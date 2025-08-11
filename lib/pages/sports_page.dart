import 'package:flutter/material.dart';

/// 体育页面 - 足球赛事信息
class SportsPage extends StatefulWidget {
  const SportsPage({super.key});

  @override
  State<SportsPage> createState() => _SportsPageState();
}

class _SportsPageState extends State<SportsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Tab标签列表
  final List<String> _tabs = [
    'AC米兰',
    '英超',
    '德甲',
    '西甲',
    '意甲',
    '欧冠',
    '欧联',
    '欧协联'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 构建Tab内容页面
  Widget _buildTabContent(String tabName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
             Icons.sports_soccer,
             size: 80,
             color: Colors.orange.withValues(alpha: 0.7),
           ),
          const SizedBox(height: 20),
          Text(
            '$tabName 赛事信息',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '敬请期待更多精彩内容',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [

          // Tab标签栏
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: Colors.orange,
              indicatorWeight: 3,
              labelColor: Colors.orange,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
              tabs: _tabs.map((tab) => Tab(
                text: tab,
                height: 50,
              )).toList(),
            ),
          ),
          // Tab内容区域
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabs.map((tab) => _buildTabContent(tab)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}