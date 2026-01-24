import 'package:pocketbase/pocketbase.dart';

enum NotificationType {
  like,
  comment,
  follow,
  answer,
  mention,
  system;

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NotificationType.system,
    );
  }
}

enum NotificationTargetType {
  post,
  question,
  user,
  comment,
  answer;

  static NotificationTargetType? fromString(String? value) {
    if (value == null) return null;
    return NotificationTargetType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NotificationTargetType.post,
    );
  }
}

class NotificationData {
  NotificationData({
    this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.targetId,
    this.targetType,
    this.isRead = false,
    this.actorId,
    this.actorName,
    this.actorAvatar,
    this.created,
  });

  String? id;
  String userId;
  NotificationType type;
  String title;
  String message;
  String? targetId;
  NotificationTargetType? targetType;
  bool isRead;
  String? actorId;
  String? actorName;
  String? actorAvatar;
  DateTime? created;

  factory NotificationData.fromRecord(RecordModel record) {
    final actorRecord = record.get<RecordModel?>('expand.actor');

    return NotificationData(
      id: record.id,
      userId: record.getStringValue('user'),
      type: NotificationType.fromString(record.getStringValue('type')),
      title: record.getStringValue('title'),
      message: record.getStringValue('message'),
      targetId: record.getStringValue('target_id'),
      targetType: NotificationTargetType.fromString(
        record.getStringValue('target_type'),
      ),
      isRead: record.getBoolValue('is_read'),
      actorId: actorRecord?.id,
      actorName: actorRecord?.getStringValue('name'),
      actorAvatar: actorRecord?.getStringValue('avatar'),
      created: DateTime.tryParse(record.getStringValue('created')),
    );
  }

  factory NotificationData.fromJson(Map<String, dynamic> json) {
    return NotificationData(
      id: json['id'],
      userId: json['user'] ?? '',
      type: NotificationType.fromString(json['type'] ?? 'system'),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      targetId: json['target_id'],
      targetType: NotificationTargetType.fromString(json['target_type']),
      isRead: json['is_read'] ?? false,
      actorId: json['actor'],
      created: DateTime.tryParse(json['created'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': userId,
      'type': type.name,
      'title': title,
      'message': message,
      'target_id': targetId,
      'target_type': targetType?.name,
      'is_read': isRead,
      'actor': actorId,
    };
  }

  String get timeAgo {
    if (created == null) return '방금 전';

    final diff = DateTime.now().difference(created!);
    if (diff.inDays > 0) {
      return '${diff.inDays}일 전';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}시간 전';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}분 전';
    }
    return '방금 전';
  }

  NotificationData copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    String? targetId,
    NotificationTargetType? targetType,
    bool? isRead,
    String? actorId,
    String? actorName,
    String? actorAvatar,
    DateTime? created,
  }) {
    return NotificationData(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      targetId: targetId ?? this.targetId,
      targetType: targetType ?? this.targetType,
      isRead: isRead ?? this.isRead,
      actorId: actorId ?? this.actorId,
      actorName: actorName ?? this.actorName,
      actorAvatar: actorAvatar ?? this.actorAvatar,
      created: created ?? this.created,
    );
  }
}
