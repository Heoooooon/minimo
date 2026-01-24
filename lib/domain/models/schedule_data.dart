enum AlarmType {
  waterChange('water_change', '물갈이'),
  feeding('feeding', '먹이주기'),
  cleaning('cleaning', '청소'),
  waterTest('water_test', '수질검사'),
  medication('medication', '투약'),
  other('other', '기타');

  const AlarmType(this.value, this.label);
  final String value;
  final String label;

  static AlarmType fromValue(String? value) {
    if (value == null) return AlarmType.other;
    return AlarmType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AlarmType.other,
    );
  }
}

enum RepeatCycle {
  none('none', '반복 안함'),
  daily('daily', '매일'),
  everyOtherDay('every_other_day', '격일'),
  weekly('weekly', '매주'),
  biweekly('biweekly', '격주'),
  monthly('monthly', '매월');

  const RepeatCycle(this.value, this.label);
  final String value;
  final String label;

  static RepeatCycle fromValue(String? value) {
    if (value == null) return RepeatCycle.none;
    return RepeatCycle.values.firstWhere(
      (e) => e.value == value,
      orElse: () => RepeatCycle.none,
    );
  }
}

class ScheduleData {
  ScheduleData({
    required this.id,
    this.ownerId,
    required this.time,
    required this.title,
    required this.aquariumName,
    this.aquariumId,
    this.isCompleted = false,
    required this.date,
    this.alarmType = AlarmType.other,
    this.repeatCycle = RepeatCycle.none,
    this.isNotificationEnabled = false,
  });

  final String id;
  final String? ownerId;
  final String time;
  final String title;
  final String aquariumName;
  final String? aquariumId;
  final bool isCompleted;
  final DateTime date;
  final AlarmType alarmType;
  final RepeatCycle repeatCycle;
  final bool isNotificationEnabled;

  ScheduleData copyWith({
    String? id,
    String? ownerId,
    String? time,
    String? title,
    String? aquariumName,
    String? aquariumId,
    bool? isCompleted,
    DateTime? date,
    AlarmType? alarmType,
    RepeatCycle? repeatCycle,
    bool? isNotificationEnabled,
  }) {
    return ScheduleData(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      time: time ?? this.time,
      title: title ?? this.title,
      aquariumName: aquariumName ?? this.aquariumName,
      aquariumId: aquariumId ?? this.aquariumId,
      isCompleted: isCompleted ?? this.isCompleted,
      date: date ?? this.date,
      alarmType: alarmType ?? this.alarmType,
      repeatCycle: repeatCycle ?? this.repeatCycle,
      isNotificationEnabled:
          isNotificationEnabled ?? this.isNotificationEnabled,
    );
  }

  factory ScheduleData.fromJson(Map<String, dynamic> json) {
    return ScheduleData(
      id: json['id'] ?? '',
      ownerId: json['owner'],
      time: json['time'] ?? '',
      title: json['title'] ?? '',
      aquariumName: json['aquarium_name'] ?? '',
      aquariumId: json['aquarium'],
      isCompleted: json['is_completed'] ?? false,
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      alarmType: AlarmType.fromValue(json['alarm_type']),
      repeatCycle: RepeatCycle.fromValue(json['repeat_cycle']),
      isNotificationEnabled: json['is_notification_enabled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'title': title,
      'aquarium_name': aquariumName,
      'aquarium': aquariumId,
      'is_completed': isCompleted,
      'date': date.toIso8601String(),
      'alarm_type': alarmType.value,
      'repeat_cycle': repeatCycle.value,
      'is_notification_enabled': isNotificationEnabled,
    };
  }
}
