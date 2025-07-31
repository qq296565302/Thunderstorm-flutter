import 'package:flutter/material.dart';
import 'dart:async';
import 'package:logger/logger.dart';
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

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  final SocketManager _socketManager = SocketManager();
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.none,
    ),
  );
  bool _isSocketConnected = false;
  StreamSubscription<bool>? _connectionSubscription;
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;
  
  /// 上次显示断开提示的时间戳，用于防抖
  DateTime? _lastDisconnectNotificationTime;

  /// 页面列表
  final List<Widget> _pages = [
    const FinancePage(),
    const SportsPage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
            
            // 重置断开提示时间戳
            _lastDisconnectNotificationTime = null;
          } else {
            // 防抖机制：只有距离上次断开提示超过5秒才显示新的断开提示
            final now = DateTime.now();
            if (_lastDisconnectNotificationTime == null || 
                now.difference(_lastDisconnectNotificationTime!).inSeconds >= 5) {
              _showConnectionStatus('Socket.IO连接断开', Colors.red);
              _lastDisconnectNotificationTime = now;
            }
          }
        }
      });
      
      // 监听通用消息
      _messageSubscription = _socketManager.messageStream.listen((message) {
        if (mounted) {
          _logger.d('主页面收到消息: $message');
        }
      });
      
      // 连接到Socket.IO服务器
      await _socketManager.connect('ws://192.168.1.128:3000');
      
    } catch (e) {
      _logger.e('Socket.IO初始化失败: $e');
      if (mounted) {
        _showConnectionStatus('Socket.IO连接失败', Colors.red);
      }
    }
  }

  /// 显示连接状态提示
  /// [message] 提示消息
  /// [color] 提示颜色
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
    WidgetsBinding.instance.removeObserver(this);
    // 清理Socket.IO相关资源
    _connectionSubscription?.cancel();
    _messageSubscription?.cancel();
    _socketManager.dispose();
    super.dispose();
  }

  /// 监听应用生命周期变化
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _logger.d('应用生命周期状态变化: $state');
    
    switch (state) {
      case AppLifecycleState.resumed:
        // 应用回到前台，确保Socket连接
        _logger.i('应用回到前台，检查Socket连接状态');
        if (!_isSocketConnected) {
          _reconnectSocket();
        }
        break;
      case AppLifecycleState.paused:
        // 应用进入后台，保持连接但减少活动
        _logger.i('应用进入后台，保持Socket连接');
        break;
      case AppLifecycleState.inactive:
        // 应用处于非活动状态
        _logger.i('应用处于非活动状态');
        break;
      case AppLifecycleState.detached:
        // 应用即将被销毁
        _logger.i('应用即将被销毁');
        break;
      case AppLifecycleState.hidden:
        // 应用被隐藏
        _logger.i('应用被隐藏');
        break;
    }
  }

  /// 重新连接Socket
  Future<void> _reconnectSocket() async {
    try {
      _logger.i('尝试重新连接Socket.IO...');
      await _socketManager.connect('ws://192.168.1.128:3000');
    } catch (e) {
      _logger.e('Socket.IO重连失败: $e');
    }
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
