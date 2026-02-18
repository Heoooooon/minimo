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

enum RecordType {
  todo('할 일', 'todo'),
  activity('기록', 'activity'),
  diary('일기', 'diary');

  const RecordType(this.label, this.value);
  final String label;
  final String value;

  static RecordType fromValue(String? value) {
    if (value == null) return RecordType.todo;
    return RecordType.values.where((e) => e.value == value).firstOrNull ??
        RecordType.todo;
  }
}

class RecordData {
  RecordData({
    this.id,
    this.ownerId,
    this.aquariumId,
    this.creatureId,
    this.recordType = RecordType.todo,
    required this.date,
    this.tags = const [],
    this.content = '',
    this.isPublic = true,
    this.isCompleted = false,
    this.created,
    this.updated,
  });

  String? id;
  String? ownerId;
  String? aquariumId;
  String? creatureId;
  RecordType recordType;
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
      'creature': creatureId,
      'record_type': recordType.value,
      'date': date.toIso8601String(),
      'tags': tags.map((e) => e.value).toList(),
      'content': content,
      'is_public': isPublic,
      'is_completed': isCompleted,
    };
  }

  RecordData copyWith({
    String? id,
    String? ownerId,
    String? aquariumId,
    String? creatureId,
    RecordType? recordType,
    DateTime? date,
    List<RecordTag>? tags,
    String? content,
    bool? isPublic,
    bool? isCompleted,
    DateTime? created,
    DateTime? updated,
  }) {
    return RecordData(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      aquariumId: aquariumId ?? this.aquariumId,
      creatureId: creatureId ?? this.creatureId,
      recordType: recordType ?? this.recordType,
      date: date ?? this.date,
      tags: tags ?? this.tags,
      content: content ?? this.content,
      isPublic: isPublic ?? this.isPublic,
      isCompleted: isCompleted ?? this.isCompleted,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }

  factory RecordData.fromJson(Map<String, dynamic> json) {
    return RecordData(
      id: json['id'],
      ownerId: json['owner'],
      aquariumId: json['aquarium'],
      creatureId: json['creature'] is String && (json['creature'] as String).isNotEmpty
          ? json['creature']
          : null,
      recordType: RecordType.fromValue(json['record_type']),
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
