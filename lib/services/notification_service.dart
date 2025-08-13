import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

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

  Future<void> init() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings iosInit = const DarwinInitializationSettings();

    final InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _flnp.initialize(initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
      // 点击通知回调（可扩展：路由跳转等）
      debugPrint('通知被点击: ${response.payload}');
    });

    // Android 8.0+ 需要创建通知渠道
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'finance_channel',
      '财经通知',
      description: '财经推送提醒',
      importance: Importance.high,
    );
    await _flnp.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Android 13+ 运行时权限请求交给调用方按需触发
    _initialized = true;
  }

  /// 对外统一的显示通知方法
  Future<void> showFinanceNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
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

    await _flnp.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // 简单的唯一id
      title, 
      body,
      details,
      payload: payload,
    );
  }

  /// 可选：请求Android 13+通知权限（在合适的时机调用）
  Future<void> requestAndroidNotificationPermissionIfNeeded() async {
    if (Platform.isAndroid) {
      final androidImpl = _flnp.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestNotificationsPermission();
    }
  }
}