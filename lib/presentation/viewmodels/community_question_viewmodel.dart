import '../../core/utils/app_logger.dart';
import '../../data/repositories/community_repository.dart';
import '../../data/repositories/record_repository.dart';
import '../../domain/models/question_data.dart';
import '../../domain/models/record_data.dart';
import 'base_viewmodel.dart';

class CommunityQuestionViewModel extends BaseViewModel {
  // PocketBase Repository 사용
  final CommunityRepository _communityRepository =
      PocketBaseCommunityRepository.instance;
  final RecordRepository _recordRepository =
      PocketBaseRecordRepository.instance;

  /// 내 기록 목록
  List<RecordData> _myRecords = [];
  List<RecordData> get myRecords => _myRecords;

  /// 초기화: 내 기록 불러오기
  Future<void> loadMyRecords() async {
    setLoading(true);
    try {
      _myRecords = await _recordRepository.getRecords();
    } catch (e) {
      AppLogger.data('Error loading my records: $e', isError: true);
      // 기록 불러오기 실패는 치명적이지 않으므로 에러 메시지 설정 안 함 (조용히 실패)
    } finally {
      setLoading(false);
    }
  }

  /// 질문 등록
  Future<bool> submitQuestion({
    required String title,
    required String content,
    required String category,
    List<RecordData> attachedRecords = const [],
  }) async {
    return await runAsyncBool(() async {
      final question = QuestionData(
        title: title,
        content: content,
        category: category,
      )..attachedRecordIds = attachedRecords.map((r) => r.id!).toList();

      await _communityRepository.createQuestion(question);
    }, errorPrefix: '질문 등록 중 오류가 발생했습니다');
  }
}
