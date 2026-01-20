/// 답변 데이터 모델
class AnswerData {
  AnswerData({
    this.id,
    required this.questionId,
    this.authorId,
    required this.authorName,
    required this.content,
    this.isAccepted = false,
    this.likeCount = 0,
    this.created,
    this.updated,
  });

  String? id;
  String questionId;
  String? authorId;
  String authorName;
  String content;
  bool isAccepted;
  int likeCount;
  DateTime? created;
  DateTime? updated;

  /// PocketBase JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'question': questionId,
      'author': authorId,
      'author_name': authorName,
      'content': content,
      'is_accepted': isAccepted,
      'like_count': likeCount,
    };
  }

  /// PocketBase JSON에서 생성
  factory AnswerData.fromJson(Map<String, dynamic> json) {
    return AnswerData(
      id: json['id'],
      questionId: json['question'] ?? '',
      authorId: json['author'],
      authorName: json['author_name'] ?? '익명',
      content: json['content'] ?? '',
      isAccepted: json['is_accepted'] ?? false,
      likeCount: json['like_count'] ?? 0,
      created: DateTime.tryParse(json['created'] ?? ''),
      updated: DateTime.tryParse(json['updated'] ?? ''),
    );
  }

  /// 시간 포맷팅
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

  /// copyWith
  AnswerData copyWith({
    String? id,
    String? questionId,
    String? authorId,
    String? authorName,
    String? content,
    bool? isAccepted,
    int? likeCount,
    DateTime? created,
    DateTime? updated,
  }) {
    return AnswerData(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      content: content ?? this.content,
      isAccepted: isAccepted ?? this.isAccepted,
      likeCount: likeCount ?? this.likeCount,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }
}
