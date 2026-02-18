import 'package:pocketbase/pocketbase.dart';
import '../../config/app_config.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/pb_filter.dart';
import '../../domain/models/notification_data.dart';
import 'pocketbase_service.dart';

class PbNotificationService {
  PbNotificationService._();

  static PbNotificationService? _instance;
  static PbNotificationService get instance =>
      _instance ??= PbNotificationService._();
  int get _deleteConcurrency => AppConfig.notificationDeleteConcurrency > 0
      ? AppConfig.notificationDeleteConcurrency
      : 10;

  PocketBase get _pb => PocketBaseService.instance.client;
  String? get _currentUserId => _pb.authStore.record?.id;

  Future<List<NotificationData>> getNotifications({
    int page = 1,
    int perPage = 20,
    bool unreadOnly = false,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) return [];

      String filter = PbFilter.eq('user', userId);
      if (unreadOnly) {
        filter += ' && is_read = false';
      }

      final result = await _pb
          .collection('notifications')
          .getList(
            page: page,
            perPage: perPage,
            filter: filter,
            sort: '-created',
            expand: 'actor',
          );

      return result.items
          .map((record) => NotificationData.fromRecord(record))
          .toList();
    } catch (e) {
      AppLogger.data('Failed to get notifications: $e', isError: true);
      return [];
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final userId = _currentUserId;
      if (userId == null) return 0;

      final result = await _pb.send(
        '/api/notifications/unread-count',
        method: 'GET',
      );

      return (result as Map<String, dynamic>)['count'] as int? ?? 0;
    } catch (e) {
      AppLogger.data('Failed to get unread count: $e', isError: true);
      return 0;
    }
  }

  Future<bool> markAsRead(String notificationId) async {
    try {
      await _pb
          .collection('notifications')
          .update(notificationId, body: {'is_read': true});
      return true;
    } catch (e) {
      AppLogger.data('Failed to mark as read: $e', isError: true);
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      await _pb.send('/api/notifications/mark-all-read', method: 'POST');
      return true;
    } catch (e) {
      AppLogger.data('Failed to mark all as read: $e', isError: true);
      return false;
    }
  }

  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _pb.collection('notifications').delete(notificationId);
      return true;
    } catch (e) {
      AppLogger.data('Failed to delete notification: $e', isError: true);
      return false;
    }
  }

  Future<bool> deleteAllNotifications() async {
    final stopwatch = Stopwatch()..start();
    String? userId;
    bool hasError = false;
    int deletedCount = 0;
    int batchCount = 0;

    try {
      userId = _currentUserId;
      if (userId == null) return false;

      final filter = PbFilter.eq('user', userId);

      // 페이지네이션 배치 삭제 (한 번에 전체를 메모리에 올리지 않음)
      while (true) {
        final batch = await _pb
            .collection('notifications')
            .getList(page: 1, perPage: 100, filter: filter);

        if (batch.items.isEmpty) break;
        batchCount++;

        for (int i = 0; i < batch.items.length; i += _deleteConcurrency) {
          final chunk = batch.items.skip(i).take(_deleteConcurrency).toList();
          await Future.wait(
            chunk.map((notification) {
              return _pb.collection('notifications').delete(notification.id);
            }),
          );
          deletedCount += chunk.length;
        }
      }
      return true;
    } catch (e) {
      hasError = true;
      AppLogger.data('Failed to delete all notifications: $e', isError: true);
      return false;
    } finally {
      stopwatch.stop();
      AppLogger.perf(
        'Notification.deleteAll',
        stopwatch.elapsed,
        fields: {
          'deleted': deletedCount,
          'batches': batchCount,
          'concurrency': _deleteConcurrency,
          'hasUser': userId != null,
        },
        isError: hasError,
      );
    }
  }
}
