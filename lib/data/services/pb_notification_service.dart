import 'package:pocketbase/pocketbase.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/models/notification_data.dart';
import 'pocketbase_service.dart';
import 'auth_service.dart';

class PbNotificationService {
  PbNotificationService._();

  static PbNotificationService? _instance;
  static PbNotificationService get instance =>
      _instance ??= PbNotificationService._();

  PocketBase get _pb => PocketBaseService.instance.client;

  Future<List<NotificationData>> getNotifications({
    int page = 1,
    int perPage = 20,
    bool unreadOnly = false,
  }) async {
    try {
      final userId = AuthService.instance.currentUser?.id;
      if (userId == null) return [];

      String filter = 'user = "$userId"';
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
      final userId = AuthService.instance.currentUser?.id;
      if (userId == null) return 0;

      final result = await _pb
          .collection('notifications')
          .getList(
            page: 1,
            perPage: 1,
            filter: 'user = "$userId" && is_read = false',
          );

      return result.totalItems;
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
      final userId = AuthService.instance.currentUser?.id;
      if (userId == null) return false;

      final unread = await _pb
          .collection('notifications')
          .getFullList(filter: 'user = "$userId" && is_read = false');

      for (final notification in unread) {
        await _pb
            .collection('notifications')
            .update(notification.id, body: {'is_read': true});
      }
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
    try {
      final userId = AuthService.instance.currentUser?.id;
      if (userId == null) return false;

      final all = await _pb
          .collection('notifications')
          .getFullList(filter: 'user = "$userId"');

      for (final notification in all) {
        await _pb.collection('notifications').delete(notification.id);
      }
      return true;
    } catch (e) {
      AppLogger.data('Failed to delete all notifications: $e', isError: true);
      return false;
    }
  }
}
