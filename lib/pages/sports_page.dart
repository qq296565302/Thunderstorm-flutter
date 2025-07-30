import 'package:flutter/material.dart';
import 'dart:async';
import 'package:logger/logger.dart';
import '../services/socket_manager.dart';

/// 体育页面
class SportsPage extends StatefulWidget {
  const SportsPage({super.key});

  @override
  State<SportsPage> createState() => _SportsPageState();
}

class _SportsPageState extends State<SportsPage> {
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
  List<Map<String, dynamic>> _sportsList = [];
  bool _isSocketConnected = false;
  StreamSubscription<Map<String, dynamic>>? _sportsNewsSubscription;
  StreamSubscription<bool>? _connectionSubscription;

  @override
  void initState() {
    super.initState();
    _setupSocketListeners();
  }

  /// 设置Socket.IO监听器
  void _setupSocketListeners() {
    // 监听连接状态变化
    _connectionSubscription = _socketManager.connectionStream.listen((isConnected) {
      if (mounted) {
        setState(() {
          _isSocketConnected = isConnected;
        });
      }
    });
    
    // 监听体育新闻实时更新
    _sportsNewsSubscription = _socketManager.sportsNewsStream.listen((newsData) {
      if (mounted) {
        _handleRealTimeSportsNews(newsData);
      }
    });
  }

  /// 处理实时体育新闻数据
  void _handleRealTimeSportsNews(Map<String, dynamic> newsData) {
    try {
      setState(() {
        // 将新消息添加到列表顶部
        _sportsList.insert(0, newsData);
        // 限制列表长度，避免内存占用过多
        if (_sportsList.length > 30) {
          _sportsList = _sportsList.take(30).toList();
        }
      });
      
      // 显示新消息提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('收到新的体育资讯'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      _logger.e('处理实时体育新闻失败: $e');
    }
  }

  @override
  void dispose() {
    // 清理Socket.IO相关资源
    _sportsNewsSubscription?.cancel();
    _connectionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 头部标题
          Container(
            padding: const EdgeInsets.fromLTRB(16, 60, 16, 20),
            child: Row(
              children: [
                const Icon(
                  Icons.sports_soccer,
                  size: 32,
                  color: Colors.orange,
                ),
                const SizedBox(width: 12),
                const Text(
                  '体育资讯',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                // Socket.IO连接状态指示器
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isSocketConnected ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _sportsList.clear();
                    });
                  },
                  icon: const Icon(Icons.clear_all),
                  tooltip: '清空列表',
                ),
              ],
            ),
          ),
          // 内容区域
          Expanded(
            child: _sportsList.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.sports_soccer,
                          size: 100,
                          color: Colors.orange,
                        ),
                        SizedBox(height: 20),
                        Text(
                          '等待体育资讯推送...',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          '实时体育新闻将在这里显示',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _sportsList.length,
                    itemBuilder: (context, index) {
                      final news = _sportsList[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                news['title'] ?? '体育新闻',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                news['content'] ?? '暂无内容',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      news['source'] ?? '体育频道',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    news['time'] ?? DateTime.now().toString().substring(11, 19),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}