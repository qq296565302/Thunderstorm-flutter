/// 财经新闻数据模型
class FinanceNews {
  final String content;
  final String publishTime;
  final String author;

  FinanceNews({
    required this.content,
    required this.publishTime,
    required this.author,
  });

  /// 从JSON创建FinanceNews对象
  factory FinanceNews.fromJson(Map<String, dynamic> json) {
    return FinanceNews(
      content: json['content'] ?? '',
      publishTime: json['publishTime'] ?? '',
      author: json['author'] ?? '',
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'publishTime': publishTime,
      'author': author,
    };
  }
}

/// 财经API响应数据模型
class FinanceResponse {
  final List<FinanceNews> data;
  final bool success;
  final String? message;

  FinanceResponse({
    required this.data,
    required this.success,
    this.message,
  });

  /// 从JSON创建FinanceResponse对象
  factory FinanceResponse.fromJson(Map<String, dynamic> json) {
    List<FinanceNews> newsList = [];
    if (json['data'] != null && json['data'] is List) {
      newsList = (json['data'] as List)
          .map((item) => FinanceNews.fromJson(item))
          .toList();
    }

    return FinanceResponse(
      data: newsList,
      success: json['success'] ?? false,
      message: json['message'],
    );
  }
}