import 'record_data.dart';

/// 질문 데이터 모델
class QuestionData {
  QuestionData({
    this.id,
    required this.title,
    required this.content,
    required this.category,
    this.attachedRecords = const [],
    this.viewCount = 0,
    this.commentCount = 0,
    this.created,
    this.updated,
  });

  String? id;
  String title;
  String content;
  String category;
  List<RecordData> attachedRecords; // Relation expansion
  List<String> attachedRecordIds = []; // For creating/updating
  int viewCount;
  int commentCount;
  DateTime? created;
  DateTime? updated;

  /// PocketBase JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'category': category,
      'attached_records': attachedRecordIds,
    };
  }

  /// PocketBase JSON에서 생성
  factory QuestionData.fromJson(Map<String, dynamic> json) {
    return QuestionData(
      id: json['id'],
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      category: json['category'] ?? '',
      attachedRecords: (json['expand']?['attached_records'] as List<dynamic>?)
              ?.map((e) => RecordData.fromJson(e))
              .toList() ??
          [],
      viewCount: json['view_count'] ?? 0,
      commentCount: json['comment_count'] ?? 0,
      created: DateTime.tryParse(json['created'] ?? ''),
      updated: DateTime.tryParse(json['updated'] ?? ''),
    )..attachedRecordIds = (json['attached_records'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
  }
}
