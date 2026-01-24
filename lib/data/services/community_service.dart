import 'package:pocketbase/pocketbase.dart';
import 'package:http/http.dart' as http;
import 'pocketbase_service.dart';
import 'auth_service.dart';
import '../../domain/models/question_data.dart';
import '../../presentation/widgets/home/community_card.dart';
import '../../core/utils/app_logger.dart';

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
      final result = await _pb
          .collection(_questionsCollection)
          .getList(
            page: page,
            perPage: perPage,
            filter: filter ?? '',
            sort: sort ?? '',
            expand: 'attached_records',
          );

      return result.items
          .map((record) => _recordToQuestionData(record))
          .toList();
    } catch (e) {
      AppLogger.data('Failed to get questions: $e', isError: true);
      rethrow;
    }
  }

  /// 특정 질문 조회
  Future<QuestionData?> getQuestion(String id) async {
    try {
      final record = await _pb
          .collection(_questionsCollection)
          .getOne(id, expand: 'attached_records');
      return _recordToQuestionData(record);
    } catch (e) {
      AppLogger.data('Failed to get question: $e', isError: true);
      return null;
    }
  }

  Future<QuestionData> createQuestion(QuestionData data) async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) {
      throw Exception('로그인이 필요합니다.');
    }

    try {
      final body = data.toJson();
      body['owner'] = userId;

      final record = await _pb
          .collection(_questionsCollection)
          .create(body: body);

      AppLogger.data('Question created: ${record.id}');
      return _recordToQuestionData(record);
    } catch (e) {
      AppLogger.data('Failed to create question: $e', isError: true);
      rethrow;
    }
  }

  /// 질문 수정
  Future<QuestionData> updateQuestion(String id, QuestionData data) async {
    try {
      final body = data.toJson();

      final record = await _pb
          .collection(_questionsCollection)
          .update(id, body: body);

      AppLogger.data('Question updated: ${record.id}');
      return _recordToQuestionData(record);
    } catch (e) {
      AppLogger.data('Failed to update question: $e', isError: true);
      rethrow;
    }
  }

  /// 질문 삭제
  Future<void> deleteQuestion(String id) async {
    try {
      await _pb.collection(_questionsCollection).delete(id);
      AppLogger.data('Question deleted: $id');
    } catch (e) {
      AppLogger.data('Failed to delete question: $e', isError: true);
      rethrow;
    }
  }

  /// 조회수 증가
  Future<void> incrementViewCount(String id) async {
    try {
      final record = await _pb.collection(_questionsCollection).getOne(id);
      final currentCount = record.getIntValue('view_count');
      await _pb
          .collection(_questionsCollection)
          .update(id, body: {'view_count': currentCount + 1});
    } catch (e) {
      AppLogger.data('Failed to increment view count: $e', isError: true);
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
      final result = await _pb
          .collection(_postsCollection)
          .getList(
            page: page,
            perPage: perPage,
            filter: filter ?? '',
            sort: sort ?? '',
          );

      return result.items
          .map((record) => _recordToCommunityData(record))
          .toList();
    } catch (e) {
      AppLogger.data('Failed to get posts: $e', isError: true);
      rethrow;
    }
  }

  Future<CommunityData> createPost({
    required String authorId,
    required String authorName,
    required String content,
    String? authorImagePath,
    String? imagePath,
    List<String>? tags,
  }) async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) {
      throw Exception('로그인이 필요합니다.');
    }

    try {
      final body = <String, dynamic>{
        'owner': userId,
        'author_id': authorId,
        'author_name': authorName,
        'content': content,
        'like_count': 0,
        'comment_count': 0,
        'bookmark_count': 0,
      };

      if (tags != null && tags.isNotEmpty) {
        body['tags'] = tags;
      }

      final files = <http.MultipartFile>[];

      if (authorImagePath != null && authorImagePath.isNotEmpty) {
        files.add(
          await http.MultipartFile.fromPath('author_image', authorImagePath),
        );
      }

      if (imagePath != null && imagePath.isNotEmpty) {
        files.add(await http.MultipartFile.fromPath('image', imagePath));
      }

      RecordModel record;
      if (files.isNotEmpty) {
        record = await _pb
            .collection(_postsCollection)
            .create(body: body, files: files);
      } else {
        record = await _pb.collection(_postsCollection).create(body: body);
      }

      AppLogger.data('Post created: ${record.id}');
      return _recordToCommunityData(record);
    } catch (e) {
      AppLogger.data('Failed to create post: $e', isError: true);
      rethrow;
    }
  }

  /// 커뮤니티 포스트 수정
  Future<CommunityData> updatePost({
    required String id,
    String? content,
    String? imagePath,
    bool removeImage = false,
  }) async {
    try {
      final body = <String, dynamic>{};

      if (content != null) {
        body['content'] = content;
      }

      if (removeImage) {
        body['image'] = null;
      }

      final files = <http.MultipartFile>[];

      if (imagePath != null && imagePath.isNotEmpty) {
        files.add(await http.MultipartFile.fromPath('image', imagePath));
      }

      RecordModel record;
      if (files.isNotEmpty) {
        record = await _pb
            .collection(_postsCollection)
            .update(id, body: body, files: files);
      } else {
        record = await _pb.collection(_postsCollection).update(id, body: body);
      }

      AppLogger.data('Post updated: ${record.id}');
      return _recordToCommunityData(record);
    } catch (e) {
      AppLogger.data('Failed to update post: $e', isError: true);
      rethrow;
    }
  }

  /// 커뮤니티 포스트 삭제
  Future<void> deletePost(String id) async {
    try {
      await _pb.collection(_postsCollection).delete(id);
      AppLogger.data('Post deleted: $id');
    } catch (e) {
      AppLogger.data('Failed to delete post: $e', isError: true);
      rethrow;
    }
  }

  /// 특정 포스트 조회
  Future<CommunityData?> getPost(String id) async {
    try {
      final record = await _pb.collection(_postsCollection).getOne(id);
      return _recordToCommunityData(record);
    } catch (e) {
      AppLogger.data('Failed to get post: $e', isError: true);
      return null;
    }
  }

  /// 좋아요 토글
  Future<void> toggleLike(String id, bool isLiked) async {
    try {
      final record = await _pb.collection(_postsCollection).getOne(id);
      final currentCount = record.getIntValue('like_count');
      await _pb
          .collection(_postsCollection)
          .update(
            id,
            body: {
              'like_count': isLiked
                  ? currentCount + 1
                  : (currentCount > 0 ? currentCount - 1 : 0),
            },
          );
    } catch (e) {
      AppLogger.data('Failed to toggle like: $e', isError: true);
    }
  }

  /// 북마크 토글
  Future<void> toggleBookmark(String id, bool isBookmarked) async {
    try {
      final record = await _pb.collection(_postsCollection).getOne(id);
      final currentCount = record.getIntValue('bookmark_count');
      await _pb
          .collection(_postsCollection)
          .update(
            id,
            body: {
              'bookmark_count': isBookmarked
                  ? currentCount + 1
                  : (currentCount > 0 ? currentCount - 1 : 0),
            },
          );
    } catch (e) {
      AppLogger.data('Failed to toggle bookmark: $e', isError: true);
    }
  }

  // ==================== Helpers ====================

  QuestionData _recordToQuestionData(RecordModel record) {
    return QuestionData.fromJson({
      'id': record.id,
      'owner': record.getStringValue('owner'),
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

    // 태그 파싱
    List<String> tags = [];
    final tagsData = record.data['tags'];
    if (tagsData != null) {
      if (tagsData is List) {
        tags = tagsData.map((e) => e.toString()).toList();
      } else if (tagsData is String && tagsData.isNotEmpty) {
        // JSON 문자열인 경우
        tags = [tagsData];
      }
    }

    return CommunityData(
      id: record.id,
      authorId: record.getStringValue('author_id'),
      authorName: record.getStringValue('author_name'),
      authorImageUrl: authorImageUrl,
      timeAgo: timeAgo,
      content: record.getStringValue('content'),
      imageUrl: imageUrl,
      tags: tags,
      likeCount: record.getIntValue('like_count'),
      commentCount: record.getIntValue('comment_count'),
      bookmarkCount: record.getIntValue('bookmark_count'),
    );
  }
}
