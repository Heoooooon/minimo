import 'package:pocketbase/pocketbase.dart';
import 'pocketbase_service.dart';
import '../../domain/models/answer_data.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/pb_filter.dart';

/// 답변 서비스
///
/// PocketBase answers 컬렉션과 통신
class AnswerService {
  AnswerService._();

  static AnswerService? _instance;
  static AnswerService get instance => _instance ??= AnswerService._();

  PocketBase get _pb => PocketBaseService.instance.client;

  static const String _collection = 'answers';

  /// 질문에 대한 답변 목록 조회
  Future<List<AnswerData>> getAnswers({
    required String questionId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final result = await _pb
          .collection(_collection)
          .getList(
            page: page,
            perPage: perPage,
            filter: PbFilter.eq('question', questionId),
            expand: 'author',
          );

      return result.items.map((record) => _recordToAnswerData(record)).toList();
    } catch (e) {
      AppLogger.data('Failed to get answers: $e', isError: true);
      rethrow;
    }
  }

  /// 특정 답변 조회
  Future<AnswerData?> getAnswer(String id) async {
    try {
      final record = await _pb
          .collection(_collection)
          .getOne(id, expand: 'author');
      return _recordToAnswerData(record);
    } catch (e) {
      AppLogger.data('Failed to get answer: $e', isError: true);
      return null;
    }
  }

  /// 답변 생성
  Future<AnswerData> createAnswer(AnswerData data) async {
    try {
      final body = data.toJson();

      final record = await _pb.collection(_collection).create(body: body);

      // 질문의 comment_count 증가
      await _incrementQuestionCommentCount(data.questionId);

      AppLogger.data('Answer created: ${record.id}');
      return _recordToAnswerData(record);
    } catch (e) {
      AppLogger.data('Failed to create answer: $e', isError: true);
      rethrow;
    }
  }

  /// 답변 수정
  Future<AnswerData> updateAnswer(String id, AnswerData data) async {
    try {
      final body = data.toJson();

      final record = await _pb.collection(_collection).update(id, body: body);

      AppLogger.data('Answer updated: ${record.id}');
      return _recordToAnswerData(record);
    } catch (e) {
      AppLogger.data('Failed to update answer: $e', isError: true);
      rethrow;
    }
  }

  /// 답변 삭제
  Future<void> deleteAnswer(String id, String questionId) async {
    try {
      await _pb.collection(_collection).delete(id);

      // 질문의 comment_count 감소
      await _decrementQuestionCommentCount(questionId);

      AppLogger.data('Answer deleted: $id');
    } catch (e) {
      AppLogger.data('Failed to delete answer: $e', isError: true);
      rethrow;
    }
  }

  /// 답변 채택 (질문 작성자만 가능, 본인 답변 채택 불가)
  Future<void> acceptAnswer(String answerId) async {
    try {
      await _pb.send(
        '/api/community/accept-answer',
        method: 'POST',
        body: {'answer_id': answerId},
      );
      AppLogger.data('Answer accepted: $answerId');
    } catch (e) {
      AppLogger.data('Failed to accept answer: $e', isError: true);
      rethrow;
    }
  }

  Future<void> toggleLike(String answerId, bool isLiked) async {
    try {
      await _pb.send(
        '/api/community/toggle-like',
        method: 'POST',
        body: {'target_id': answerId, 'target_type': 'answer'},
      );
    } catch (e) {
      AppLogger.data('Failed to toggle like: $e', isError: true);
    }
  }

  // ==================== Helpers ====================

  Future<void> _incrementQuestionCommentCount(String questionId) async {
    try {
      await _pb.send(
        '/api/community/increment-comment-count',
        method: 'POST',
        body: {'id': questionId, 'type': 'question'},
      );
    } catch (e) {
      AppLogger.data(
        'Failed to increment question comment count: $e',
        isError: true,
      );
    }
  }

  Future<void> _decrementQuestionCommentCount(String questionId) async {
    try {
      await _pb.send(
        '/api/community/decrement-comment-count',
        method: 'POST',
        body: {'id': questionId, 'type': 'question'},
      );
    } catch (e) {
      AppLogger.data(
        'Failed to decrement question comment count: $e',
        isError: true,
      );
    }
  }

  /// RecordModel을 AnswerData로 변환
  AnswerData _recordToAnswerData(RecordModel record) {
    return AnswerData.fromJson({
      'id': record.id,
      'question': record.getStringValue('question'),
      'author': record.data['author'],
      'author_name': record.getStringValue('author_name'),
      'content': record.getStringValue('content'),
      'is_accepted': record.getBoolValue('is_accepted'),
      'like_count': record.getIntValue('like_count'),
      'created': record.getStringValue('created'),
      'updated': record.getStringValue('updated'),
    });
  }
}
