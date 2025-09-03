import 'package:flutter/material.dart';
import '../services/http_service.dart';

/// 积分标签页组件 - 管理特定联赛的积分数据和UI
class RankingTab extends StatefulWidget {
  /// 联赛名称，用于数据请求
  final String leagueName;

  const RankingTab({
    super.key,
    required this.leagueName,
  });

  @override
  State<RankingTab> createState() => _RankingTabState();
}

class _RankingTabState extends State<RankingTab> {
  List<Map<String, dynamic>> _rankingData = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 延迟加载数据，确保组件已挂载
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadRankingData();
      }
    });
  }

  /// 加载积分数据
  Future<void> _loadRankingData() async {
    if (_isLoading) return;
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await HttpService().get('/sport/league/rank', params: {
        'leagueName': widget.leagueName,
      });

      if (!mounted) return;

      setState(() {
        if (response is List && response.isNotEmpty) {
          final leagueData = response.firstWhere(
            (item) => item is Map<String, dynamic> && item['league'] == widget.leagueName,
            orElse: () => null,
          );
          if (leagueData != null && leagueData.containsKey('table')) {
            _rankingData = List<Map<String, dynamic>>.from(leagueData['table'] ?? []);
          } else {
            _rankingData = [];
          }
        } else if (response is Map<String, dynamic> && response.containsKey('table')) {
          _rankingData = List<Map<String, dynamic>>.from(response['table'] ?? []);
        } else if (response is Map<String, dynamic> && response.containsKey('data')) {
          _rankingData = List<Map<String, dynamic>>.from(response['data'] ?? []);
        } else {
          _rankingData = [];
        }
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

  /// 构建积分榜行UI
  Widget _buildRankingRow(Map<String, dynamic> team, int index) {
    final rank = team['rank']?.toString() ?? (index + 1).toString();
    final teamName = team['team_name']?.toString() ?? '未知球队';
    final points = team['points']?.toString() ?? '0';

    Color? backgroundColor;
    if (index < 4) {
      backgroundColor = Colors.green.withOpacity(0.1);
    } else if (index < 6) {
      backgroundColor = Colors.blue.withOpacity(0.1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              rank,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              teamName,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              points,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_rankingData.isEmpty && _isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 119, 34, 34)),
        ),
      );
    }

    if (_rankingData.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.leaderboard,
              size: 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '暂无积分数据',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '当前没有可显示的积分榜',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (mounted) {
                  _loadRankingData();
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

    return Column(
      children: [
        Container(
          color: const Color.fromARGB(255, 119, 34, 34),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: const Row(
            children: [
              SizedBox(
                width: 50,
                child: Text(
                  '排名',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  '球队',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(
                width: 60,
                child: Text(
                  '积分',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(0),
            itemCount: _rankingData.length,
            itemBuilder: (context, index) {
              return _buildRankingRow(_rankingData[index], index);
            },
          ),
        ),
      ],
    );
  }
}