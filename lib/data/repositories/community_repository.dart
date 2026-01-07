import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import '../../domain/models/question_data.dart';
import '../services/pocketbase_service.dart';

/// 커뮤니티 Repository
class CommunityRepository {
  CommunityRepository._();

  static CommunityRepository? _instance;
  static CommunityRepository get instance =>
      _instance ??= CommunityRepository._();

  static const String _collectionName = 'questions';

  PocketBase get _pb => PocketBaseService.instance.client;

  /// 질문 목록 조회
  Future<List<QuestionData>> getQuestions({
    int page = 1,
    int perPage = 20,
    String? filter,
    String sort = '-created',
  }) async {
    try {
      final result = await _pb.collection(_collectionName).getList(
            page: page,
            perPage: perPage,
            filter: filter,
            sort: sort,
            expand: 'attached_records',
          );

      return result.items
          .map((record) => QuestionData.fromJson(record.toJson()))
          .toList();
    } catch (e) {
      debugPrint('Error fetching questions: $e');
      rethrow;
    }
  }

  /// 질문 생성
  Future<QuestionData> createQuestion(QuestionData data) async {
    try {
      final record = await _pb
          .collection(_collectionName)
          .create(body: data.toJson());
      // 생성 후 expand된 데이터를 받으려면 다시 조회하거나 클라이언트에서 처리해야 하지만,
      // 여기서는 생성된 레코드만 반환
      return QuestionData.fromJson(record.toJson());
    } catch (e) {
      debugPrint('Error creating question: $e');
      rethrow;
    }
  }
}
