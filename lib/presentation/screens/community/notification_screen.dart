import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../domain/models/notification_data.dart';
import '../../../data/services/pb_notification_service.dart';
import '../../widgets/common/empty_state.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<NotificationData> _notifications = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreNotifications();
    }
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    final notifications = await PbNotificationService.instance.getNotifications(
      page: 1,
      perPage: 20,
    );

    setState(() {
      _notifications = notifications;
      _isLoading = false;
      _currentPage = 1;
      _hasMore = notifications.length >= 20;
    });
  }

  Future<void> _loadMoreNotifications() async {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    final notifications = await PbNotificationService.instance.getNotifications(
      page: _currentPage + 1,
      perPage: 20,
    );

    setState(() {
      _notifications.addAll(notifications);
      _currentPage++;
      _isLoadingMore = false;
      _hasMore = notifications.length >= 20;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
          ? _buildEmptyState()
          : _buildNotificationList(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.backgroundSurface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        '알림',
        style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textMain),
      ),
      actions: [
        if (_notifications.isNotEmpty)
          TextButton(
            onPressed: _markAllAsRead,
            child: Text(
              '모두 읽음',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.brand),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return EmptyStatePresets.noNotifications;
  }

  Widget _buildNotificationList() {
    final today = DateTime.now();
    final todayNotifications = _notifications
        .where((n) => n.created != null && _isSameDay(n.created!, today))
        .toList();
    final yesterdayNotifications = _notifications
        .where(
          (n) =>
              n.created != null &&
              _isSameDay(n.created!, today.subtract(const Duration(days: 1))),
        )
        .toList();
    final olderNotifications = _notifications
        .where(
          (n) =>
              n.created == null ||
              (!_isSameDay(n.created!, today) &&
                  !_isSameDay(
                    n.created!,
                    today.subtract(const Duration(days: 1)),
                  )),
        )
        .toList();

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          if (todayNotifications.isNotEmpty) ...[
            _buildSectionHeader('오늘'),
            ...todayNotifications.map(_buildNotificationItem),
          ],
          if (yesterdayNotifications.isNotEmpty) ...[
            _buildSectionHeader('어제'),
            ...yesterdayNotifications.map(_buildNotificationItem),
          ],
          if (olderNotifications.isNotEmpty) ...[
            _buildSectionHeader('이전'),
            ...olderNotifications.map(_buildNotificationItem),
          ],
          if (_isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: AppTextStyles.captionMedium.copyWith(
          color: AppColors.textSubtle,
        ),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationData notification) {
    return Dismissible(
      key: Key(notification.id ?? ''),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => _deleteNotification(notification),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: () => _onNotificationTap(notification),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: notification.isRead
              ? AppColors.backgroundApp
              : AppColors.backgroundSurface,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getNotificationColor(
                    notification.type,
                  ).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getNotificationIcon(notification.type),
                  size: 20,
                  color: _getNotificationColor(notification.type),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          notification.title,
                          style: AppTextStyles.titleSmall.copyWith(
                            color: AppColors.textMain,
                            fontWeight: notification.isRead
                                ? FontWeight.w500
                                : FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          notification.timeAgo,
                          style: AppTextStyles.captionRegular.copyWith(
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: notification.isRead
                            ? AppColors.textSubtle
                            : AppColors.textMain,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!notification.isRead) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.brand,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.like:
        return Icons.favorite;
      case NotificationType.comment:
        return Icons.chat_bubble;
      case NotificationType.follow:
        return Icons.person_add;
      case NotificationType.answer:
        return Icons.question_answer;
      case NotificationType.mention:
        return Icons.alternate_email;
      case NotificationType.system:
        return Icons.info;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.like:
        return AppColors.error;
      case NotificationType.comment:
        return AppColors.brand;
      case NotificationType.follow:
        return AppColors.success;
      case NotificationType.answer:
        return AppColors.secondary;
      case NotificationType.mention:
        return AppColors.brand;
      case NotificationType.system:
        return AppColors.textSubtle;
    }
  }

  Future<void> _onNotificationTap(NotificationData notification) async {
    if (!notification.isRead && notification.id != null) {
      await PbNotificationService.instance.markAsRead(notification.id!);
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = notification.copyWith(isRead: true);
        }
      });
    }

    if (!mounted) return;

    switch (notification.type) {
      case NotificationType.like:
      case NotificationType.comment:
        if (notification.targetId != null) {
          Navigator.pushNamed(
            context,
            '/post-detail',
            arguments: notification.targetId,
          );
        }
        break;
      case NotificationType.answer:
        if (notification.targetId != null) {
          Navigator.pushNamed(
            context,
            '/question-detail',
            arguments: notification.targetId,
          );
        }
        break;
      case NotificationType.follow:
      case NotificationType.mention:
      case NotificationType.system:
        break;
    }
  }

  Future<void> _markAllAsRead() async {
    final success = await PbNotificationService.instance.markAllAsRead();
    if (success) {
      setState(() {
        _notifications = _notifications
            .map((n) => n.copyWith(isRead: true))
            .toList();
      });
    }
  }

  Future<void> _deleteNotification(NotificationData notification) async {
    final deletedIndex = _notifications.indexOf(notification);
    setState(() {
      _notifications.removeWhere((n) => n.id == notification.id);
    });

    final success = await PbNotificationService.instance.deleteNotification(
      notification.id!,
    );

    if (!success && mounted) {
      setState(() {
        _notifications.insert(deletedIndex, notification);
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '알림이 삭제되었습니다' : '삭제에 실패했습니다'),
          action: success
              ? SnackBarAction(
                  label: '취소',
                  onPressed: () async {
                    await _loadNotifications();
                  },
                )
              : null,
        ),
      );
    }
  }
}
