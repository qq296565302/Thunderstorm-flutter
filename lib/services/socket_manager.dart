import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:logger/logger.dart';

/// Socket.IO连接管理器
/// 负责统一管理Socket.IO连接、事件监听和数据分发
class SocketManager {
  static final SocketManager _instance = SocketManager._internal();
  factory SocketManager() => _instance;
  SocketManager._internal();

  // 日志记录器
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

  IO.Socket? _socket;
  bool _isConnected = false;
  String? _serverUrl;

  // 连接状态流控制器
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  
  // 财经新闻流控制器
  final StreamController<Map<String, dynamic>> _financeNewsController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  // 体育新闻流控制器
  final StreamController<Map<String, dynamic>> _sportsNewsController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  // 通用消息流控制器
  final StreamController<Map<String, dynamic>> _messageController = 
      StreamController<Map<String, dynamic>>.broadcast();

  /// 获取连接状态流
  Stream<bool> get connectionStream => _connectionController.stream;
  
  /// 获取财经新闻流
  Stream<Map<String, dynamic>> get financeNewsStream => _financeNewsController.stream;
  
  /// 获取体育新闻流
  Stream<Map<String, dynamic>> get sportsNewsStream => _sportsNewsController.stream;
  
  /// 获取通用消息流
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  
  /// 获取当前连接状态
  bool get isConnected => _isConnected;
  
  /// 获取服务器地址
  String? get serverUrl => _serverUrl;

  /// 连接到Socket.IO服务器
  /// [url] 服务器地址
  /// [options] 连接选项
  Future<void> connect(String url, {Map<String, dynamic>? options}) async {
    try {
      if (_socket != null && _isConnected) {
        return;
      }

      _serverUrl = url;
      
      // 创建Socket.IO连接
      _socket = IO.io(url, IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setExtraHeaders(options ?? {})
          .build());

      // 设置事件监听器
      _setupEventListeners();
      
      // 连接到服务器
      _socket!.connect();
      
    } catch (e) {
      _updateConnectionStatus(false);
      rethrow;
    }
  }

  /// 设置事件监听器
  void _setupEventListeners() {
    if (_socket == null) return;

    // 连接成功事件
    _socket!.onConnect((_) {
      _updateConnectionStatus(true);
      // 连接成功后发送subscribeFinance消息
      _socket!.emit('subscribeFinance');
    });

    // 监听financePush事件
    _socket!.on('financePush', (data) {
      try {
        if (data is Map<String, dynamic>) {
          // 检查数据结构并提取content字段
          if (data.containsKey('content') && data['content'] is Map<String, dynamic>) {
            // 提取财经新闻内容数据
            Map<String, dynamic> financeContent = data['content'];
            // 添加额外的元数据
            financeContent['message'] = data['message'] ?? '';
            financeContent['timestamp'] = data['timestamp'] ?? '';
            financeContent['type'] = data['type'] ?? 'finance';
            
            _financeNewsController.add(financeContent);
          } 
        }
      } catch (e) {
        _logger.e('处理financePush事件时发生错误', error: e);
      }
    });

    // 连接断开事件
    _socket!.onDisconnect((_) {
      _updateConnectionStatus(false);
    });

    // 连接错误事件
    _socket!.onConnectError((error) {
      _updateConnectionStatus(false);
    });

  }

  /// 更新连接状态
  void _updateConnectionStatus(bool connected) {
    _isConnected = connected;
    _connectionController.add(connected);
  }

  /// 订阅频道
  /// [channel] 频道名称（如：finance_news, sports_news）
  void subscribe(String channel) {
    if (_socket != null && _isConnected) {
      _socket!.emit('subscribe', channel);
    } else {
      _logger.w('Socket.IO未连接，无法订阅频道: $channel');
    }
  }

  /// 取消订阅频道
  /// [channel] 频道名称
  void unsubscribe(String channel) {
    if (_socket != null && _isConnected) {
      _socket!.emit('unsubscribe', channel);
      _logger.i('取消订阅频道: $channel');
    } else {
      _logger.w('Socket.IO未连接，无法取消订阅频道: $channel');
    }
  }

  /// 发送消息
  /// [event] 事件名称
  /// [data] 消息数据
  void sendMessage(String event, dynamic data) {
    if (_socket != null && _isConnected) {
      _socket!.emit(event, data);
      _logger.d('发送消息 - 事件: $event, 数据: $data');
    } else {
      _logger.w('Socket.IO未连接，无法发送消息');
    }
  }

  /// 断开连接
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _updateConnectionStatus(false);
      _logger.i('Socket.IO连接已断开');
    }
  }

  /// 重新连接
  Future<void> reconnect() async {
    if (_serverUrl != null) {
      disconnect();
      await Future.delayed(const Duration(seconds: 1));
      await connect(_serverUrl!);
    } else {
      _logger.e('无法重新连接：服务器地址为空');
    }
  }

  /// 释放资源
  void dispose() {
    disconnect();
    _connectionController.close();
    _financeNewsController.close();
    _sportsNewsController.close();
    _messageController.close();
    _logger.i('SocketManager资源已释放');
  }

  /// 获取连接信息
  Map<String, dynamic> getConnectionInfo() {
    return {
      'isConnected': _isConnected,
      'serverUrl': _serverUrl,
      'socketId': _socket?.id,
      'connected': _socket?.connected ?? false,
    };
  }
}