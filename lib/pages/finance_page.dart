import 'package:flutter/material.dart';
import 'dart:async';
import '../models/finance_model.dart';
import '../services/http_service.dart';
import '../services/socket_manager.dart';

/// 财经页面
class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  final HttpService _httpService = HttpService();
  final SocketManager _socketManager = SocketManager();
  List<FinanceNews> _newsList = [];
  bool _isLoading = true;
  String? _errorMessage;
  final Set<int> _expandedCards = <int>{}; // 记录展开的卡片索引
  bool _isSocketConnected = false;
  StreamSubscription<Map<String, dynamic>>? _financeNewsSubscription;
  StreamSubscription<bool>? _connectionSubscription;
  
  // 滚动控制器
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTopButton = false;

  @override
  void initState() {
    super.initState();
    _loadFinanceData();
    _setupSocketListeners();
    _setupScrollListener();
  }

  /// 设置滚动监听器
  void _setupScrollListener() {
    _scrollController.addListener(() {
      // 当滚动位置超过200像素时显示返回顶部按钮
      if (_scrollController.offset > 200 && !_showBackToTopButton) {
        setState(() {
          _showBackToTopButton = true;
        });
      } else if (_scrollController.offset <= 200 && _showBackToTopButton) {
        setState(() {
          _showBackToTopButton = false;
        });
      }
    });
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
    
    // 监听财经新闻实时更新
    _financeNewsSubscription = _socketManager.financeNewsStream.listen((newsData) {
      if (mounted) {
        _handleRealTimeFinanceNews(newsData);
      }
    });
  }

  /// 处理实时财经新闻数据
  void _handleRealTimeFinanceNews(Map<String, dynamic> newsData) {
    try {
      // 将实时数据转换为FinanceNews对象
      final newNews = FinanceNews(
        content: newsData['content'] ?? '',
        author: newsData['author'] ?? '实时推送',
        publishTime: newsData['publishTime'] ?? DateTime.now().toString().substring(0, 19),
      );
      
      // 保存当前滚动位置
      final currentScrollOffset = _scrollController.hasClients ? _scrollController.offset : 0.0;
      
      setState(() {
        // 将新消息添加到列表顶部
        _newsList.insert(0, newNews);
        // 限制列表长度，避免内存占用过多
        if (_newsList.length > 50) {
          _newsList = _newsList.take(50).toList();
        }
      });
      
      // 恢复滚动位置（延迟执行以确保ListView已重建）
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients && currentScrollOffset > 0) {
          _scrollController.jumpTo(currentScrollOffset);
        }
      });
      
      // 显示新消息提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('收到新的财经资讯'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('处理实时财经新闻失败: $e');
    }
  }

  /// 返回顶部
  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  /// 加载财经数据
  Future<void> _loadFinanceData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await _httpService.get('/finance', params: {
        'page': 1,
        'limit': 20,
      });

      final financeResponse = FinanceResponse.fromJson(response);
      
      setState(() {
        _newsList = financeResponse.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// 构建新闻卡片
  Widget _buildNewsCard(FinanceNews news, int index) {
    final isExpanded = _expandedCards.contains(index);
    final isLongContent = news.content.length > 100; // 判断内容是否过长
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              news.content,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
              maxLines: isExpanded ? null : 3,
              overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            // 展开/收起按钮
            if (isLongContent)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedCards.remove(index);
                      } else {
                        _expandedCards.add(index);
                      }
                    });
                  },
                  child: Text(
                    isExpanded ? '收起' : '展开全文',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildAuthorTag(news.author),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      news.publishTime,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建作者标签
  Widget _buildAuthorTag(String author) {
    Color backgroundColor;
    Color textColor = Colors.white;
    
    if (author.contains('财联社')) {
      backgroundColor = Colors.red;
    } else if (author.contains('新浪财经')) {
      backgroundColor = Colors.blue;
    } else {
      backgroundColor = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        author,
        style: TextStyle(
          fontSize: 12,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  void dispose() {
    // 清理Socket.IO相关资源
    _financeNewsSubscription?.cancel();
    _connectionSubscription?.cancel();
    // 清理滚动控制器
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              // 头部标题
              Container(
                padding: const EdgeInsets.fromLTRB(16, 60, 16, 20),
                child: Row(
                  children: [
                    const Icon(
                      Icons.trending_up,
                      size: 32,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '财经资讯',
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
                      onPressed: _loadFinanceData,
                      icon: const Icon(Icons.refresh),
                      tooltip: '刷新',
                    ),
                  ],
                ),
              ),
              // 内容区域
              SizedBox(
                height: MediaQuery.of(context).size.height - 250, // 限制内容区域高度，避免超出
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : _errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.red,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '加载失败',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadFinanceData,
                                  child: const Text('重试'),
                                ),
                              ],
                            ),
                          )
                        : _newsList.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.inbox,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      '暂无数据',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _loadFinanceData,
                                child: ListView.builder(
                                  controller: _scrollController, // 添加滚动控制器
                                  padding: const EdgeInsets.only(bottom: 20), // 减少底部间距
                                  itemCount: _newsList.length,
                                  itemBuilder: (context, index) {
                                    return _buildNewsCard(_newsList[index], index);
                                  },
                                ),
                              ),
              ),
            ],
          ),
          // 悬浮返回顶部按钮
          if (_showBackToTopButton)
            Positioned(
              right: 16,
              bottom: 100, // 距离底部100像素，避免与底部导航栏重叠
              child: FloatingActionButton(
                onPressed: _scrollToTop,
                backgroundColor: Colors.white.withOpacity(0.8),
                foregroundColor: Colors.black87,
                elevation: 4,
                mini: true, // 使用小尺寸
                child: const Icon(
                  Icons.keyboard_arrow_up,
                  size: 24,
                ),
              ),
            ),
        ],
      ),
    );
  }
}