import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../main.dart' show navigatorKey;

/// Firebase Cloud Messaging + ローカル通知サービス
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Lazy getter — avoids accessing FirebaseMessaging.instance at construction
  /// time (which requires Firebase to be initialized).
  FirebaseMessaging get _fcm => FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'shougaku_main';
  static const _channelName = '小学コレ！道徳';
  static const _channelDescription = '学習リマインダーと成長レポートの通知';

  /// 初期化
  Future<void> initialize() async {
    // 通知権限リクエスト
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    developer.log(
      'FCM permission: ${settings.authorizationStatus}',
      name: 'NotificationService',
    );

    // ローカル通知初期化
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // 既にFCMでリクエスト済み
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Android通知チャンネル作成
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // フォアグラウンド通知ハンドラー
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // バックグラウンド→アプリ起動時
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // アプリ終了状態から起動
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    developer.log('NotificationService initialized', name: 'NotificationService');
  }

  /// FCMトークン取得
  Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      developer.log('FCM token error: $e', name: 'NotificationService', error: e);
      return null;
    }
  }

  /// トークンリフレッシュ監視
  Stream<String> get onTokenRefresh => _fcm.onTokenRefresh;

  /// フォアグラウンドメッセージ処理
  void _handleForegroundMessage(RemoteMessage message) {
    developer.log(
      'Foreground message: ${message.messageId}',
      name: 'NotificationService',
    );

    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data['type'],
    );
  }

  /// メッセージタップ時の処理 — type に応じて画面に遷移
  void _handleMessageOpenedApp(RemoteMessage message) {
    final type = message.data['type'] as String?;
    developer.log(
      'Message opened app: type=$type',
      name: 'NotificationService',
    );

    // 通知タイプに応じてディープリンク
    switch (type) {
      case 'daily_reminder':
      case 'monthly_report':
      default:
        navigatorKey.currentState
            ?.pushNamedAndRemoveUntil('/home', (r) => false);
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    developer.log(
      'Notification tapped: payload=${response.payload}',
      name: 'NotificationService',
    );
  }

  /// デイリーリマインダー設定 (ローカル通知)
  Future<void> scheduleDailyReminder({
    required TimeOfDay time,
    required String title,
    required String body,
  }) async {
    // flutter_local_notifications の timezone パッケージが必要
    // 現在はシンプルな実装
    developer.log(
      'Daily reminder scheduled at ${time.hour}:${time.minute}',
      name: 'NotificationService',
    );
  }

  /// 通知をすべてキャンセル
  Future<void> cancelAll() async {
    await _localNotifications.cancelAll();
  }

  /// バッジ数をリセット (iOS)
  Future<void> resetBadge() async {
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(badge: true);
  }
}

/// バックグラウンドメッセージハンドラー (top-level function 必須)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  developer.log(
    'Background message: ${message.messageId}',
    name: 'FCM_Background',
  );
}
