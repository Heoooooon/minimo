import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../core/utils/app_logger.dart';
import '../../main.dart' show navigatorKey;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:permission_handler/permission_handler.dart';
import '../../domain/models/schedule_data.dart';

/// 푸시 알림 서비스
///
/// flutter_local_notifications 기반 로컬 푸시 알림 관리
class NotificationService {
  NotificationService._();

  static NotificationService? _instance;
  static NotificationService get instance =>
      _instance ??= NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 타임존 초기화
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    // 알림 설정
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      // Foreground에서도 알림 표시
      notificationCategories: [],
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _isInitialized = true;
    AppLogger.ui('NotificationService initialized');
  }

  /// 알림 탭 시 콜백 - 해당 어항 상세 화면으로 이동
  void _onNotificationTap(NotificationResponse response) {
    AppLogger.ui('Notification tapped: ${response.payload}');

    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    // payload 형식: "schedule:<scheduleId>:aquarium:<aquariumId>"
    if (payload.startsWith('schedule:')) {
      final parts = payload.split(':');
      if (parts.length >= 4 && parts[2] == 'aquarium') {
        final aquariumId = parts[3];
        navigator.pushNamed('/aquarium/detail', arguments: aquariumId);
      }
    }
  }

  /// 알림 권한 요청
  Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// 알림 권한 확인
  Future<bool> hasPermission() async {
    // iOS에서는 flutter_local_notifications로 직접 확인
    final iosImpl = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (iosImpl != null) {
      final settings = await iosImpl.checkPermissions();
      return settings?.isEnabled ?? false;
    }

    // Android는 permission_handler 사용
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// 일정 알림 예약
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required RepeatCycle repeatCycle,
    String? payload,
  }) async {
    // 권한 확인
    if (!await hasPermission()) {
      final granted = await requestPermission();
      if (!granted) {
        AppLogger.warning('Notification permission denied');
        return;
      }
    }

    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    // 이미 지난 시간이면 다음 날로 설정
    final now = tz.TZDateTime.now(tz.local);
    var adjustedTime = tzScheduledTime;
    if (adjustedTime.isBefore(now)) {
      adjustedTime = adjustedTime.add(const Duration(days: 1));
    }

    switch (repeatCycle) {
      case RepeatCycle.daily:
        await _notifications.zonedSchedule(
          id,
          title,
          body,
          adjustedTime,
          _notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: payload,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        break;

      case RepeatCycle.weekly:
        await _notifications.zonedSchedule(
          id,
          title,
          body,
          adjustedTime,
          _notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: payload,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        break;

      case RepeatCycle.none:
      case RepeatCycle.everyOtherDay:
      case RepeatCycle.biweekly:
      case RepeatCycle.monthly:
        // 단일 알림 또는 커스텀 반복
        await _notifications.zonedSchedule(
          id,
          title,
          body,
          adjustedTime,
          _notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: payload,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        break;
    }

    AppLogger.ui('Notification scheduled: $id at $adjustedTime');
  }

  /// 즉시 알림 표시 (테스트용)
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _notifications.show(
      id,
      title,
      body,
      _notificationDetails,
      payload: payload,
    );
  }

  /// 알림 취소
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    AppLogger.ui('Notification cancelled: $id');
  }

  /// 모든 알림 취소
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    AppLogger.ui('All notifications cancelled');
  }

  /// 예약된 알림 목록 조회
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// 알림 상세 설정
  NotificationDetails get _notificationDetails {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'schedule_channel',
        '일정 알림',
        channelDescription: '어항 관리 일정 알림',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  /// 일정 ID를 알림 ID로 변환 (해시 기반)
  int scheduleIdToNotificationId(String scheduleId) {
    return scheduleId.hashCode.abs() % 2147483647;
  }
}
