/// 댓글 데이터 모델
class CommentData {
  CommentData({
    this.id,
    required this.postId,
    this.authorId,
    required this.authorName,
    required this.content,
    this.likeCount = 0,
    this.parentCommentId,
    this.replies = const [],
    this.created,
    this.updated,
  });

  String? id;
  String postId;
  String? authorId;
  String authorName;
  String content;
  int likeCount;
  String? parentCommentId;
  List<CommentData> replies;
  DateTime? created;
  DateTime? updated;

  /// PocketBase JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'post': postId,
      'author': authorId,
      'author_name': authorName,
      'content': content,
      'like_count': likeCount,
      'parent_comment': parentCommentId,
    };
  }

  /// PocketBase JSON에서 생성
  factory CommentData.fromJson(Map<String, dynamic> json) {
    return CommentData(
      id: json['id'],
      postId: json['post'] ?? '',
      authorId: json['author'],
      authorName: json['author_name'] ?? '익명',
      content: json['content'] ?? '',
      likeCount: json['like_count'] ?? 0,
      parentCommentId: json['parent_comment'],
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
  CommentData copyWith({
    String? id,
    String? postId,
    String? authorId,
    String? authorName,
    String? content,
    int? likeCount,
    String? parentCommentId,
    List<CommentData>? replies,
    DateTime? created,
    DateTime? updated,
  }) {
    return CommentData(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      content: content ?? this.content,
      likeCount: likeCount ?? this.likeCount,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      replies: replies ?? this.replies,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }
}
