import 'package:flutter/material.dart';
import 'pages/finance_page.dart';
import 'pages/sports_page.dart';
import 'services/socket_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// 应用程序的根组件
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '雷雨新闻',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainPage(),
    );
  }
}

/// 主页面组件，包含底部导航栏
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  /// 页面列表
  final List<Widget> _pages = [
    const FinancePage(),
    const SportsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeSocket();
  }

  /// 初始化Socket连接
  void _initializeSocket() async {
    try {
      final socketManager = SocketManager();
      await socketManager.connect('http://192.168.1.128:3000');
    } catch (e) {
      // 连接失败时的处理，使用debugPrint避免在生产环境中输出
      debugPrint('Socket连接失败: $e');
    }
  }





  @override
  void dispose() {
    // 断开Socket连接
    final socketManager = SocketManager();
    socketManager.disconnect();
    super.dispose();
  }





  /// 处理底部导航栏点击事件
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 主要内容区域
          Expanded(
            child: _pages[_selectedIndex],
          ),
          // 底部导航栏
          SafeArea(
            child: CustomBottomNavBar(
              selectedIndex: _selectedIndex,
              onItemTapped: _onItemTapped,
            ),
          ),
        ],
      ),
    );
  }
}

/// 自定义底部导航栏组件
class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(
            index: 0,
            icon: Icons.trending_up,
            label: '财经',
            isSelected: selectedIndex == 0,
          ),
          _buildNavItem(
            index: 1,
            icon: Icons.sports_soccer,
            label: '足球',
            isSelected: selectedIndex == 1,
          ),
        ],
      ),
    );
  }

  /// 构建导航栏项目
  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => onItemTapped(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple.withAlpha(25) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.deepPurple : Colors.grey,
              size: 20,
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.deepPurple : Colors.grey,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
