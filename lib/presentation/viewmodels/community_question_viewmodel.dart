import 'package:flutter/foundation.dart';
import '../../data/repositories/community_repository.dart';
import '../../data/repositories/record_repository.dart';
import '../../domain/models/question_data.dart';
import '../../domain/models/record_data.dart';

class CommunityQuestionViewModel extends ChangeNotifier {
  // PocketBase Repository 사용
  final CommunityRepository _communityRepository = PocketBaseCommunityRepository.instance;
  final RecordRepository _recordRepository = PocketBaseRecordRepository.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// 내 기록 목록
  List<RecordData> _myRecords = [];
  List<RecordData> get myRecords => _myRecords;

  /// 초기화: 내 기록 불러오기
  Future<void> loadMyRecords() async {
    try {
      _isLoading = true;
      notifyListeners();

      _myRecords = await _recordRepository.getRecords();
    } catch (e) {
      debugPrint('Error loading my records: $e');
      // 기록 불러오기 실패는 치명적이지 않으므로 에러 메시지 설정 안 함 (조용히 실패)
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 질문 등록
  Future<bool> submitQuestion({
    required String title,
    required String content,
    required String category,
    List<RecordData> attachedRecords = const [],
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final question = QuestionData(
        title: title,
        content: content,
        category: category,
      )..attachedRecordIds = attachedRecords.map((r) => r.id!).toList();

      await _communityRepository.createQuestion(question);
      return true;
    } catch (e) {
      debugPrint('Error submitting question: $e');
      _errorMessage = '질문 등록 중 오류가 발생했습니다.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
