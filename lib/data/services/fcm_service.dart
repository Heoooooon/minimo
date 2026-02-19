import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../core/utils/app_logger.dart';
import '../../main.dart' show navigatorKey;
import 'notification_service.dart';
import 'pocketbase_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  AppLogger.data('Background message: ${message.messageId}');

  // 백그라운드에서 로컬 알림 표시
  final notification = message.notification;
  if (notification == null) return;

  const androidDetails = AndroidNotificationDetails(
    'fcm_channel',
    '알림',
    channelDescription: '서버 푸시 알림',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );
  const iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );
  const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.show(
    message.hashCode,
    notification.title,
    notification.body,
    details,
    payload: _buildPayloadFromData(message.data),
  );
}

/// FCM data를 로컬 알림 payload 문자열로 변환
String? _buildPayloadFromData(Map<String, dynamic> data) {
  final targetType = data['target_type'] as String?;
  final targetId = data['target_id'] as String?;
  if (targetType == null || targetId == null) return null;
  return '$targetType:$targetId';
}

class FcmService {
  FcmService._();

  static FcmService? _instance;
  static FcmService get instance => _instance ??= FcmService._();

  // Firebase 초기화 후에만 접근 (lazy initialization)
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  bool get _isLoggedIn => PocketBaseService.instance.client.authStore.isValid;
  String? get _currentUserId =>
      PocketBaseService.instance.client.authStore.record?.id;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  bool _isInitialized = false;

  /// iOS에서 APNS 토큰이 준비될 때까지 대기 후 FCM 토큰 획득
  Future<String?> _getTokenSafely() async {
    try {
      // iOS에서는 APNS 토큰이 먼저 준비되어야 함
      if (Platform.isIOS) {
        String? apnsToken;
        // 최대 10초 대기 (1초 간격으로 10번 시도)
        for (int i = 0; i < 10; i++) {
          apnsToken = await _messaging.getAPNSToken();
          if (apnsToken != null) break;
          await Future.delayed(const Duration(seconds: 1));
        }
        if (apnsToken == null) {
          AppLogger.data(
            'APNS token not available (simulator or no push capability)',
          );
          return null;
        }
      }
      return await _messaging.getToken();
    } catch (e) {
      AppLogger.data('Failed to get FCM token: $e', isError: true);
      return null;
    }
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    await Firebase.initializeApp();

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      _fcmToken = await _getTokenSafely();
      if (_fcmToken != null) {
        AppLogger.data('FCM Token: $_fcmToken');

        if (_isLoggedIn) {
          await _saveFcmTokenToServer(_fcmToken!);
        }
      }
    }

    _messaging.onTokenRefresh.listen((newToken) async {
      _fcmToken = newToken;
      AppLogger.data('FCM Token refreshed: $newToken');
      if (_isLoggedIn) {
        await _saveFcmTokenToServer(newToken);
      }
    });

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    _isInitialized = true;
    AppLogger.ui('FcmService initialized');
  }

  Future<void> _saveFcmTokenToServer(String token) async {
    try {
      final userId = _currentUserId;
      if (userId == null) return;

      final client = PocketBaseService.instance.client;
      await client
          .collection('users')
          .update(userId, body: {'fcm_token': token});
      AppLogger.data('FCM token saved to server');
    } catch (e) {
      AppLogger.data('Failed to save FCM token: $e', isError: true);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    AppLogger.data('Foreground message: ${message.notification?.title}');

    final notification = message.notification;
    if (notification == null) return;

    // 포그라운드에서 로컬 알림으로 표시
    final NotificationService notificationService;
    try {
      notificationService = NotificationService.instance;
    } catch (_) {
      return;
    }
    notificationService.showNotification(
      id: message.hashCode,
      title: notification.title ?? '',
      body: notification.body ?? '',
      payload: _buildPayloadFromData(message.data),
    );
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    AppLogger.data('Message opened app: ${message.data}');
    _navigateByData(message.data);
  }

  /// FCM 데이터 기반 딥링크 네비게이션
  void _navigateByData(Map<String, dynamic> data) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    final targetType = data['target_type'] as String?;
    final targetId = data['target_id'] as String?;
    if (targetType == null || targetId == null) {
      navigator.pushNamed('/notifications');
      return;
    }

    switch (targetType) {
      case 'question':
        navigator.pushNamed('/question-detail', arguments: targetId);
        break;
      case 'post':
        navigator.pushNamed('/post-detail', arguments: targetId);
        break;
      case 'user':
        navigator.pushNamed('/notifications');
        break;
      default:
        navigator.pushNamed('/notifications');
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    AppLogger.data('Subscribed to topic: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    AppLogger.data('Unsubscribed from topic: $topic');
  }

  Future<void> updateTokenOnLogin() async {
    if (_fcmToken != null) {
      await _saveFcmTokenToServer(_fcmToken!);
    }
  }

  Future<void> clearTokenOnLogout() async {
    try {
      final userId = _currentUserId;
      if (userId == null) return;

      final client = PocketBaseService.instance.client;
      await client.collection('users').update(userId, body: {'fcm_token': ''});
    } catch (e) {
      AppLogger.data('Failed to clear FCM token: $e', isError: true);
    }
  }
}
