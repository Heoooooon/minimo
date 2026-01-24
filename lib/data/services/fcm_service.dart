import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../core/utils/app_logger.dart';
import 'pocketbase_service.dart';
import 'auth_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  AppLogger.data('Background message: ${message.messageId}');
}

class FcmService {
  FcmService._();

  static FcmService? _instance;
  static FcmService get instance => _instance ??= FcmService._();

  // Firebase 초기화 후에만 접근 (lazy initialization)
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  bool _isInitialized = false;

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
      _fcmToken = await _messaging.getToken();
      AppLogger.data('FCM Token: $_fcmToken');

      if (AuthService.instance.isLoggedIn && _fcmToken != null) {
        await _saveFcmTokenToServer(_fcmToken!);
      }
    }

    _messaging.onTokenRefresh.listen((newToken) async {
      _fcmToken = newToken;
      AppLogger.data('FCM Token refreshed: $newToken');
      if (AuthService.instance.isLoggedIn) {
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
      final userId = AuthService.instance.currentUser?.id;
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
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    AppLogger.data('Message opened app: ${message.data}');
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
      final userId = AuthService.instance.currentUser?.id;
      if (userId == null) return;

      final client = PocketBaseService.instance.client;
      await client.collection('users').update(userId, body: {'fcm_token': ''});
    } catch (e) {
      AppLogger.data('Failed to clear FCM token: $e', isError: true);
    }
  }
}
