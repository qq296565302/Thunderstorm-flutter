import 'package:flutter/material.dart';
import '../services/http_service.dart';

/// 动态文章数据模型
class ArticleModel {
  final String id;
  final String title;
  final String thumb;

  ArticleModel({
    required this.id,
    required this.title,
    required this.thumb,
  });

  /// 从JSON数据创建文章模型
  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    return ArticleModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      thumb: json['thumb']?.toString() ?? '',
    );
  }
}

/// 动态标签页组件 - 展示联赛动态文章列表
/// 
/// 该组件用于展示指定联赛的动态文章信息，支持分页加载。
/// 功能包括：
/// - 文章列表展示（左图右文布局）
/// - 分页加载更多文章
/// - 点击文章获取文章ID
/// - 加载状态和错误处理
class DynamicTab extends StatefulWidget {
  /// 联赛名称，用于显示和数据请求
  final String leagueName;

  /// 构造函数
  /// 
  /// @param key - Widget标识键
  /// @param leagueName - 必选参数，指定当前联赛名称
  const DynamicTab({
    super.key,
    required this.leagueName,
  });

  @override
  State<DynamicTab> createState() => _DynamicTabState();
}

class _DynamicTabState extends State<DynamicTab> {
  /// 文章列表数据
  List<ArticleModel> _articles = [];
  
  /// 是否正在加载数据
  bool _isLoading = false;
  
  /// 是否正在加载更多数据
  bool _isLoadingMore = false;
  
  /// 是否还有更多数据可加载
  bool _hasMoreData = true;
  
  /// 当前跳过的数据条数（用于分页）
  int _skip = 0;
  
  /// 每次加载的数据条数
  static const int _limit = 50;
  
  /// 滚动控制器，用于监听滚动事件
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadArticles();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 滚动监听器，当滚动到底部时加载更多数据
  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMoreData) {
        _loadMoreArticles();
      }
    }
  }

  /// 加载文章列表数据
  Future<void> _loadArticles() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await HttpService().get(
        '/sport/article/list/db',
        params: {
          'limit': _limit,
          'skip': 0,
        },
      );
      if (response != null && response['data'] != null && response['data'] is List) {
        final List<dynamic> articleData = response['data'];
        final List<ArticleModel> articles = articleData
            .map((json) => ArticleModel.fromJson(json))
            .toList();
  
        setState(() {
          _articles = articles;
          _skip = articles.length;
          _hasMoreData = articles.length >= _limit;
          _isLoading = false;
        });
      } else {
        setState(() {
          _articles = [];
          _hasMoreData = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasMoreData = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载文章失败: $e')),
        );
      }
    }
  }

  /// 加载更多文章数据
  Future<void> _loadMoreArticles() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final response = await HttpService().get(
        '/sport/article/list/db',
        params: {
          'limit': _limit,
          'skip': _skip,
        },
      );

      if (response != null && response['data'] != null && response['data'] is List) {
        final List<dynamic> articleData = response['data'];
        final List<ArticleModel> newArticles = articleData
            .map((json) => ArticleModel.fromJson(json))
            .toList();

        setState(() {
          _articles.addAll(newArticles);
          _skip += newArticles.length;
          _hasMoreData = newArticles.length >= _limit;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _hasMoreData = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载更多文章失败: $e')),
        );
      }
    }
  }

  /// 处理文章点击事件
  void _onArticleTap(ArticleModel article) {
    // 打印文章ID到控制台，实际应用中可以导航到文章详情页
    print('点击文章，ID: ${article.id}');
    
    // 显示文章ID的提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('文章ID: ${article.id}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 构建文章列表项
  Widget _buildArticleItem(ArticleModel article) {
    return InkWell(
      onTap: () => _onArticleTap(article),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左侧图片区域，占据约25%宽度
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.25,
              height: 80,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: article.thumb.isNotEmpty
                    ? Image.network(
                        article.thumb,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                              size: 30,
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.article,
                          color: Colors.grey,
                          size: 30,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // 右侧标题区域
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建加载更多指示器
  Widget _buildLoadMoreIndicator() {
    if (!_isLoadingMore) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// 构建无更多数据提示
  Widget _buildNoMoreDataWidget() {
    if (_hasMoreData || _articles.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          '没有更多文章了',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 如果正在初始加载，显示加载指示器
    if (_isLoading && _articles.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // 如果没有文章数据，显示空状态
    if (_articles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '暂无${widget.leagueName}动态文章',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadArticles,
              child: const Text('重新加载'),
            ),
          ],
        ),
      );
    }

    // 显示文章列表
    return RefreshIndicator(
      onRefresh: () async {
        _skip = 0;
        _hasMoreData = true;
        await _loadArticles();
      },
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _articles.length + 2, // +2 for loading indicator and no more data widget
        itemBuilder: (context, index) {
          if (index < _articles.length) {
            return _buildArticleItem(_articles[index]);
          } else if (index == _articles.length) {
            return _buildLoadMoreIndicator();
          } else {
            return _buildNoMoreDataWidget();
          }
        },
      ),
    );
  }
}