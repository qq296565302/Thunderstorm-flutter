import 'package:flutter/material.dart';
import 'dart:async';
import 'package:logger/logger.dart';
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
  List<FinanceNews> _newsList = [];
  bool _isLoading = true;
  String? _errorMessage;
  final Set<int> _expandedCards = <int>{}; // 记录展开的卡片索引
  StreamSubscription<Map<String, dynamic>>? _financeNewsSubscription;
  StreamSubscription<bool>? _connectionSubscription;
  
  // 滚动控制器
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTopButton = false;
  
  // 新消息通知相关
  List<FinanceNews> _pendingNewsList = []; // 存储待显示的新消息
  int _newMessageCount = 0; // 新消息计数
  
  // Socket连接状态
  bool _isSocketConnected = false; // Socket.IO连接状态

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
      // Socket.IO连接状态调试输出
      debugPrint('Socket.IO连接状态: ${isConnected ? "已连接" : "已断开"}');
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
      
      setState(() {
        // 将新消息添加到待显示列表
        _pendingNewsList.insert(0, newNews);
        // 增加新消息计数
        _newMessageCount++;
        // 限制待显示列表长度，避免内存占用过多
        if (_pendingNewsList.length > 50) {
          _pendingNewsList = _pendingNewsList.take(50).toList();
        }
      });
    } catch (e) {
      _logger.e('处理实时财经新闻失败: $e');
    }
  }
  
  /// 加载新消息到列表中
  void _loadNewMessages() {
    if (_pendingNewsList.isEmpty) return;
    
    setState(() {
      // 将待显示的新消息添加到主列表顶部
      _newsList.insertAll(0, _pendingNewsList);
      // 限制主列表长度
      if (_newsList.length > 100) {
        _newsList = _newsList.take(100).toList();
      }
      // 清空待显示列表和计数
      _pendingNewsList.clear();
      _newMessageCount = 0;
    });
    
    // 滚动到顶部显示新消息
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
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
    // 使用更准确的方法判断内容是否需要展开按钮
    final isLongContent = _isContentTooLong(news.content);
    
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
              news.content.trim(), // 格式化内容：去掉开头和结尾的空格符
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
              // Socket连接状态指示器
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: _isSocketConnected ? Colors.green.shade100 : Colors.red.shade100,
                child: Row(
                  children: [
                    Icon(
                      _isSocketConnected ? Icons.wifi : Icons.wifi_off,
                      size: 16,
                      color: _isSocketConnected ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Socket.IO: ${_isSocketConnected ? "已连接" : "已断开"}',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isSocketConnected ? Colors.green.shade700 : Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // 新消息通知栏
              if (_newMessageCount > 0) ...[
                // 调试输出：打印新消息计数
                Builder(
                  builder: (context) {
                    debugPrint('当前新消息数量: $_newMessageCount');
                    return const SizedBox.shrink();
                  },
                ),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: InkWell(
                    onTap: _loadNewMessages,
                    child: Row(
                      children: [
                        Icon(
                          Icons.notifications_active,
                          color: Colors.blue.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '接收到 $_newMessageCount 条新消息',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '点击查看',
                          style: TextStyle(
                            color: Colors.blue.shade600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.blue.shade600,
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // 内容区域
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), // 设置容器的padding
                child: SizedBox(
                  height: MediaQuery.of(context).size.height - (_newMessageCount > 0 ? 170 : 120), // 根据通知栏动态调整高度
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
                                  padding: const EdgeInsets.all(16), // 设置内容区域的padding值
                                  itemCount: _newsList.length,
                                  itemBuilder: (context, index) {
                                    return _buildNewsCard(_newsList[index], index);
                                  },
                                ),
                              ),
                ),
              ),
            ],
          ),
          // 悬浮返回顶部按钮
          if (_showBackToTopButton)
            Positioned(
              right: 16,
              bottom: 120, // 距离底部120像素，避免与底部导航栏重叠
              child: FloatingActionButton(
                onPressed: _scrollToTop,
                backgroundColor: Colors.white.withValues(alpha: 0.8),
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

  /// 判断文本内容是否过长，需要展开按钮
  /// 使用TextPainter来准确计算文本在指定约束下是否会超过3行
  bool _isContentTooLong(String content) {
    // 格式化内容：去掉开头和结尾的空格符
    final String trimmedContent = content.trim();
    
    // 如果内容为空或过短，不需要展开按钮
    if (trimmedContent.isEmpty || trimmedContent.length < 50) {
      return false;
    }
    
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: trimmedContent,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
      ),
      maxLines: 3,
      textDirection: TextDirection.ltr,
    );
    
    // 计算可用宽度（屏幕宽度减去卡片边距和内边距）
    final double screenWidth = MediaQuery.of(context).size.width;
    final double availableWidth = screenWidth - 32 - 32; // 16*2 margin + 16*2 padding
    
    textPainter.layout(maxWidth: availableWidth);
    
    // 创建一个无限行数的TextPainter来计算完整文本的行数
    final TextPainter fullTextPainter = TextPainter(
      text: TextSpan(
        text: trimmedContent,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    fullTextPainter.layout(maxWidth: availableWidth);
    
    // 计算实际需要的行数
    final int actualLines = (fullTextPainter.height / fullTextPainter.preferredLineHeight).ceil();
    
    // 只有当实际行数大于3行时才显示展开按钮
    return actualLines > 3;
  }
}