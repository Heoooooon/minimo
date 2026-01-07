/// 일정 데이터 모델
class ScheduleData {
  ScheduleData({
    required this.id,
    required this.time,
    required this.title,
    required this.aquariumName,
    this.aquariumId,
    this.isCompleted = false,
    required this.date,
  });

  final String id;
  final String time; // "08:00" 형식
  final String title;
  final String aquariumName;
  final String? aquariumId;
  final bool isCompleted;
  final DateTime date;

  ScheduleData copyWith({
    String? id,
    String? time,
    String? title,
    String? aquariumName,
    String? aquariumId,
    bool? isCompleted,
    DateTime? date,
  }) {
    return ScheduleData(
      id: id ?? this.id,
      time: time ?? this.time,
      title: title ?? this.title,
      aquariumName: aquariumName ?? this.aquariumName,
      aquariumId: aquariumId ?? this.aquariumId,
      isCompleted: isCompleted ?? this.isCompleted,
      date: date ?? this.date,
    );
  }

  // PocketBase 연동을 위한 준비 (현재는 Mock 데이터용으로만 사용될 수 있음)
  factory ScheduleData.fromJson(Map<String, dynamic> json) {
    return ScheduleData(
      id: json['id'] ?? '',
      time: json['time'] ?? '',
      title: json['title'] ?? '',
      aquariumName: json['aquarium_name'] ?? '',
      aquariumId: json['aquarium_id'],
      isCompleted: json['is_completed'] ?? false,
      date: DateTime.parse(json['date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'time': time,
      'title': title,
      'aquarium_name': aquariumName,
      'aquarium_id': aquariumId,
      'is_completed': isCompleted,
      'date': date.toIso8601String(),
    };
  }
}
