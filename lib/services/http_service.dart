import 'dart:convert';
import 'package:http/http.dart' as http;

/// 全局HTTP服务类
class HttpService {
  // 单例模式
  static final HttpService _instance = HttpService._internal();
  factory HttpService() => _instance;
  HttpService._internal();

  /// 全局服务器地址
  static const String baseUrl = 'http://192.168.1.128:3000';

  /// 发起GET请求
  /// [endpoint] 请求端点
  /// [params] 请求参数
  Future<Map<String, dynamic>> get(String endpoint, {Map<String, dynamic>? params}) async {
    try {
      // 构建URL
      Uri uri = Uri.parse('$baseUrl$endpoint');
      if (params != null && params.isNotEmpty) {
        uri = uri.replace(queryParameters: params.map((key, value) => MapEntry(key, value.toString())));
      }

      // 发起请求
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      // 处理响应
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('请求失败: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('网络请求错误: $e');
    }
  }

  /// 发起POST请求
  /// [endpoint] 请求端点
  /// [data] 请求数据
  Future<Map<String, dynamic>> post(String endpoint, {Map<String, dynamic>? data}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: data != null ? json.encode(data) : null,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('请求失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('网络请求错误: $e');
    }
  }
}