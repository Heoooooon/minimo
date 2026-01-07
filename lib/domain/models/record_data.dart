

/// 기록 태그 타입
enum RecordTag {
  waterChange('물갈이', 'water_change'),
  cleaning('청소', 'cleaning'),
  feeding('먹이주기', 'feeding'),
  waterTest('수질검사', 'water_test'),
  fishAdded('물고기 추가', 'fish_added'),
  medication('치료/약품', 'medication'),
  maintenance('장비 관리', 'maintenance');

  const RecordTag(this.label, this.value);
  final String label;
  final String value;

  static RecordTag? fromValue(String? value) {
    if (value == null) return null;
    return RecordTag.values.where((e) => e.value == value).firstOrNull;
  }
}

/// 기록 데이터 모델
class RecordData {
  RecordData({
    this.id,
    this.aquariumId,
    required this.date,
    required this.tags,
    required this.content,
    this.isPublic = true,
    this.created,
    this.updated,
  });

  String? id;
  String? aquariumId; // 어떤 어항에 대한 기록인지 (Optional)
  DateTime date;
  List<RecordTag> tags;
  String content;
  bool isPublic;
  DateTime? created;
  DateTime? updated;

  /// PocketBase JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'aquarium': aquariumId,
      'date': date.toIso8601String(),
      'tags': tags.map((e) => e.value).toList(),
      'content': content,
      'is_public': isPublic,
    };
  }

  /// PocketBase JSON에서 생성
  factory RecordData.fromJson(Map<String, dynamic> json) {
    return RecordData(
      id: json['id'],
      aquariumId: json['aquarium'],
      date: DateTime.parse(json['date']),
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => RecordTag.fromValue(e.toString()))
              .whereType<RecordTag>()
              .toList() ??
          [],
      content: json['content'] ?? '',
      isPublic: json['is_public'] ?? true,
      created: DateTime.tryParse(json['created'] ?? ''),
      updated: DateTime.tryParse(json['updated'] ?? ''),
    );
  }
}
