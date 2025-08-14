import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// 通知服务（组件化）：统一初始化与展示本地通知
class NotificationService {
  NotificationService._internal();
  static NotificationService? _instance;
  
  /// 获取单例实例
  static NotificationService getInstance() { 
    _instance ??= NotificationService._internal();
    return _instance!;
  }
  
  /// 工厂构造函数
  factory NotificationService() => getInstance();

  final FlutterLocalNotificationsPlugin _flnp = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// 检查是否为开发环境
  bool get _isDebugMode => kDebugMode;

  /// 初始化通知服务
  Future<void> init() async {
    if (_initialized) return;
    
    // 开发环境下跳过通知初始化
    if (_isDebugMode) {
      debugPrint('开发环境：跳过通知服务初始化');
      _initialized = true;
      return;
    }

    try {
      const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      final DarwinInitializationSettings iosInit = const DarwinInitializationSettings();

      final InitializationSettings initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );

      // 初始化插件
      final bool? initialized = await _flnp.initialize(initSettings,
          onDidReceiveNotificationResponse: (NotificationResponse response) {
        // 点击通知回调（可扩展：路由跳转等）
        debugPrint('通知被点击: ${response.payload}');
      });

      // 检查初始化是否成功
      if (initialized != true) {
        debugPrint('通知插件初始化失败');
        return;
      }

      // Android 8.0+ 需要创建通知渠道
      if (Platform.isAndroid) {
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'finance_channel',
          '财经通知',
          description: '财经推送提醒',
          importance: Importance.high,
        );
        await _flnp.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
      }

      _initialized = true;
      debugPrint('通知服务初始化成功');
    } catch (e) {
      debugPrint('通知服务初始化失败: $e');
      _initialized = false;
    }
  }

  /// 对外统一的显示通知方法
  Future<void> showFinanceNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    // 开发环境下跳过通知显示
    if (_isDebugMode) {
      debugPrint('开发环境：跳过通知显示 - $title: $body');
      return;
    }
    
    try {
      // 确保插件已初始化
      if (!_initialized) {
        await init();
      }

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'finance_channel',
        '财经通知',
        channelDescription: '财经推送提醒',
        importance: Importance.high,
        priority: Priority.high,
        enableLights: true,
        enableVibration: true,
        playSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      // 添加额外的安全检查
      if (_initialized) {
        await _flnp.show(
          DateTime.now().millisecondsSinceEpoch ~/ 1000, // 简单的唯一id
          title, 
          body,
          details,
          payload: payload,
        );
      }
    } catch (e) {
      // 捕获并记录错误，避免应用崩溃
      debugPrint('显示通知时发生错误: $e');
    }
  }

  /// 可选：请求Android 13+通知权限（在合适的时机调用）
  Future<void> requestAndroidNotificationPermissionIfNeeded() async {
    if (Platform.isAndroid) {
      final androidImpl = _flnp.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestNotificationsPermission();
    }
  }
}