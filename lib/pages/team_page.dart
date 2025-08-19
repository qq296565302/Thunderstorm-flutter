import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    // 初始化TabController
    _tabController = TabController(length: 3, vsync: this);
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