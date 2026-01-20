import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'pocketbase_service.dart';
import '../../domain/models/comment_data.dart';

/// 댓글 서비스
///
/// PocketBase comments 컬렉션과 통신
class CommentService {
  CommentService._();

  static CommentService? _instance;
  static CommentService get instance => _instance ??= CommentService._();

  PocketBase get _pb => PocketBaseService.instance.client;

  static const String _collection = 'comments';

  /// 게시글에 대한 댓글 목록 조회
  Future<List<CommentData>> getComments({
    required String postId,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      final result = await _pb.collection(_collection).getList(
        page: page,
        perPage: perPage,
        filter: 'post = "$postId"',
        expand: 'author',
      );

      final comments = result.items.map((record) => _recordToCommentData(record)).toList();

      // 대댓글 구조화
      return _organizeComments(comments);
    } catch (e) {
      debugPrint('Failed to get comments: $e');
      rethrow;
    }
  }

  /// 특정 댓글 조회
  Future<CommentData?> getComment(String id) async {
    try {
      final record = await _pb.collection(_collection).getOne(
        id,
        expand: 'author',
      );
      return _recordToCommentData(record);
    } catch (e) {
      debugPrint('Failed to get comment: $e');
      return null;
    }
  }

  /// 댓글 생성
  Future<CommentData> createComment(CommentData data) async {
    try {
      final body = data.toJson();

      final record = await _pb.collection(_collection).create(body: body);

      // 게시글의 comment_count 증가
      await _incrementPostCommentCount(data.postId);

      debugPrint('Comment created: ${record.id}');
      return _recordToCommentData(record);
    } catch (e) {
      debugPrint('Failed to create comment: $e');
      rethrow;
    }
  }

  /// 댓글 수정
  Future<CommentData> updateComment(String id, CommentData data) async {
    try {
      final body = {
        'content': data.content,
      };

      final record = await _pb.collection(_collection).update(id, body: body);

      debugPrint('Comment updated: ${record.id}');
      return _recordToCommentData(record);
    } catch (e) {
      debugPrint('Failed to update comment: $e');
      rethrow;
    }
  }

  /// 댓글 삭제
  Future<void> deleteComment(String id, String postId) async {
    try {
      await _pb.collection(_collection).delete(id);

      // 게시글의 comment_count 감소
      await _decrementPostCommentCount(postId);

      debugPrint('Comment deleted: $id');
    } catch (e) {
      debugPrint('Failed to delete comment: $e');
      rethrow;
    }
  }

  /// 좋아요 토글
  Future<void> toggleLike(String id, bool isLiked) async {
    try {
      final record = await _pb.collection(_collection).getOne(id);
      final currentCount = record.getIntValue('like_count');
      await _pb.collection(_collection).update(id, body: {
        'like_count': isLiked ? currentCount + 1 : (currentCount > 0 ? currentCount - 1 : 0),
      });
    } catch (e) {
      debugPrint('Failed to toggle like: $e');
    }
  }

  // ==================== Helpers ====================

  /// 게시글의 comment_count 증가
  Future<void> _incrementPostCommentCount(String postId) async {
    try {
      final record = await _pb.collection('community_posts').getOne(postId);
      final currentCount = record.getIntValue('comment_count');
      await _pb.collection('community_posts').update(postId, body: {
        'comment_count': currentCount + 1,
      });
    } catch (e) {
      debugPrint('Failed to increment post comment count: $e');
    }
  }

  /// 게시글의 comment_count 감소
  Future<void> _decrementPostCommentCount(String postId) async {
    try {
      final record = await _pb.collection('community_posts').getOne(postId);
      final currentCount = record.getIntValue('comment_count');
      await _pb.collection('community_posts').update(postId, body: {
        'comment_count': currentCount > 0 ? currentCount - 1 : 0,
      });
    } catch (e) {
      debugPrint('Failed to decrement post comment count: $e');
    }
  }

  /// 댓글 목록을 부모-자식 구조로 정리
  List<CommentData> _organizeComments(List<CommentData> comments) {
    final Map<String, CommentData> commentMap = {};
    final List<CommentData> rootComments = [];

    // 먼저 모든 댓글을 맵에 등록
    for (final comment in comments) {
      if (comment.id != null) {
        commentMap[comment.id!] = comment;
      }
    }

    // 부모-자식 관계 설정
    for (final comment in comments) {
      if (comment.parentCommentId != null && commentMap.containsKey(comment.parentCommentId)) {
        // 대댓글
        final parent = commentMap[comment.parentCommentId]!;
        final updatedReplies = List<CommentData>.from(parent.replies)..add(comment);
        commentMap[comment.parentCommentId!] = parent.copyWith(replies: updatedReplies);
      } else {
        // 루트 댓글
        rootComments.add(comment);
      }
    }

    // 루트 댓글에 대댓글 연결
    return rootComments.map((comment) {
      if (comment.id != null && commentMap.containsKey(comment.id)) {
        return commentMap[comment.id!]!;
      }
      return comment;
    }).toList();
  }

  /// RecordModel을 CommentData로 변환
  CommentData _recordToCommentData(RecordModel record) {
    return CommentData.fromJson({
      'id': record.id,
      'post': record.getStringValue('post'),
      'author': record.data['author'],
      'author_name': record.getStringValue('author_name'),
      'content': record.getStringValue('content'),
      'like_count': record.getIntValue('like_count'),
      'parent_comment': record.data['parent_comment'],
      'created': record.getStringValue('created'),
      'updated': record.getStringValue('updated'),
    });
  }
}
