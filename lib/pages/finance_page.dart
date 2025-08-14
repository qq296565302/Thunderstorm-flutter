import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
// 条件导入，避免Web平台兼容性问题
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/finance_model.dart';
import '../services/http_service.dart';
import '../services/socket_manager.dart';

/// 财经页面常量配置
class _FinancePageConstants {
  static const int maxPendingNews = 50;
  static const int maxMainNewsList = 100;
  static const int defaultPageSize = 20;
  static const double scrollThreshold = 200.0;
  static const double bottomButtonOffset = 40.0;
  static const Duration scrollAnimationDuration = Duration(milliseconds: 500);
  static const Duration newMessageAnimationDuration = Duration(milliseconds: 300);
}

/// 财经页面
class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> with WidgetsBindingObserver, AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final HttpService _httpService = HttpService();
  final SocketManager _socketManager = SocketManager();
  
  /// 保持页面状态，避免切换页面时重建
  @override
  bool get wantKeepAlive => true;
  
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
  
  // 新消息通知动画控制器
  late AnimationController _notificationAnimationController;
  late Animation<Offset> _notificationSlideAnimation;
  
  // Socket连接状态
  bool _isSocketConnected = false; // Socket.IO连接状态
  
  // 截图控制器映射（仅在非Web平台使用）
  final Map<String, ScreenshotController> _screenshotControllers = {};
  
  // 分页相关状态
  int _currentPage = 1;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadFinanceData();
    _setupSocketListeners();
    _setupScrollListener();
    // 添加应用生命周期监听
    WidgetsBinding.instance.addObserver(this);
    // 初始化动画控制器
    _initializeAnimations();
  }
  
  /// 初始化动画控制器
  void _initializeAnimations() {
    _notificationAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _notificationSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _notificationAnimationController,
      curve: Curves.easeOutBack,
    ));
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
    
    // 检测是否滑动到底部，触发分页加载
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
      _loadMoreData();
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
    _financeNewsSubscription = _socketManager.financeNewsStream.listen(
      (newsData) {
        _logger.d('=== 财经页面接收到流数据 ===');
        _logger.d('数据类型: ${newsData.runtimeType}');
        _logger.d('数据内容: $newsData');
        _logger.d('页面挂载状态: $mounted');
        
        if (mounted) {
          _handleRealTimeFinanceNews(newsData);
        } else {
          _logger.w('页面未挂载，跳过处理实时数据');
        }
      },
      onError: (error) {
        _logger.e('财经新闻流监听出错', error: error);
      },
      onDone: () {
        _logger.w('财经新闻流已关闭');
      },
    );
  }

  /// 处理实时财经新闻数据
  void _handleRealTimeFinanceNews(Map<String, dynamic> newsData) {
    if (!mounted) return;
    
    try {
      _logger.d('处理实时财经新闻数据: $newsData');
      
      // 提取新闻内容，优先使用嵌套结构中的content
      String content;
      String author;
      String publishTime;
      
      // 检查是否有嵌套的content结构（从Socket数据中提取）
      if (newsData.containsKey('content') && newsData['content'] is Map<String, dynamic>) {
        final contentData = newsData['content'] as Map<String, dynamic>;
        content = contentData['content']?.toString() ?? contentData['title']?.toString() ?? '';
        author = contentData['author']?.toString() ?? '实时推送';
        publishTime = contentData['publishTime']?.toString() ?? 
            DateTime.now().toString().substring(0, 19);
        _logger.d('使用嵌套结构数据: content=$content, author=$author, publishTime=$publishTime');
      } else {
        // 使用扁平结构
        content = newsData['content']?.toString() ?? newsData['title']?.toString() ?? '';
        author = newsData['author']?.toString() ?? '实时推送';
        publishTime = newsData['publishTime']?.toString() ?? 
            DateTime.now().toString().substring(0, 19);
        _logger.d('使用扁平结构数据: content=$content, author=$author, publishTime=$publishTime');
      }
      
      // 验证必要字段
      if (content.trim().isEmpty) {
        _logger.w('接收到空内容的新闻数据');
        return;
      }
      
      // 将实时数据转换为FinanceNews对象
      final newNews = FinanceNews(
        content: content,
        author: author,
        publishTime: publishTime,
      );
      
      _logger.d('创建的FinanceNews对象: ${newNews.toJson()}');
      
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
      
      // 触发新消息通知动画
      _showNotificationAnimation();
    } catch (e, stackTrace) {
      _logger.e('处理实时财经新闻失败', error: e, stackTrace: stackTrace);
    }
  }
  
  /// 显示新消息通知动画
  void _showNotificationAnimation() {
    if (_notificationAnimationController.isCompleted) {
      _notificationAnimationController.reset();
    }
    _notificationAnimationController.forward();
  }
  
  /// 隐藏新消息通知动画
  void _hideNotificationAnimation() {
    _notificationAnimationController.reverse();
  }
  
  /// 加载新消息到列表中
  void _loadNewMessages() {
    if (_pendingNewsList.isEmpty || !mounted) return;
    
    final newMessagesCount = _pendingNewsList.length;
    
    // 先隐藏通知动画
    _hideNotificationAnimation();
    
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
    
    // 清理不再需要的截图控制器
    _cleanupUnusedScreenshotControllers();
    
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

  /// 清理不再需要的截图控制器
   /// 由于现在采用按需创建策略，只清理不在当前新闻列表中的控制器
   void _cleanupUnusedScreenshotControllers() {
     if (kIsWeb || _screenshotControllers.isEmpty) return;
     
     final currentNewsIds = _newsList.map((news) => news.uniqueId).toSet();
     final controllersToRemove = <String>[];
     
     for (final id in _screenshotControllers.keys) {
       if (!currentNewsIds.contains(id)) {
         controllersToRemove.add(id);
       }
     }
     
     for (final id in controllersToRemove) {
       _screenshotControllers.remove(id);
     }
     
     if (controllersToRemove.isNotEmpty) {
       _logger.d('清理了${controllersToRemove.length}个不再需要的截图控制器');
     }
   }

  /// 加载财经数据
  Future<void> _loadFinanceData() async {
    if (!mounted) return;
    
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _currentPage = 1;
        _hasMoreData = true;
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
        _hasMoreData = financeResponse.data.length >= _FinancePageConstants.defaultPageSize;
      });
      
      // 清理不再需要的截图控制器
      _cleanupUnusedScreenshotControllers();
      
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
  
  /// 加载更多数据
  Future<void> _loadMoreData() async {
    if (!mounted || _isLoadingMore || !_hasMoreData || _isLoading) return;
    
    try {
      setState(() {
        _isLoadingMore = true;
      });
      
      final nextPage = _currentPage + 1;
      final response = await _httpService.get('/finance', params: {
        'page': nextPage,
        'limit': _FinancePageConstants.defaultPageSize,
      });

      if (!mounted) return;
      
      final financeResponse = FinanceResponse.fromJson(response);
      
      setState(() {
        _currentPage = nextPage;
        _newsList.addAll(financeResponse.data);
        _isLoadingMore = false;
        _hasMoreData = financeResponse.data.length >= _FinancePageConstants.defaultPageSize;
      });
      
      // 清理不再需要的截图控制器
      _cleanupUnusedScreenshotControllers();
      
      _logger.i('成功加载第$nextPage页 ${financeResponse.data.length} 条财经新闻');
    } catch (e, stackTrace) {
      if (!mounted) return;
      
      _logger.e('加载更多财经数据失败', error: e, stackTrace: stackTrace);
      setState(() {
        _isLoadingMore = false;
      });
      
      // 显示错误提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('加载更多数据失败: ${_formatErrorMessage(e)}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
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
  
  /// 构建加载更多指示器
  Widget _buildLoadMoreIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: _isLoadingMore
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '正在加载更多...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              )
            : !_hasMoreData
                ? Text(
                    '没有更多数据了',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  )
                : const SizedBox.shrink(),
      ),
    );
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
    
    Widget cardContent = Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                Row(
                  children: [
                    Text(
                      news.author,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      news.publishTime,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    // 分享功能
                    _shareNews(news);
                  },
                  child: const Icon(
                    Icons.share,
                    size: 18,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    
    // 根据平台和截图控制器的存在决定是否使用Screenshot包装器
    if (kIsWeb || !_screenshotControllers.containsKey(news.uniqueId)) {
      return cardContent;
    } else {
      return Screenshot(
        controller: _screenshotControllers[news.uniqueId]!,
        child: cardContent,
      );
    }
  }

  /// 分享新闻
  Future<void> _shareNews(FinanceNews news) async {
    try {
      if (kIsWeb) {
        // Web平台直接分享文本内容
        await Share.share(
          '${news.content}\n\n作者: ${news.author}\n时间: ${news.publishTime}',
          subject: '财经新闻分享',
        );
        _showSuccessSnackBar('分享成功');
      } else {
        // 移动平台使用截图分享
        _logger.i('开始生成新闻卡片图片: ${news.content.substring(0, 20)}...');
        
        // 在分享时创建截图控制器，避免预先创建过多控制器
        ScreenshotController controller;
        if (_screenshotControllers.containsKey(news.uniqueId)) {
          controller = _screenshotControllers[news.uniqueId]!;
        } else {
          controller = ScreenshotController();
          _screenshotControllers[news.uniqueId] = controller;
          _logger.d('为分享功能创建截图控制器: ${news.uniqueId}');
          
          // 需要重新构建Widget以应用新的截图控制器
          setState(() {});
          // 等待Widget重建完成
          await Future.delayed(const Duration(milliseconds: 100));
        }
        
        // 等待Widget完全渲染
        await Future.delayed(const Duration(milliseconds: 200));
        
        // 生成截图，增加重试机制
        Uint8List? imageBytes;
        int retryCount = 0;
        const maxRetries = 3;
        
        while (retryCount < maxRetries && imageBytes == null) {
          try {
            _logger.i('尝试截图，第${retryCount + 1}次');
            imageBytes = await controller.capture(
              delay: Duration(milliseconds: 200 + (retryCount * 100)),
              pixelRatio: 2.0,
            );
            
            if (imageBytes != null) {
              _logger.i('截图成功，图片大小: ${imageBytes.length} bytes');
              break;
            }
          } catch (captureError) {
            _logger.w('第${retryCount + 1}次截图失败: $captureError');
          }
          
          retryCount++;
          if (retryCount < maxRetries) {
            await Future.delayed(Duration(milliseconds: 300 * retryCount));
          }
        }
        
        if (imageBytes == null) {
          _logger.e('截图生成失败，已重试$maxRetries次');
          _showErrorSnackBar('图片生成失败，请稍后重试');
          return;
        }
        
        // 显示分享选择对话框
        _showShareDialog(imageBytes, news);
      }
      
    } catch (e, stackTrace) {
      _logger.e('分享新闻失败', error: e, stackTrace: stackTrace);
      _showErrorSnackBar('分享失败: ${e.toString()}');
    }
  }
  
  /// 显示分享选择对话框
  void _showShareDialog(Uint8List imageBytes, FinanceNews news) {
    final ScreenshotController dialogScreenshotController = ScreenshotController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                // 可截图的内容区域
                Screenshot(
                  controller: dialogScreenshotController,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.2),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 顶部标题图片（在卡片内）
                        Center(
                          child: Image.asset(
                            'assets/screenshot-bg.png',
                            height: 80,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // 时间
                        Text(
                          news.publishTime,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // 新闻内容（完整版）
                        Text(
                          news.content,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // 作者信息
                        Text(
                          '来源：${news.author}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // 分享选项
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          if (kIsWeb) {
                            Navigator.of(context).pop();
                            _shareToWeChat(imageBytes, news);
                          } else {
                            try {
                              // 先截图，再关闭对话框
                              final dialogImageBytes = await dialogScreenshotController.capture(
                                delay: const Duration(milliseconds: 200),
                                pixelRatio: 2.0,
                              );
                              Navigator.of(context).pop();
                              if (dialogImageBytes != null) {
                                _shareToWeChat(dialogImageBytes, news);
                              } else {
                                _showErrorSnackBar('对话框截图失败');
                              }
                            } catch (e) {
                              Navigator.of(context).pop();
                              _logger.e('对话框截图失败: $e');
                              _showErrorSnackBar('对话框截图失败: ${e.toString()}');
                            }
                          }
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.green.shade50,
                          foregroundColor: Colors.green.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('分享给他人'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          if (kIsWeb) {
                            Navigator.of(context).pop();
                            _saveToLocal(imageBytes, news);
                          } else {
                            try {
                              // 先截图，再关闭对话框
                              final dialogImageBytes = await dialogScreenshotController.capture(
                                delay: const Duration(milliseconds: 200),
                                pixelRatio: 2.0,
                              );
                              Navigator.of(context).pop();
                              if (dialogImageBytes != null) {
                                _saveToLocal(dialogImageBytes, news);
                              } else {
                                _showErrorSnackBar('对话框截图失败');
                              }
                            } catch (e) {
                              Navigator.of(context).pop();
                              _logger.e('对话框截图失败: $e');
                              _showErrorSnackBar('对话框截图失败: ${e.toString()}');
                            }
                          }
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.blue.shade50,
                          foregroundColor: Colors.blue.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('保存到本地'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                          foregroundColor: Colors.grey.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('取消'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  /// 分享到微信
  Future<void> _shareToWeChat(Uint8List imageBytes, FinanceNews news) async {
    try {
      if (kIsWeb) {
        // Web平台直接分享文本
        await Share.share(
          '${news.content}\n\n作者: ${news.author}\n时间: ${news.publishTime}',
          subject: '财经新闻分享',
        );
      } else {
        // 移动平台分享图片
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/news_${DateTime.now().millisecondsSinceEpoch}.png');
        await file.writeAsBytes(imageBytes);
        
        // 使用share_plus分享图片
        await Share.shareXFiles(
          [XFile(file.path)],
          text: '${news.content}\n\n来源: ${news.author}\n时间: ${news.publishTime}',
          subject: '财经新闻分享',
        );
      }
      
      _logger.i('已调用系统分享功能');
      _showSuccessSnackBar('分享成功');
    } catch (e, stackTrace) {
      _logger.e('分享到微信失败', error: e, stackTrace: stackTrace);
      _showErrorSnackBar('分享失败: ${e.toString()}');
    }
  }
  
  /// 保存到本地
  Future<void> _saveToLocal(Uint8List imageBytes, FinanceNews news) async {
    try {
      if (kIsWeb) {
        // Web平台暂不支持直接保存到本地
        _showErrorSnackBar('Web平台暂不支持保存到本地，请使用分享功能');
        return;
      }
      
      // 获取下载目录
       Directory? directory;
       if (Platform.isAndroid) {
         directory = await getExternalStorageDirectory();
       } else {
         directory = await getApplicationDocumentsDirectory();
       }
       
       if (directory == null) {
         throw Exception('无法获取存储目录');
       }
       
       // 创建文件名
       final fileName = 'news_${DateTime.now().millisecondsSinceEpoch}.png';
       final file = File('${directory.path}/$fileName');
      
      // 保存图片
      await file.writeAsBytes(imageBytes);
      
      _logger.i('图片已保存到: ${file.path}');
      _showSuccessSnackBar('图片已保存到: ${file.path}');
      
    } catch (e, stackTrace) {
      _logger.e('保存到本地失败', error: e, stackTrace: stackTrace);
      _showErrorSnackBar('保存失败: ${e.toString()}');
    }
  }
  
  /// 显示成功提示
  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  /// 显示错误提示
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// 监听应用生命周期状态变化
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // 当应用从后台切换回前台时，如果当前页面是财经页面，则加载新消息
    if (state == AppLifecycleState.resumed && mounted) {
      _logger.d('应用从后台切换回前台，检查是否需要加载新消息');
      
      // 延迟一小段时间确保页面完全恢复
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        
        // 检查是否有待显示的新消息
        if (_pendingNewsList.isNotEmpty) {
          _logger.i('检测到 ${_pendingNewsList.length} 条待显示消息，自动加载');
          _loadNewMessages();
        } else {
          _logger.d('没有待显示的新消息');
        }
      });
    }
  }

  @override
  void dispose() {
    // 移除应用生命周期监听
    WidgetsBinding.instance.removeObserver(this);
    // 清理动画控制器
    _notificationAnimationController.dispose();
    // 清理滚动监听器
    _scrollController.removeListener(_onScroll);
    // 清理Socket.IO相关资源
    _financeNewsSubscription?.cancel();
    _connectionSubscription?.cancel();
    // 清理滚动控制器
    _scrollController.dispose();
    // 清理截图控制器
    try {
      _logger.d('清理${_screenshotControllers.length}个截图控制器');
      _screenshotControllers.clear();
    } catch (e) {
      _logger.w('清理截图控制器时出错: $e');
    }
    
    _logger.d('财经页面资源已清理');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin 需要调用
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
                SlideTransition(
                  position: _notificationSlideAnimation,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      color: Color.fromRGBO(119, 34, 34, 1),
                    ),
                    child: InkWell(
                      onTap: _loadNewMessages,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.notifications_active,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '接收到 $_newMessageCount 条新消息',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            '点击查看',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white70,
                            size: 12,
                          ),
                        ],
                      ),
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
                                  itemCount: _newsList.length + (_hasMoreData || _isLoadingMore ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index < _newsList.length) {
                                      return _buildNewsCard(_newsList[index], index);
                                    } else {
                                      // 显示加载更多指示器
                                      return _buildLoadMoreIndicator();
                                    }
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