import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/sports_service.dart';
import '../services/http_service.dart';
import 'team_page.dart';
import '../widgets/dynamic_tab.dart';
import '../widgets/schedule_tab.dart';
import '../widgets/ranking_tab.dart';

/// 体育页面 - 足球赛事信息
class SportsPage extends StatefulWidget {
  const SportsPage({super.key});

  @override
  State<SportsPage> createState() => _SportsPageState();
}

class _SportsPageState extends State<SportsPage> with TickerProviderStateMixin {
  late TabController _primaryTabController;
  late List<TabController> _secondaryTabControllers;
  
  // 一级Tab标签列表
  final List<String> _primaryTabs = [
    'AC米兰',
    '英超',
    '德甲',
    '西甲',
    '意甲',
    '欧冠',
    '欧联',
    '欧协联',
    '深度'
  ];
  
  // 二级Tab配置
  final Map<String, List<String>> _secondaryTabsConfig = {
    'AC米兰': ['动态', '赛程'],
    '英超': ['动态', '赛程', '积分'],
    '德甲': ['动态', '赛程', '积分'],
    '西甲': ['动态', '赛程', '积分'],
    '意甲': ['动态', '赛程', '积分'],
    '欧冠': ['动态', '赛程', '积分'],
    '欧联': ['动态', '赛程', '积分'],
    '欧协联': ['动态', '赛程', '积分'],
    '深度': [], // 深度没有二级Tab
  };
  
  @override
  void initState() {
    super.initState();
    _primaryTabController = TabController(length: _primaryTabs.length, vsync: this);
    
    // 初始化二级TabController列表
    _secondaryTabControllers = _primaryTabs.map((tab) {
      final secondaryTabs = _secondaryTabsConfig[tab] ?? [];
      final length = secondaryTabs.isEmpty ? 1 : secondaryTabs.length;
      return TabController(length: length, vsync: this);
    }).toList();
  }

  @override
  void dispose() {
    _primaryTabController.dispose();
    for (var controller in _secondaryTabControllers) {
      controller.dispose();
    }
    super.dispose();
  }
  
  /// 构建一级Tab内容页面
  Widget _buildPrimaryTabContent(int primaryIndex) {
    final primaryTabName = _primaryTabs[primaryIndex];
    final secondaryTabs = _secondaryTabsConfig[primaryTabName] ?? [];
    
    // 如果没有二级Tab（如"深度"），直接显示内容
    if (secondaryTabs.isEmpty) {
      return _buildContentPage(primaryTabName, '');
    }
    
    // 有二级Tab的情况
    return Column(
      children: [
        // 二级Tab栏
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _secondaryTabControllers[primaryIndex],
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(
                color: Color.fromARGB(255, 119, 34, 34),
                width: 2,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(0),
                bottomRight: Radius.circular(0),
              ),
            ),
            labelColor: const Color.fromARGB(255, 119, 34, 34),
            unselectedLabelColor: Colors.grey[600],
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
            tabs: secondaryTabs.map((tab) => Tab(
              text: tab,
              height: 40,
            )).toList(),
          ),
        ),
        // 二级Tab内容区域
        Expanded(
          child: TabBarView(
            controller: _secondaryTabControllers[primaryIndex],
            physics: const NeverScrollableScrollPhysics(),
            children: secondaryTabs.map((secondaryTab) => 
              _buildContentPage(primaryTabName, secondaryTab)
            ).toList(),
          ),
        ),
      ],
    );
  }
  
  /// 构建具体内容页面
  Widget _buildContentPage(String primaryTab, String secondaryTab) {
    if (secondaryTab == '动态') {
      return DynamicTab(leagueName: primaryTab);
    }
    
    if (secondaryTab == '赛程' && SportsService().isLeagueSupported(primaryTab)) {
      return ScheduleTab(leagueName: primaryTab);
    }
    
    if (secondaryTab == '积分') {
      return RankingTab(leagueName: primaryTab);
    }
    
    // 其他Tab显示占位符内容
    final displayText = secondaryTab.isEmpty ? primaryTab : '$primaryTab - $secondaryTab';
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports_soccer,
            size: 80,
            color: Colors.orange.withOpacity(0.7),
          ),
          const SizedBox(height: 20),
          Text(
            '$displayText 信息',
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
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 119, 34, 34),
        elevation: 0,
        toolbarHeight: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Color.fromARGB(255, 119, 34, 34),
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            // 一级Tab标签栏
            Container(
              color: const Color.fromARGB(255, 119, 34, 34),
              child: TabBar(
                controller: _primaryTabController,
                isScrollable: true,
                indicator: const UnderlineTabIndicator(
                  borderSide: BorderSide(
                    color: Colors.white,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(0),
                    bottomRight: Radius.circular(0),
                  ),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                ),
                tabs: _primaryTabs.map((tab) => Tab(
                  text: tab,
                  height: 50,
                )).toList(),
              ),
            ),
            // 一级Tab内容区域（包含二级Tab）
            Expanded(
              child: TabBarView(
                controller: _primaryTabController,
                children: List.generate(_primaryTabs.length, (index) => 
                  _buildPrimaryTabContent(index)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 移除所有以下旧方法，因为它们已移到子组件中