import 'package:flutter/material.dart';
import '../services/http_service.dart';

/// 球队页面组件
/// 显示球队详细信息，包含顶部标题栏和球队内容
class TeamPage extends StatefulWidget {
  final String teamId;
  final String teamName;
  final String teamLogo;

  const TeamPage({
    Key? key,
    required this.teamId,
    required this.teamName,
    required this.teamLogo,
  }) : super(key: key);

  @override
  State<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _players = [];
  bool _isLoadingPlayers = false;

  @override
  void initState() {
    super.initState();
    // 初始化TabController
    _tabController = TabController(length: 4, vsync: this);
    // 初始化时可以根据teamId请求球队详细信息
    _loadTeamData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 加载球队数据
  /// 根据传入的teamId请求接口获取球队详细信息
  Future<void> _loadTeamData() async {
    // TODO: 实现根据widget.teamId请求球队数据的逻辑
    print('Loading team data for team ID: ${widget.teamId}');
  }

  /// 加载球员数据
  /// 根据teamId请求球员列表接口
  Future<void> _loadPlayersData() async {
    if (_isLoadingPlayers) return;
    
    setState(() {
      _isLoadingPlayers = true;
    });

    try {
      final response = await HttpService().get('/sport/team/${widget.teamId}/players');
      if (response['code'] == 200 && response['data'] != null) {
        setState(() {
          _players = List<Map<String, dynamic>>.from(response['data']);
        });
      } else {
        print('Failed to load players data: ${response['message']}');
      }
    } catch (e) {
      print('Error loading players data: $e');
    } finally {
      setState(() {
        _isLoadingPlayers = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  /// 构建顶部标题栏
  /// 包含返回按钮、球队logo和球队名称
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios,
          color: Colors.black87,
          size: 20,
        ),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
      title: _buildTitle(),
      centerTitle: true,
    );
  }

  /// 构建标题组件
  /// 包含球队logo和球队名称的组合
  Widget _buildTitle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 球队logo
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 0.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              widget.teamLogo,
              width: 24,
              height: 24,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 24,
                  height: 24,
                  color: Colors.grey.shade200,
                  child: Icon(
                    Icons.sports_soccer,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        // 球队名称
        Text(
          widget.teamName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  /// 构建页面主体内容
  /// 包含球队基本信息和Tab页签内容
  Widget _buildBody() {
    return Column(
      children: [
        // 球队基本信息卡片
        Container(
          padding: const EdgeInsets.all(16),
          child: _buildTeamInfoCard(),
        ),
        // Tab页签
        _buildTabBar(),
        // Tab内容
        Expanded(
          child: _buildTabBarView(),
        ),
      ],
    );
  }

  /// 构建Tab页签栏
  /// 包含动态、赛程、数据三个标签
  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: const Color.fromARGB(255, 119, 34, 34),
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        indicatorColor: const Color.fromARGB(255, 119, 34, 34),
        indicatorWeight: 3,
        tabs: const [
          Tab(text: '动态'),
          Tab(text: '赛程'),
          Tab(text: '数据'),
          Tab(text: '球员'),
        ],
      ),
    );
  }

  /// 构建Tab内容视图
  /// 包含三个标签页的具体内容
  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildDynamicTab(),
        _buildScheduleTab(),
        _buildDataTab(),
        _buildPlayersTab(),
      ],
    );
  }

  /// 构建动态标签页
  /// 显示球队相关动态信息
  Widget _buildDynamicTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '球队动态',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.article_outlined,
                    size: 60,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无动态信息',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '球队相关动态将在此处显示',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建赛程标签页
  /// 显示球队赛程信息
  Widget _buildScheduleTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '球队赛程',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    size: 60,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无赛程信息',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '球队赛程安排将在此处显示',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建数据标签页
  /// 显示球队统计数据
  Widget _buildDataTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '球队数据',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bar_chart_outlined,
                    size: 60,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无数据信息',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '球队统计数据将在此处显示',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建球员标签页
  /// 显示球队球员信息
  Widget _buildPlayersTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '球队球员',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              IconButton(
                onPressed: _loadPlayersData,
                icon: Icon(
                  Icons.refresh,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoadingPlayers
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _players.isEmpty
                    ? _buildEmptyPlayersState()
                    : _buildPlayersList(),
          ),
        ],
      ),
    );
  }

  /// 构建空状态显示
  /// 当没有球员数据时显示
  Widget _buildEmptyPlayersState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outlined,
            size: 60,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无球员信息',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击刷新按钮获取球员数据',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadPlayersData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 119, 34, 34),
              foregroundColor: Colors.white,
            ),
            child: const Text('加载球员数据'),
          ),
        ],
      ),
    );
  }

  /// 构建球员列表
  /// 显示球员详细信息列表
  Widget _buildPlayersList() {
    return ListView.builder(
      itemCount: _players.length,
      itemBuilder: (context, index) {
        final player = _players[index];
        return _buildPlayerCard(player);
      },
    );
  }

  /// 构建单个球员卡片
  /// 显示球员的详细信息
  Widget _buildPlayerCard(Map<String, dynamic> player) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 球员头像
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Image.network(
                player['avatar_url'] ?? '',
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 50,
                    height: 50,
                    color: Colors.grey.shade200,
                    child: Icon(
                      Icons.person,
                      size: 30,
                      color: Colors.grey.shade400,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 球员信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 姓名和号码
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        player['name'] ?? '未知',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 119, 34, 34),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '#${player['jersey_number'] ?? '0'}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // 位置和国籍
                Row(
                  children: [
                    Text(
                      player['position'] ?? '未知位置',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (player['nationality_flag'] != null)
                      Container(
                        width: 20,
                        height: 14,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 0.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: Image.network(
                            player['nationality_flag'],
                            width: 20,
                            height: 14,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 20,
                                height: 14,
                                color: Colors.grey.shade200,
                                child: Icon(
                                  Icons.flag,
                                  size: 10,
                                  color: Colors.grey.shade400,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // 统计数据
                Row(
                  children: [
                    _buildStatItem('出场', player['appearances']?.toString() ?? '0'),
                    const SizedBox(width: 16),
                    _buildStatItem('进球', player['goals']?.toString() ?? '0'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建统计数据项
  /// 显示单个统计数据
  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  /// 构建球队信息卡片
  /// 显示球队的基本信息
  Widget _buildTeamInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 大尺寸球队logo
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: Image.network(
                widget.teamLogo,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey.shade200,
                    child: Icon(
                      Icons.sports_soccer,
                      size: 40,
                      color: Colors.grey.shade400,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 球队名称
          Text(
            widget.teamName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // 球队ID（调试用，可选显示）
          if (widget.teamId.isNotEmpty)
            Text(
              'Team ID: ${widget.teamId}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
        ],
      ),
    );
  }


}