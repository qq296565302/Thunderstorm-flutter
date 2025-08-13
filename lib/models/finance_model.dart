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

  /// 获取新闻的唯一标识符
  /// 使用内容、发布时间和作者的组合生成唯一标识
  String get uniqueId {
    // 使用更安全的方式生成唯一ID，避免hashCode冲突
    final combinedString = '$content|$publishTime|$author';
    return combinedString.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').substring(0, combinedString.length > 50 ? 50 : combinedString.length) + '_${combinedString.hashCode.abs()}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FinanceNews &&
        other.content == content &&
        other.publishTime == publishTime &&
        other.author == author;
  }

  @override
  int get hashCode {
    return content.hashCode ^ publishTime.hashCode ^ author.hashCode;
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