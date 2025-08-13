import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:logger/logger.dart';
import 'package:flutter/widgets.dart';
import 'notification_service.dart';

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

  io.Socket? _socket;
  bool _isConnected = false;
  String? _serverUrl;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  Timer? _connectionCheckTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 50;
  static const Duration _reconnectDelay = Duration(seconds: 1);
  static const Duration _heartbeatInterval = Duration(seconds: 10);
  static const Duration _connectionCheckInterval = Duration(seconds: 5);
  bool _shouldReconnect = true;

  // App生命周期状态（用于判断前后台）
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;
  final StreamController<AppLifecycleState> _appLifecycleController = StreamController<AppLifecycleState>.broadcast();

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
  
  /// 获取应用生命周期状态流
  Stream<AppLifecycleState> get appLifecycleStream => _appLifecycleController.stream;
  
  /// 获取当前连接状态
  bool get isConnected => _isConnected;
  
  /// 获取服务器地址
  String? get serverUrl => _serverUrl;

  /// 更新应用生命周期状态
  void updateAppLifecycleState(AppLifecycleState state) {
    _appLifecycleState = state;
    _appLifecycleController.add(state);
  }

  /// 连接到Socket.IO服务器
  Future<void> connect(String url, {Map<String, dynamic>? options}) async {
    try {
      if (_socket != null && _isConnected) {
        return;
      }

      _serverUrl = url;
      
      _socket = io.io(url, io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setReconnectionAttempts(0)
          .setTimeout(20000)
          .setExtraHeaders(options ?? {})
          .build());

      _setupEventListeners();
      _socket!.connect();
      
    } catch (e) {
      _updateConnectionStatus(false);
      rethrow;
    }
  }

  /// 设置事件监听器
  void _setupEventListeners() {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      _logger.i('Socket.IO连接成功');
      _reconnectAttempts = 0;
      _updateConnectionStatus(true);
      _socket!.emit('subscribeFinance');
      _startHeartbeat();
      _startConnectionCheck();
    });

    _socket!.on('financePush', (data) {
      try {
        if (data is Map<String, dynamic>) {
          _logger.d('收到financePush数据: $data');
          
          Map<String, dynamic>? financeContent;
          if (data.containsKey('content') && data['content'] is Map<String, dynamic>) {
            financeContent = Map<String, dynamic>.from(data['content']);
            financeContent['message'] = data['message'] ?? '';
            financeContent['timestamp'] = data['timestamp'] ?? '';
            financeContent['type'] = data['type'] ?? 'finance';
          } else {
            financeContent = Map<String, dynamic>.from(data);
          }

          _financeNewsController.add(financeContent);

          // 如果APP在后台，发送系统通知
          if (_appLifecycleState != AppLifecycleState.resumed) {
            final title = (financeContent['author']?.toString().isNotEmpty ?? false)
                ? financeContent['author'].toString()
                : '新的财经消息';
            final body = financeContent['content']?.toString() ?? '您有一条新的财经消息';
            NotificationService().showFinanceNotification(title: title, body: body, payload: 'finance');
          }
        }
      } catch (e) {
        _logger.e('处理financePush事件时发生错误', error: e);
      }
    });

    _socket!.onDisconnect((reason) {
      _logger.w('Socket.IO连接断开，原因: $reason');
      _updateConnectionStatus(false);
      _stopHeartbeat();
      _stopConnectionCheck();
      if (_shouldReconnect && reason != 'io client disconnect') {
        _scheduleReconnect();
      }
    });

    _socket!.onConnectError((error) {
      _logger.e('Socket.IO连接错误: $error');
      _updateConnectionStatus(false);
      if (_shouldReconnect) {
        _scheduleReconnect();
      }
    });

    _socket!.on('pong', (_) {
      _logger.d('收到服务器心跳响应');
    });
  }

  void _updateConnectionStatus(bool connected) {
    _isConnected = connected;
    _connectionController.add(connected);
  }

  void subscribe(String channel) {
    if (_socket != null && _isConnected) {
      _socket!.emit('subscribe', channel);
    } else {
      _logger.w('Socket.IO未连接，无法订阅频道: $channel');
    }
  }

  void unsubscribe(String channel) {
    if (_socket != null && _isConnected) {
      _socket!.emit('unsubscribe', channel);
      _logger.i('取消订阅频道: $channel');
    } else {
      _logger.w('Socket.IO未连接，无法取消订阅频道: $channel');
    }
  }

  void sendMessage(String event, dynamic data) {
    if (_socket != null && _isConnected) {
      _socket!.emit(event, data);
      _logger.d('发送消息 - 事件: $event, 数据: $data');
    } else {
      _logger.w('Socket.IO未连接，无法发送消息');
    }
  }

  void disconnect() {
    _shouldReconnect = false;
    _stopReconnectTimer();
    _stopHeartbeat();
    _stopConnectionCheck();
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _updateConnectionStatus(false);
      _logger.i('Socket.IO连接已断开');
    }
  }

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
          _scheduleReconnect();
        }
      }
    });
  }

  void _stopReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (_socket != null && _isConnected) {
        _socket!.emit('ping');
      } else {
        _stopHeartbeat();
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _startConnectionCheck() {
    _stopConnectionCheck();
    _connectionCheckTimer = Timer.periodic(_connectionCheckInterval, (timer) {
      if (_socket != null) {
        bool actuallyConnected = _socket!.connected;
        if (_isConnected != actuallyConnected) {
          _logger.w('检测到连接状态不一致，实际状态: $actuallyConnected，记录状态: $_isConnected');
          _updateConnectionStatus(actuallyConnected);
        }
        
        if (_shouldReconnect && !actuallyConnected) {
          _logger.w('检测到连接断开，尝试重连');
          _scheduleReconnect();
        }
      } else if (_shouldReconnect) {
        _logger.w('Socket对象为空，尝试重连');
        _scheduleReconnect();
      }
    });
  }

  void _stopConnectionCheck() {
    _connectionCheckTimer?.cancel();
    _connectionCheckTimer = null;
  }

  void dispose() {
    disconnect();
    _stopReconnectTimer();
    _stopHeartbeat();
    _stopConnectionCheck();
    _connectionController.close();
    _appLifecycleController.close();
    _financeNewsController.close();
    _sportsNewsController.close();
    _messageController.close();
    _logger.i('SocketManager资源已释放');
  }

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

  void resetReconnectState() {
    _reconnectAttempts = 0;
    _shouldReconnect = true;
  }
}