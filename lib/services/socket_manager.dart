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
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const Duration _reconnectDelay = Duration(seconds: 5);
  static const Duration _heartbeatInterval = Duration(seconds: 30);
  bool _shouldReconnect = true;

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
          .setReconnectionAttempts(0) // 禁用内置重连，使用自定义重连
          .setTimeout(20000) // 连接超时20秒
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
      _logger.i('Socket.IO连接成功');
      _reconnectAttempts = 0; // 重置重连计数
      _updateConnectionStatus(true);
      // 连接成功后发送subscribeFinance消息
      _socket!.emit('subscribeFinance');
      // 启动心跳检测
      _startHeartbeat();
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
    _socket!.onDisconnect((reason) {
      _logger.w('Socket.IO连接断开，原因: $reason');
      _updateConnectionStatus(false);
      _stopHeartbeat();
      // 如果不是主动断开，则尝试重连
      if (_shouldReconnect && reason != 'io client disconnect') {
        _scheduleReconnect();
      }
    });

    // 连接错误事件
    _socket!.onConnectError((error) {
      _logger.e('Socket.IO连接错误: $error');
      _updateConnectionStatus(false);
      if (_shouldReconnect) {
        _scheduleReconnect();
      }
    });

    // 监听心跳响应
    _socket!.on('pong', (_) {
      _logger.d('收到服务器心跳响应');
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
    _shouldReconnect = false; // 停止自动重连
    _stopReconnectTimer();
    _stopHeartbeat();
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
      _shouldReconnect = true;
      _stopReconnectTimer();
      if (_socket != null) {
        _socket!.disconnect();
        _socket!.dispose();
        _socket = null;
      }
      await Future.delayed(const Duration(seconds: 1));
      await connect(_serverUrl!);
    } else {
      _logger.e('无法重新连接：服务器地址为空');
    }
  }

  /// 安排重连
  void _scheduleReconnect() {
    if (!_shouldReconnect || _reconnectAttempts >= _maxReconnectAttempts) {
      if (_reconnectAttempts >= _maxReconnectAttempts) {
        _logger.e('达到最大重连次数($_maxReconnectAttempts)，停止重连');
      }
      return;
    }

    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectDelay.inSeconds * _reconnectAttempts);
    _logger.i('第$_reconnectAttempts次重连将在${delay.inSeconds}秒后开始');

    _stopReconnectTimer();
    _reconnectTimer = Timer(delay, () async {
      if (_shouldReconnect && _serverUrl != null) {
        try {
          _logger.i('开始第$_reconnectAttempts次重连尝试');
          await connect(_serverUrl!);
        } catch (e) {
          _logger.e('重连失败: $e');
          _scheduleReconnect(); // 继续尝试重连
        }
      }
    });
  }

  /// 停止重连定时器
  void _stopReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  /// 启动心跳检测
  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (_socket != null && _isConnected) {
        _socket!.emit('ping');
        _logger.d('发送心跳包');
      } else {
        _stopHeartbeat();
      }
    });
  }

  /// 停止心跳检测
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// 释放资源
  void dispose() {
    disconnect();
    _stopReconnectTimer();
    _stopHeartbeat();
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
      'reconnectAttempts': _reconnectAttempts,
      'shouldReconnect': _shouldReconnect,
    };
  }

  /// 重置重连状态
  void resetReconnectState() {
    _reconnectAttempts = 0;
    _shouldReconnect = true;
  }
}