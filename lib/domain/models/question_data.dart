import 'record_data.dart';

class QuestionData {
  QuestionData({
    this.id,
    this.ownerId,
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
  String? ownerId;
  String title;
  String content;
  String category;
  List<RecordData> attachedRecords;
  List<String> attachedRecordIds = [];
  int viewCount;
  int commentCount;
  DateTime? created;
  DateTime? updated;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'category': category,
      'attached_records': attachedRecordIds,
    };
  }

  factory QuestionData.fromJson(Map<String, dynamic> json) {
    return QuestionData(
        id: json['id'],
        ownerId: json['owner'],
        title: json['title'] ?? '',
        content: json['content'] ?? '',
        category: json['category'] ?? '',
        attachedRecords:
            (json['expand']?['attached_records'] as List<dynamic>?)
                ?.map((e) => RecordData.fromJson(e))
                .toList() ??
            [],
        viewCount: json['view_count'] ?? 0,
        commentCount: json['comment_count'] ?? 0,
        created: DateTime.tryParse(json['created'] ?? ''),
        updated: DateTime.tryParse(json['updated'] ?? ''),
      )
      ..attachedRecordIds =
          (json['attached_records'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
  }
}
