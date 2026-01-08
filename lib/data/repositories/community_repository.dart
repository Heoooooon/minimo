import 'package:flutter/foundation.dart';
import '../../domain/models/question_data.dart';

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

/// Mock 커뮤니티 Repository
///
/// 백엔드 없이 로컬 메모리에서 동작
class MockCommunityRepository implements CommunityRepository {
  MockCommunityRepository._();

  static MockCommunityRepository? _instance;
  static MockCommunityRepository get instance =>
      _instance ??= MockCommunityRepository._();

  // 인메모리 저장소
  final List<QuestionData> _questions = [];
  int _idCounter = 1;

  @override
  Future<List<QuestionData>> getQuestions({
    int page = 1,
    int perPage = 20,
    String? filter,
    String sort = '-created',
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // 정렬 (최신순)
    final sorted = List<QuestionData>.from(_questions);
    if (sort.startsWith('-')) {
      sorted.sort((a, b) => (b.created ?? DateTime(0)).compareTo(a.created ?? DateTime(0)));
    } else {
      sorted.sort((a, b) => (a.created ?? DateTime(0)).compareTo(b.created ?? DateTime(0)));
    }

    // 페이지네이션
    final start = (page - 1) * perPage;
    final end = start + perPage;
    if (start >= sorted.length) return [];

    return sorted.sublist(start, end.clamp(0, sorted.length));
  }

  @override
  Future<QuestionData> createQuestion(QuestionData data) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final newQuestion = QuestionData(
      id: 'question_${_idCounter++}',
      title: data.title,
      content: data.content,
      category: data.category,
      attachedRecords: data.attachedRecords,
      viewCount: 0,
      commentCount: 0,
      created: DateTime.now(),
      updated: DateTime.now(),
    );
    _questions.add(newQuestion);

    debugPrint('[MockCommunityRepository] Created question: ${newQuestion.title}');
    return newQuestion;
  }

  /// 테스트용: 샘플 데이터 추가
  void addSampleData() {
    if (_questions.isNotEmpty) return;

    final now = DateTime.now();
    _questions.addAll([
      QuestionData(
        id: 'question_${_idCounter++}',
        title: '구피 물갈이 주기 질문',
        content: '60큐브에 구피 20마리 키우고 있는데 물갈이 주기를 어떻게 잡아야 할까요?',
        category: 'beginner',
        viewCount: 42,
        commentCount: 5,
        created: now.subtract(const Duration(hours: 3)),
      ),
      QuestionData(
        id: 'question_${_idCounter++}',
        title: '이끼 제거 방법 추천',
        content: '유리면에 녹조가 계속 생기는데 효과적인 제거 방법 있을까요?',
        category: 'maintenance',
        viewCount: 28,
        commentCount: 3,
        created: now.subtract(const Duration(hours: 8)),
      ),
      QuestionData(
        id: 'question_${_idCounter++}',
        title: '베타 합사 가능 물고기',
        content: '베타랑 합사 가능한 물고기 추천해주세요. 공격적이지 않은 종으로요.',
        category: 'species',
        viewCount: 156,
        commentCount: 12,
        created: now.subtract(const Duration(days: 1)),
      ),
    ]);
  }

  /// 테스트용: 데이터 초기화
  void clearAll() {
    _questions.clear();
    _idCounter = 1;
  }
}
