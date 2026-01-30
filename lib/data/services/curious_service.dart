import 'package:pocketbase/pocketbase.dart';
import 'pocketbase_service.dart';
import '../../core/utils/app_logger.dart';

/// 궁금해요 데이터 모델
class CuriousData {
  CuriousData({
    this.id,
    required this.userId,
    required this.questionId,
    this.created,
  });

  String? id;
  String userId;
  String questionId;
  DateTime? created;

  factory CuriousData.fromJson(Map<String, dynamic> json) {
    return CuriousData(
      id: json['id'],
      userId: json['user_id'] ?? '',
      questionId: json['question_id'] ?? '',
      created: DateTime.tryParse(json['created'] ?? ''),
    );
  }
}

/// 궁금해요 서비스
///
/// PocketBase curious 컬렉션과 통신
/// 질문에 대한 "궁금해요" 기능 관리
class CuriousService {
  CuriousService._();

  static CuriousService? _instance;
  static CuriousService get instance => _instance ??= CuriousService._();

  PocketBase get _pb => PocketBaseService.instance.client;

  static const String _collection = 'curious';

  /// 궁금해요 토글
  Future<bool> toggleCurious({
    required String userId,
    required String questionId,
  }) async {
    try {
      final result = await _pb.send(
        '/api/community/toggle-curious',
        method: 'POST',
        body: {'question_id': questionId},
      );

      final curious =
          (result as Map<String, dynamic>)['curious'] as bool? ?? false;
      AppLogger.data(
        'Curious toggled: $userId -> $questionId (curious: $curious)',
      );
      return curious;
    } catch (e) {
      AppLogger.data('Failed to toggle curious: $e', isError: true);
      rethrow;
    }
  }

  /// 궁금해요 여부 확인
  Future<bool> isCurious({
    required String userId,
    required String questionId,
  }) async {
    try {
      final existing = await _getCuriousRecord(userId, questionId);
      return existing != null;
    } catch (e) {
      AppLogger.data('Failed to check curious status: $e', isError: true);
      return false;
    }
  }

  /// 질문의 궁금해요 수 조회
  Future<int> getCuriousCount(String questionId) async {
    try {
      final result = await _pb
          .collection(_collection)
          .getList(page: 1, perPage: 1, filter: 'question_id = "$questionId"');
      return result.totalItems;
    } catch (e) {
      AppLogger.data('Failed to get curious count: $e', isError: true);
      return 0;
    }
  }

  /// 사용자가 궁금해요 한 질문 목록 조회
  Future<List<String>> getUserCuriousQuestions({
    required String userId,
    int page = 1,
    int perPage = 100,
  }) async {
    try {
      final result = await _pb
          .collection(_collection)
          .getList(
            page: page,
            perPage: perPage,
            filter: 'user_id = "$userId"',
            sort: '-created',
          );

      return result.items
          .map((record) => record.getStringValue('question_id'))
          .toList();
    } catch (e) {
      AppLogger.data('Failed to get user curious questions: $e', isError: true);
      return [];
    }
  }

  // ==================== Helpers ====================

  /// 궁금해요 레코드 조회
  Future<CuriousData?> _getCuriousRecord(
    String userId,
    String questionId,
  ) async {
    try {
      final result = await _pb
          .collection(_collection)
          .getList(
            page: 1,
            perPage: 1,
            filter: 'user_id = "$userId" && question_id = "$questionId"',
          );

      if (result.items.isNotEmpty) {
        final record = result.items.first;
        return CuriousData.fromJson({
          'id': record.id,
          'user_id': record.getStringValue('user_id'),
          'question_id': record.getStringValue('question_id'),
          'created': record.getStringValue('created'),
        });
      }
      return null;
    } catch (e) {
      AppLogger.data('Failed to get curious record: $e', isError: true);
      return null;
    }
  }
}
