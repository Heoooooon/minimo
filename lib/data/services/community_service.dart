import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:http/http.dart' as http;
import 'pocketbase_service.dart';
import '../../domain/models/question_data.dart';
import '../../presentation/widgets/home/community_card.dart';

/// 커뮤니티 서비스
///
/// PocketBase questions, community_posts 컬렉션과 통신
class CommunityService {
  CommunityService._();

  static CommunityService? _instance;
  static CommunityService get instance => _instance ??= CommunityService._();

  PocketBase get _pb => PocketBaseService.instance.client;

  static const String _questionsCollection = 'questions';
  static const String _postsCollection = 'community_posts';

  // ==================== Questions (Q&A) ====================

  /// 질문 목록 조회
  Future<List<QuestionData>> getQuestions({
    int page = 1,
    int perPage = 20,
    String? filter,
    String? sort,
  }) async {
    try {
      final result = await _pb.collection(_questionsCollection).getList(
        page: page,
        perPage: perPage,
        filter: filter,
        sort: sort ?? '',
        expand: 'attached_records',
      );

      return result.items.map((record) => _recordToQuestionData(record)).toList();
    } catch (e) {
      debugPrint('Failed to get questions: $e');
      rethrow;
    }
  }

  /// 특정 질문 조회
  Future<QuestionData?> getQuestion(String id) async {
    try {
      final record = await _pb.collection(_questionsCollection).getOne(
        id,
        expand: 'attached_records',
      );
      return _recordToQuestionData(record);
    } catch (e) {
      debugPrint('Failed to get question: $e');
      return null;
    }
  }

  /// 질문 생성
  Future<QuestionData> createQuestion(QuestionData data) async {
    try {
      final body = data.toJson();

      final record = await _pb.collection(_questionsCollection).create(body: body);

      debugPrint('Question created: ${record.id}');
      return _recordToQuestionData(record);
    } catch (e) {
      debugPrint('Failed to create question: $e');
      rethrow;
    }
  }

  /// 질문 수정
  Future<QuestionData> updateQuestion(String id, QuestionData data) async {
    try {
      final body = data.toJson();

      final record = await _pb.collection(_questionsCollection).update(id, body: body);

      debugPrint('Question updated: ${record.id}');
      return _recordToQuestionData(record);
    } catch (e) {
      debugPrint('Failed to update question: $e');
      rethrow;
    }
  }

  /// 질문 삭제
  Future<void> deleteQuestion(String id) async {
    try {
      await _pb.collection(_questionsCollection).delete(id);
      debugPrint('Question deleted: $id');
    } catch (e) {
      debugPrint('Failed to delete question: $e');
      rethrow;
    }
  }

  /// 조회수 증가
  Future<void> incrementViewCount(String id) async {
    try {
      final record = await _pb.collection(_questionsCollection).getOne(id);
      final currentCount = record.getIntValue('view_count');
      await _pb.collection(_questionsCollection).update(id, body: {
        'view_count': currentCount + 1,
      });
    } catch (e) {
      debugPrint('Failed to increment view count: $e');
    }
  }

  // ==================== Community Posts ====================

  /// 커뮤니티 포스트 목록 조회
  Future<List<CommunityData>> getPosts({
    int page = 1,
    int perPage = 20,
    String? filter,
    String? sort,
  }) async {
    try {
      final result = await _pb.collection(_postsCollection).getList(
        page: page,
        perPage: perPage,
        filter: filter,
        sort: sort ?? '',
      );

      return result.items.map((record) => _recordToCommunityData(record)).toList();
    } catch (e) {
      debugPrint('Failed to get posts: $e');
      rethrow;
    }
  }

  /// 커뮤니티 포스트 생성
  Future<CommunityData> createPost({
    required String authorName,
    required String content,
    String? authorImagePath,
    String? imagePath,
  }) async {
    try {
      final body = <String, dynamic>{
        'author_name': authorName,
        'content': content,
        'like_count': 0,
        'comment_count': 0,
        'bookmark_count': 0,
      };

      final files = <http.MultipartFile>[];

      if (authorImagePath != null && authorImagePath.isNotEmpty) {
        files.add(await http.MultipartFile.fromPath('author_image', authorImagePath));
      }

      if (imagePath != null && imagePath.isNotEmpty) {
        files.add(await http.MultipartFile.fromPath('image', imagePath));
      }

      RecordModel record;
      if (files.isNotEmpty) {
        record = await _pb.collection(_postsCollection).create(
          body: body,
          files: files,
        );
      } else {
        record = await _pb.collection(_postsCollection).create(body: body);
      }

      debugPrint('Post created: ${record.id}');
      return _recordToCommunityData(record);
    } catch (e) {
      debugPrint('Failed to create post: $e');
      rethrow;
    }
  }

  /// 좋아요 토글
  Future<void> toggleLike(String id, bool isLiked) async {
    try {
      final record = await _pb.collection(_postsCollection).getOne(id);
      final currentCount = record.getIntValue('like_count');
      await _pb.collection(_postsCollection).update(id, body: {
        'like_count': isLiked ? currentCount + 1 : (currentCount > 0 ? currentCount - 1 : 0),
      });
    } catch (e) {
      debugPrint('Failed to toggle like: $e');
    }
  }

  /// 북마크 토글
  Future<void> toggleBookmark(String id, bool isBookmarked) async {
    try {
      final record = await _pb.collection(_postsCollection).getOne(id);
      final currentCount = record.getIntValue('bookmark_count');
      await _pb.collection(_postsCollection).update(id, body: {
        'bookmark_count': isBookmarked ? currentCount + 1 : (currentCount > 0 ? currentCount - 1 : 0),
      });
    } catch (e) {
      debugPrint('Failed to toggle bookmark: $e');
    }
  }

  // ==================== Helpers ====================

  /// RecordModel을 QuestionData로 변환
  QuestionData _recordToQuestionData(RecordModel record) {
    return QuestionData.fromJson({
      'id': record.id,
      'title': record.getStringValue('title'),
      'content': record.getStringValue('content'),
      'category': record.getStringValue('category'),
      'attached_records': record.data['attached_records'] ?? [],
      'view_count': record.getIntValue('view_count'),
      'comment_count': record.getIntValue('comment_count'),
      'created': record.getStringValue('created'),
      'updated': record.getStringValue('updated'),
      'expand': record.data['expand'],
    });
  }

  /// RecordModel을 CommunityData로 변환
  CommunityData _recordToCommunityData(RecordModel record) {
    // 작성 시간 계산
    final created = DateTime.tryParse(record.getStringValue('created'));
    String timeAgo = '방금 전';
    if (created != null) {
      final diff = DateTime.now().difference(created);
      if (diff.inDays > 0) {
        timeAgo = '${diff.inDays}일 전';
      } else if (diff.inHours > 0) {
        timeAgo = '${diff.inHours}시간 전';
      } else if (diff.inMinutes > 0) {
        timeAgo = '${diff.inMinutes}분 전';
      }
    }

    // 이미지 URL 가져오기
    String? imageUrl;
    final image = record.getStringValue('image');
    if (image.isNotEmpty) {
      imageUrl = _pb.files.getUrl(record, image).toString();
    }

    String? authorImageUrl;
    final authorImage = record.getStringValue('author_image');
    if (authorImage.isNotEmpty) {
      authorImageUrl = _pb.files.getUrl(record, authorImage).toString();
    }

    return CommunityData(
      id: record.id,
      authorName: record.getStringValue('author_name'),
      authorImageUrl: authorImageUrl,
      timeAgo: timeAgo,
      content: record.getStringValue('content'),
      imageUrl: imageUrl,
      likeCount: record.getIntValue('like_count'),
      commentCount: record.getIntValue('comment_count'),
      bookmarkCount: record.getIntValue('bookmark_count'),
    );
  }
}
