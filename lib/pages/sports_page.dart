import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/sports_service.dart';

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
      // 如果没有二级Tab，创建一个length为1的TabController作为占位
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
            indicatorColor: const Color.fromARGB(255, 119, 34, 34),
            indicatorWeight: 2,
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
    // 如果是赛程Tab，显示赛程数据
    if (secondaryTab == '赛程' && SportsService().isLeagueSupported(primaryTab)) {
      return _buildSchedulePage(primaryTab);
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
             color: Colors.orange.withValues(alpha: 0.7),
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

  /// 构建赛程页面
  Widget _buildSchedulePage(String leagueName) {
    return FutureBuilder<List<MatchSchedule>>(
      future: SportsService().getLeagueSchedule(leagueName),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 119, 34, 34)),
            ),
          );
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 60,
                  color: Colors.red[400],
                ),
                const SizedBox(height: 16),
                Text(
                  '加载失败',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {}); // 重新构建以重试
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
        
        final matches = snapshot.data ?? [];
        
        if (matches.isEmpty) {
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
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: matches.length,
          itemBuilder: (context, index) {
            final match = matches[index];
            return _buildMatchCard(match);
          },
        );
      },
    );
  }

  /// 将格林尼治时间转换为北京时间，包含星期几信息
  Map<String, String> _convertToBeijingTime(String gmtTimeString) {
    try {
      // 解析GMT时间字符串
      DateTime gmtTime = DateTime.parse(gmtTimeString);
      
      // 转换为北京时间（UTC+8）
      DateTime beijingTime = gmtTime.add(const Duration(hours: 8));
      
      // 星期几的中文映射
      const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      String weekday = weekdays[beijingTime.weekday - 1];
      
      // 格式化为易读的时间格式
      String formattedTime = '${beijingTime.month.toString().padLeft(2, '0')}-${beijingTime.day.toString().padLeft(2, '0')} ${beijingTime.hour.toString().padLeft(2, '0')}:${beijingTime.minute.toString().padLeft(2, '0')}';
      
      return {
        'time': formattedTime,
        'weekday': weekday,
      };
    } catch (e) {
      // 如果解析失败，返回原始字符串
      return {
        'time': gmtTimeString,
        'weekday': '',
      };
    }
  }

  /// 构建比赛卡片
  Widget _buildMatchCard(MatchSchedule match) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
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
            // 比赛时间和标题
            Column(
              children: [
                // 比赛时间和星期几
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 119, 34, 34).withValues(alpha: 0.1),
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
                // 比赛标题
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
            
            // 对阵双方
            Row(
              children: [
                // 主队
                Expanded(
                  child: Column(
                    children: [
                      // 主队logo
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
                      // 主队名称
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
                
                // VS
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Text(
                    'VS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 119, 34, 34),
                    ),
                  ),
                ),
                
                // 客队
                Expanded(
                  child: Column(
                    children: [
                      // 客队logo
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
                      // 客队名称
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
              ],
            ),
            
            // 转播信息
            if (match.tvList.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '转播平台:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      match.tvList.join('、'),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
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
        child: Column(
          children: [
            // 一级Tab标签栏
            Container(
              color: const Color.fromARGB(255, 119, 34, 34),
              child: TabBar(
              controller: _primaryTabController,
              isScrollable: true,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
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