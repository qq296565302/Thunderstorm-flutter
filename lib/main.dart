import 'package:flutter/material.dart';
import 'dart:async';
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
      title: 'Flutter Thunderstorm',
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
  final SocketManager _socketManager = SocketManager();
  bool _isSocketConnected = false;
  StreamSubscription<bool>? _connectionSubscription;
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;

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

  /// 初始化Socket.IO连接和监听
  Future<void> _initializeSocket() async {
    try {
      // 监听连接状态变化
      _connectionSubscription = _socketManager.connectionStream.listen((isConnected) {
        if (mounted) {
          setState(() {
            _isSocketConnected = isConnected;
          });
          
          if (isConnected) {
            // 连接成功后自动订阅所有频道
            _socketManager.subscribe('finance_news');
            _socketManager.subscribe('sports_news');
            
            // 显示连接成功提示
            _showConnectionStatus('Socket.IO连接成功', Colors.green);
          } else {
            // 显示连接断开提示
            _showConnectionStatus('Socket.IO连接断开', Colors.red);
          }
        }
      });
      
      // 监听通用消息
      _messageSubscription = _socketManager.messageStream.listen((message) {
        if (mounted) {
          print('主页面收到消息: $message');
        }
      });
      
      // 连接到Socket.IO服务器
      await _socketManager.connect('ws://localhost:3000');
      
    } catch (e) {
      print('Socket.IO初始化失败: $e');
      if (mounted) {
        _showConnectionStatus('Socket.IO连接失败', Colors.red);
      }
    }
  }

  /// 显示连接状态提示
  void _showConnectionStatus(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                _isSocketConnected ? Icons.wifi : Icons.wifi_off,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(message),
            ],
          ),
          backgroundColor: color,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    // 清理Socket.IO相关资源
    _connectionSubscription?.cancel();
    _messageSubscription?.cancel();
    _socketManager.dispose();
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
      body: Stack(
        children: [
          // 主要内容区域
          _pages[_selectedIndex],
          // 底部导航栏
          Positioned(
            bottom: 20,
            left: MediaQuery.of(context).size.width * 0.05,
            right: MediaQuery.of(context).size.width * 0.05,
            child: CustomBottomNavBar(
              selectedIndex: _selectedIndex,
              onItemTapped: _onItemTapped,
              isSocketConnected: _isSocketConnected,
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
  final bool isSocketConnected;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.isSocketConnected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
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
          // Socket.IO连接状态指示器
          Container(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isSocketConnected ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: isSocketConnected ? [
                      BoxShadow(
                        color: Colors.green.withAlpha(100),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ] : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isSocketConnected ? '在线' : '离线',
                  style: TextStyle(
                    color: isSocketConnected ? Colors.green : Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _buildNavItem(
            index: 1,
            icon: Icons.sports_soccer,
            label: '体育',
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple.withAlpha(25) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.deepPurple : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.deepPurple : Colors.grey,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
