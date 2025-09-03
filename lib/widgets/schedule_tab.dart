import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/sports_service.dart';
import '../pages/team_page.dart';

/// 赛程标签页组件 - 管理特定联赛的赛程数据和UI
class ScheduleTab extends StatefulWidget {
  /// 联赛名称，用于数据请求
  final String leagueName;

  const ScheduleTab({
    super.key,
    required this.leagueName,
  });

  @override
  State<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<ScheduleTab> {
  List<MatchSchedule> _scheduleData = [];
  String? _nextDateData;
  bool _isLoading = false;
  bool _hasMoreData = true;
  bool _finishFlag = false;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    // 延迟加载数据，确保组件已挂载
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadScheduleData();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// 滚动监听方法 - 检测是否需要加载更多数据
  void _onScroll() {
    if (!mounted) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && _hasMoreData) {
      _loadScheduleData(isLoadMore: true);
    }
  }

  /// 加载赛程数据 - 支持首次加载和分页加载
  Future<void> _loadScheduleData({bool isLoadMore = false}) async {
    if (_isLoading || (!isLoadMore && _scheduleData.isNotEmpty)) return;
    if (isLoadMore && !_hasMoreData) return;
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await SportsService().getLeagueSchedule(
        widget.leagueName,
        start: isLoadMore ? (_nextDateData ?? '') : ''
      );

      if (!mounted) return;

      setState(() {
        if (isLoadMore) {
          _scheduleData.addAll(response.matches);
        } else {
          _scheduleData = response.matches;
        }
        _nextDateData = response.nextDate;
        final isFinished = response.nextDate == null || response.nextDate == '';
        _finishFlag = isFinished;
        _hasMoreData = !isFinished;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      // TODO: 添加错误处理，如显示提示
    }
  }

  /// 将格林尼治时间转换为北京时间，包含星期几信息
  Map<String, String> _convertToBeijingTime(String gmtTimeString) {
    try {
      DateTime gmtTime = DateTime.parse(gmtTimeString);
      DateTime beijingTime = gmtTime.add(const Duration(hours: 8));
      const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      String weekday = weekdays[beijingTime.weekday - 1];
      String formattedTime = '${beijingTime.month.toString().padLeft(2, '0')}-${beijingTime.day.toString().padLeft(2, '0')} ${beijingTime.hour.toString().padLeft(2, '0')}:${beijingTime.minute.toString().padLeft(2, '0')}';
      return {'time': formattedTime, 'weekday': weekday};
    } catch (e) {
      return {'time': gmtTimeString, 'weekday': ''};
    }
  }

  /// 判断比赛时间是否晚于当前时间
  bool _isMatchInFuture(String gmtTimeString) {
    try {
      DateTime gmtTime = DateTime.parse(gmtTimeString);
      DateTime beijingTime = gmtTime.add(const Duration(hours: 8));
      DateTime now = DateTime.now();
      return beijingTime.isAfter(now);
    } catch (e) {
      return false;
    }
  }

  /// 构建比赛卡片UI
  Widget _buildMatchCard(MatchSchedule match) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 119, 34, 34).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Builder(
                    builder: (context) {
                      final timeInfo = _convertToBeijingTime(match.startPlay);
                      return Text(
                        '${timeInfo['time']} ${timeInfo['weekday']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color.fromARGB(255, 119, 34, 34),
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                if (match.matchTitle != null && match.matchTitle!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    match.matchTitle!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _navigateToTeamPage(match.teamAId ?? '', match.teamAName, match.teamALogo),
                    child: Column(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: match.teamALogo.isNotEmpty
                                ? Image.network(
                                    match.teamALogo,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[200],
                                        child: const Icon(
                                          Icons.sports_soccer,
                                          color: Colors.grey,
                                          size: 24,
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.sports_soccer,
                                      color: Colors.grey,
                                      size: 24,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          match.teamAName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _isMatchInFuture(match.startPlay)
                          ? const Icon(
                              Icons.notifications_outlined,
                              size: 20,
                              color: Color.fromARGB(255, 119, 34, 34),
                            )
                          : const Text(
                              'VS',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 119, 34, 34),
                              ),
                            ),
                      if (match.tvList.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          match.tvList.join('、'),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _navigateToTeamPage(match.teamBId ?? '', match.teamBName, match.teamBLogo),
                    child: Column(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: match.teamBLogo.isNotEmpty
                                ? Image.network(
                                    match.teamBLogo,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[200],
                                        child: const Icon(
                                          Icons.sports_soccer,
                                          color: Colors.grey,
                                          size: 24,
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.sports_soccer,
                                      color: Colors.grey,
                                      size: 24,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          match.teamBName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建"没有更多赛程"提示组件
  Widget _buildNoMoreDataWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: Colors.grey[400],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              '没有更多赛程',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  /// 导航到球队页面
  void _navigateToTeamPage(String teamId, String teamName, String teamLogo) {
    if (teamId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('球队信息不完整，无法跳转'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TeamPage(
          teamId: teamId,
          teamName: teamName,
          teamLogo: teamLogo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_scheduleData.isEmpty && _isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 119, 34, 34)),
        ),
      );
    }

    if (_scheduleData.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '暂无赛程',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '当前没有可显示的比赛安排',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (mounted) {
                  _loadScheduleData();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 119, 34, 34),
                foregroundColor: Colors.white,
              ),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 0),
      itemCount: _scheduleData.length + (_isLoading ? 1 : (_finishFlag ? 1 : 0)),
      itemBuilder: (context, index) {
        if (index < _scheduleData.length) {
          return _buildMatchCard(_scheduleData[index]);
        } else {
          if (_isLoading) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 119, 34, 34)),
                ),
              ),
            );
          } else if (_finishFlag) {
            return _buildNoMoreDataWidget();
          }
          return const SizedBox.shrink();
        }
      },
    );
  }
}