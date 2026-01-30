enum RecordTag {
  temperatureCheck('온도 체크', 'temperature_check'),
  plantCare('수초 관리', 'plant_care'),
  maintenance('장비 관리', 'maintenance'),
  waterChange('물갈이', 'water_change'),
  feeding('먹이주기', 'feeding'),
  cleaning('어항 청소', 'cleaning'),
  waterTest('수질 체크', 'water_test'),
  fishAdded('물고기 추가', 'fish_added'),
  medication('치료/약품', 'medication');

  const RecordTag(this.label, this.value);
  final String label;
  final String value;

  static RecordTag? fromValue(String? value) {
    if (value == null) return null;
    return RecordTag.values.where((e) => e.value == value).firstOrNull;
  }

  static List<RecordTag> get activityTags => [
    temperatureCheck,
    plantCare,
    maintenance,
    waterChange,
    feeding,
    cleaning,
    waterTest,
  ];
}

class RecordData {
  RecordData({
    this.id,
    this.ownerId,
    this.aquariumId,
    required this.date,
    required this.tags,
    required this.content,
    this.isPublic = true,
    this.isCompleted = false,
    this.created,
    this.updated,
  });

  String? id;
  String? ownerId;
  String? aquariumId;
  DateTime date;
  List<RecordTag> tags;
  String content;
  bool isPublic;
  bool isCompleted;
  DateTime? created;
  DateTime? updated;

  Map<String, dynamic> toJson() {
    return {
      'aquarium': aquariumId,
      'date': date.toIso8601String(),
      'tags': tags.map((e) => e.value).toList(),
      'content': content,
      'is_public': isPublic,
      'is_completed': isCompleted,
    };
  }

  factory RecordData.fromJson(Map<String, dynamic> json) {
    return RecordData(
      id: json['id'],
      ownerId: json['owner'],
      aquariumId: json['aquarium'],
      date: DateTime.parse(json['date']),
      tags:
          (json['tags'] as List<dynamic>?)
              ?.map((e) => RecordTag.fromValue(e.toString()))
              .whereType<RecordTag>()
              .toList() ??
          [],
      content: json['content'] ?? '',
      isPublic: json['is_public'] ?? true,
      isCompleted: json['is_completed'] ?? false,
      created: DateTime.tryParse(json['created'] ?? ''),
      updated: DateTime.tryParse(json['updated'] ?? ''),
    );
  }
}
