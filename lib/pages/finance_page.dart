import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';
import '../models/finance_model.dart';
import '../services/http_service.dart';
import '../services/socket_manager.dart';

/// 财经页面常量配置
class _FinancePageConstants {
  static const int maxPendingNews = 50;
  static const int maxMainNewsList = 100;
  static const int defaultPageSize = 20;
  static const double scrollThreshold = 200.0;
  static const double bottomButtonOffset = 120.0;
  static const Duration scrollAnimationDuration = Duration(milliseconds: 500);
  static const Duration newMessageAnimationDuration = Duration(milliseconds: 300);
}

/// 财经页面
class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  final HttpService _httpService = HttpService();
  final SocketManager _socketManager = SocketManager();
  
  /// 创建Logger实例
  static Logger _createLogger() {
    return Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.none,
      ),
    );
  }
  
  final Logger _logger = _createLogger();
  List<FinanceNews> _newsList = [];
  bool _isLoading = true;
  String? _errorMessage;
  final Set<String> _expandedCards = <String>{}; // 记录展开的卡片唯一标识符
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
    _scrollController.addListener(_onScroll);
  }
  
  /// 滚动事件处理
  void _onScroll() {
    if (!mounted) return;
    
    final shouldShow = _scrollController.offset > _FinancePageConstants.scrollThreshold;
    if (shouldShow != _showBackToTopButton) {
      setState(() {
        _showBackToTopButton = shouldShow;
      });
    }
  }

  /// 设置Socket.IO监听器
  void _setupSocketListeners() {
    // 获取当前连接状态
    _isSocketConnected = _socketManager.isConnected;
    
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
    if (!mounted) return;
    
    try {
      // 验证必要字段
      final content = newsData['content']?.toString();
      if (content == null || content.trim().isEmpty) {
        _logger.w('接收到空内容的新闻数据');
        return;
      }
      
      // 将实时数据转换为FinanceNews对象
      final newNews = FinanceNews(
        content: content,
        author: newsData['author']?.toString() ?? '实时推送',
        publishTime: newsData['publishTime']?.toString() ?? 
            DateTime.now().toString().substring(0, 19),
      );
      
      // 检查待显示列表中是否已存在相同的新闻（content和author都相同）
      final isDuplicate = _pendingNewsList.any((existingNews) => 
          existingNews.content == newNews.content && 
          existingNews.author == newNews.author);
      
      // 如果是重复数据，则不处理
      if (isDuplicate) {
        _logger.d('检测到重复的财经新闻数据，跳过处理');
        return;
      }
      
      setState(() {
        // 将新消息添加到待显示列表
        _pendingNewsList.insert(0, newNews);
        // 增加新消息计数
        _newMessageCount++;
        // 限制待显示列表长度，避免内存占用过多
        if (_pendingNewsList.length > _FinancePageConstants.maxPendingNews) {
          _pendingNewsList = _pendingNewsList.take(_FinancePageConstants.maxPendingNews).toList();
        }
      });
    } catch (e, stackTrace) {
      _logger.e('处理实时财经新闻失败', error: e, stackTrace: stackTrace);
    }
  }
  
  /// 加载新消息到列表中
  void _loadNewMessages() {
    if (_pendingNewsList.isEmpty || !mounted) return;
    
    final newMessagesCount = _pendingNewsList.length;
    
    setState(() {
      // 将待显示的新消息添加到主列表顶部
      _newsList.insertAll(0, _pendingNewsList);
      // 限制主列表长度
      if (_newsList.length > _FinancePageConstants.maxMainNewsList) {
        _newsList = _newsList.take(_FinancePageConstants.maxMainNewsList).toList();
      }
      // 清空待显示列表和计数
      _pendingNewsList.clear();
      _newMessageCount = 0;
    });
    
    // 滚动到顶部显示新消息
    _scrollToTopAnimated();
    
    // 记录日志
    _logger.i('已加载 $newMessagesCount 条新消息到列表');
  }
  
  /// 动画滚动到顶部
  void _scrollToTopAnimated() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: _FinancePageConstants.newMessageAnimationDuration,
        curve: Curves.easeOut,
      );
    }
  }

  /// 返回顶部
  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: _FinancePageConstants.scrollAnimationDuration,
        curve: Curves.easeInOut,
      );
    }
  }

  /// 加载财经数据
  Future<void> _loadFinanceData() async {
    if (!mounted) return;
    
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await _httpService.get('/finance', params: {
        'page': 1,
        'limit': _FinancePageConstants.defaultPageSize,
      });

      if (!mounted) return;
      
      final financeResponse = FinanceResponse.fromJson(response);
      
      setState(() {
        _newsList = financeResponse.data;
        _isLoading = false;
      });
      
      _logger.i('成功加载 ${financeResponse.data.length} 条财经新闻');
    } catch (e, stackTrace) {
      if (!mounted) return;
      
      _logger.e('加载财经数据失败', error: e, stackTrace: stackTrace);
      setState(() {
        _errorMessage = _formatErrorMessage(e);
        _isLoading = false;
      });
    }
  }
  
  /// 格式化错误信息
  String _formatErrorMessage(dynamic error) {
    if (error.toString().contains('SocketException')) {
      return '网络连接失败，请检查网络设置';
    } else if (error.toString().contains('TimeoutException')) {
      return '请求超时，请稍后重试';
    } else if (error.toString().contains('FormatException')) {
      return '数据格式错误，请联系技术支持';
    }
    return '加载失败：${error.toString()}';
  }

  /// 构建Socket连接状态指示器
  Widget _buildConnectionStatusIndicator() {
    return Container(
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
    );
  }

  /// 构建新闻卡片
  Widget _buildNewsCard(FinanceNews news, int index) {
    final isExpanded = _expandedCards.contains(news.uniqueId);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  if (!isExpanded) {
                    _expandedCards.add(news.uniqueId);
                  }
                });
              },
              child: Text(
                news.content.trim(), // 格式化内容：去掉开头和结尾的空格符
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
                maxLines: isExpanded ? null : 3,
                overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 6),
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
    // 清理滚动监听器
    _scrollController.removeListener(_onScroll);
    // 清理Socket.IO相关资源
    _financeNewsSubscription?.cancel();
    _connectionSubscription?.cancel();
    // 清理滚动控制器
    _scrollController.dispose();
    
    _logger.d('财经页面资源已清理');
    super.dispose();
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
        child: Stack(
          children: [
            Column(
              children: [
              // Socket连接状态指示器（仅在开发环境显示）
              if (kDebugMode) _buildConnectionStatusIndicator(),
              // 新消息通知栏
              if (_newMessageCount > 0) ...[
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
                                onRefresh: () async {
                                  _loadNewMessages();
                                },
                                child: ListView.builder(
                                  controller: _scrollController, // 添加滚动控制器
                                  padding: const EdgeInsets.all(8), // 设置内容区域的padding值
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
              bottom: _FinancePageConstants.bottomButtonOffset, // 距离底部像素，避免与底部导航栏重叠
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
      ),
    );
  }


}