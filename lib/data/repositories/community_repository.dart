import '../../domain/models/question_data.dart';
import '../services/community_service.dart';

/// 커뮤니티 Repository 인터페이스
abstract class CommunityRepository {
  Future<List<QuestionData>> getQuestions({
    int page = 1,
    int perPage = 20,
    String? filter,
    String sort = '-created',
  });
  Future<QuestionData> createQuestion(QuestionData data);
}

/// PocketBase 커뮤니티 Repository
///
/// 실제 PocketBase 백엔드와 통신
class PocketBaseCommunityRepository implements CommunityRepository {
  PocketBaseCommunityRepository._();

  static PocketBaseCommunityRepository? _instance;
  static PocketBaseCommunityRepository get instance =>
      _instance ??= PocketBaseCommunityRepository._();

  final CommunityService _service = CommunityService.instance;

  @override
  Future<List<QuestionData>> getQuestions({
    int page = 1,
    int perPage = 20,
    String? filter,
    String sort = '-created',
  }) async {
    return _service.getQuestions(
      page: page,
      perPage: perPage,
      filter: filter,
      sort: sort,
    );
  }

  @override
  Future<QuestionData> createQuestion(QuestionData data) async {
    return _service.createQuestion(data);
  }
}
