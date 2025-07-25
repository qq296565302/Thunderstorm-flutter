import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';

/// Socket.IO服务类，用于管理WebSocket连接和事件处理
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;
  
  // 事件流控制器
  final StreamController<Map<String, dynamic>> _financeNewsController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _sportsNewsController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _connectionController = 
      StreamController<bool>.broadcast();

  // 获取事件流
  Stream<Map<String, dynamic>> get financeNewsStream => _financeNewsController.stream;
  Stream<Map<String, dynamic>> get sportsNewsStream => _sportsNewsController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  
  bool get isConnected => _isConnected;

  /// 连接到Socket.IO服务器
  Future<void> connect(String serverUrl) async {
    try {
      _socket = IO.io(serverUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });

      _socket!.connect();

      // 连接成功事件
      _socket!.on('connect', (_) {
        _isConnected = true;
        _connectionController.add(true);
      });

      // 连接断开事件
      _socket!.on('disconnect', (_) {
        _isConnected = false;
        _connectionController.add(false);
      });

      // 连接错误事件
      _socket!.on('connect_error', (error) {
        _isConnected = false;
        _connectionController.add(false);
      });

      // 监听财经新闻更新
      _socket!.on('finance_news_update', (data) {
        _financeNewsController.add(Map<String, dynamic>.from(data));
      });

      // 监听体育新闻更新
      _socket!.on('sports_news_update', (data) {
        _sportsNewsController.add(Map<String, dynamic>.from(data));
      });

    } catch (e) {
      _isConnected = false;
      _connectionController.add(false);
    }
  }

  /// 断开Socket.IO连接
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
      _isConnected = false;
      _connectionController.add(false);
    }
  }

  /// 发送消息到服务器
  void emit(String event, dynamic data) {
    if (_socket != null && _isConnected) {
      _socket!.emit(event, data);
    } 
  }

  /// 订阅特定频道
  void subscribe(String channel) {
    emit('subscribe', {'channel': channel});
  }

  /// 取消订阅特定频道
  void unsubscribe(String channel) {
    emit('unsubscribe', {'channel': channel});
  }

  /// 发送心跳包
  void sendHeartbeat() {
    emit('heartbeat', {'timestamp': DateTime.now().millisecondsSinceEpoch});
  }

  /// 释放资源
  void dispose() {
    disconnect();
    _financeNewsController.close();
    _sportsNewsController.close();
    _connectionController.close();
  }
}