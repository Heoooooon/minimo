import '../../config/app_config.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/pb_filter.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/community_service.dart';
import '../../data/services/curious_service.dart';
import '../../data/services/tag_service.dart';
import '../../domain/models/question_data.dart';
import '../widgets/community/qna_question_card.dart';
import 'base_viewmodel.dart';

/// 커뮤니티 Q&A 탭 ViewModel
///
/// Q&A 질문, 궁금해요, 내 질문/답변 데이터를 관리
class CommunityQnaViewModel extends BaseViewModel {
  CommunityQnaViewModel({
    CommunityService? service,
    CuriousService? curiousService,
    TagService? tagService,
    required AuthService authService,
  }) : _service = service ?? CommunityService.instance,
       _curiousService = curiousService ?? CuriousService.instance,
       _tagService = tagService ?? TagService.instance,
       _authService = authService;

  final CommunityService _service;
  final CuriousService _curiousService;
  final TagService _tagService;
  final AuthService _authService;

  static const List<String> _defaultQnaTags = ['#25\uD050\uBE0C', '#\uAD6C\uD53C\uCD08\uBCF4', '#\uBB3C\uC7A1\uC774', '#\uC774\uB07C'];

  // ==================== State ====================

  List<String> _qnaTags = [];
  List<String> get qnaTags => _qnaTags;

  List<QnaQuestionData> _popularQuestions = [];
  List<QnaQuestionData> get popularQuestions => _popularQuestions;

  QnaQuestionData? _featuredQuestion;
  QnaQuestionData? get featuredQuestion => _featuredQuestion;

  List<QnaQuestionData> _waitingQuestions = [];
  List<QnaQuestionData> get waitingQuestions => _waitingQuestions;

  // 내 질문/내 답변
  List<QuestionData> _myQuestions = [];
  List<QuestionData> get myQuestions => _myQuestions;

  // 캐시
  bool _qnaLoaded = false;
  DateTime? _qnaLoadedAt;
  Future<void>? _qnaLoadInFlight;

  Duration get _qnaTabCacheTtl => Duration(
    seconds: AppConfig.communityQnaTabCacheTtlSeconds > 0
        ? AppConfig.communityQnaTabCacheTtlSeconds
        : 60,
  );

  // ==================== Q&A Tab ====================
  Future<void> loadQnaTab({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _qnaLoaded &&
        _isCacheFresh(_qnaLoadedAt, _qnaTabCacheTtl)) {
      return;
    }
    if (_qnaLoadInFlight != null) {
      await _qnaLoadInFlight;
      return;
    }

    final inFlight = _loadQnaTabInternal();
    _qnaLoadInFlight = inFlight;
    try {
      await inFlight;
    } finally {
      if (identical(_qnaLoadInFlight, inFlight)) {
        _qnaLoadInFlight = null;
      }
    }
  }

  Future<void> _loadQnaTabInternal() async {
    await runAsync(() async {
      final stopwatch = Stopwatch()..start();
      int questionsCount = 0;
      int tagsCount = 0;

      try {
        final questionsFuture = _service.getQuestions(perPage: 20);
        final tagsFuture = _fetchPopularTagLabels(
          category: 'qna',
          fallback: _defaultQnaTags,
        );

        final questions = await questionsFuture;
        _qnaTags = await tagsFuture;
        questionsCount = questions.length;
        tagsCount = _qnaTags.length;

        // 인기 질문 (view_count 순)
        final popularQuestions = List<QuestionData>.from(questions);
        popularQuestions.sort((a, b) => b.viewCount.compareTo(a.viewCount));

        _popularQuestions = popularQuestions
            .take(3)
            .toList()
            .asMap()
            .entries
            .map((entry) {
              final index = entry.key;
              final q = entry.value;
              return QnaQuestionData(
                id: q.id ?? '',
                rank: index + 1,
                title: q.title,
                content: q.content,
                answerCount: q.commentCount,
                timeAgo: _formatTimeAgo(q.created),
              );
            })
            .toList();

        // Featured Question
        if (questions.isNotEmpty) {
          final featured = questions.first;
          _featuredQuestion = QnaQuestionData(
            id: featured.id ?? '',
            title: featured.title,
            content: featured.content,
            tags: [featured.category],
          );
        }

        // 답변 대기 질문 (댓글이 적은 순)
        final waitingQuestions = List<QuestionData>.from(questions);
        waitingQuestions.sort(
          (a, b) => a.commentCount.compareTo(b.commentCount),
        );

        _waitingQuestions = waitingQuestions
            .take(5)
            .map(
              (q) => QnaQuestionData(
                id: q.id ?? '',
                title: q.title,
                content: q.content,
                answerCount: q.commentCount,
                timeAgo: _formatTimeAgo(q.created),
              ),
            )
            .toList();

        _qnaLoaded = true;
        _qnaLoadedAt = DateTime.now();
        return questions;
      } finally {
        stopwatch.stop();
        AppLogger.perf(
          'Community.loadQnaTab',
          stopwatch.elapsed,
          fields: {'questions': questionsCount, 'tags': tagsCount},
        );
      }
    }, errorPrefix: 'Q&A\uB97C \uBD88\uB7EC\uC624\uB294\uB370 \uC2E4\uD328\uD588\uC2B5\uB2C8\uB2E4');
  }

  // ==================== My Questions ====================
  Future<void> loadMyQuestions() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        _myQuestions = [];
        notifyListeners();
        return;
      }

      final questions = await _service.getQuestions(
        perPage: 20,
        filter: PbFilter.eq('author_id', currentUser.id),
      );
      _myQuestions = questions;
      notifyListeners();
    } catch (e) {
      AppLogger.data('loadMyQuestions error: $e', isError: true);
    }
  }

  // ==================== Curious (\uAD81\uAE08\uD574\uC694) ====================

  /// 궁금해요 토글
  Future<bool> toggleCurious(String questionId) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        AppLogger.data('toggleCurious: user not logged in', isError: true);
        return false;
      }

      final isCurious = await _curiousService.toggleCurious(
        userId: currentUser.id,
        questionId: questionId,
      );

      notifyListeners();
      return isCurious;
    } catch (e) {
      AppLogger.data('toggleCurious error: $e', isError: true);
      return false;
    }
  }

  /// 궁금해요 여부 확인
  Future<bool> isCurious(String questionId) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return false;

      return await _curiousService.isCurious(
        userId: currentUser.id,
        questionId: questionId,
      );
    } catch (e) {
      AppLogger.data('isCurious error: $e', isError: true);
      return false;
    }
  }

  /// 조회수 증가
  Future<void> incrementViewCount(String questionId) async {
    try {
      await _service.incrementViewCount(questionId);
    } catch (e) {
      AppLogger.data('incrementViewCount error: $e', isError: true);
    }
  }

  // ==================== Helpers ====================

  bool _isCacheFresh(DateTime? loadedAt, Duration ttl) {
    if (loadedAt == null) return false;
    return DateTime.now().difference(loadedAt) < ttl;
  }

  Future<List<String>> _fetchPopularTagLabels({
    String? category,
    required List<String> fallback,
  }) async {
    try {
      final popularTags = await _tagService.getPopularTags(
        limit: 5,
        category: category,
      );
      if (popularTags.isNotEmpty) {
        return popularTags.map((tag) => '#${tag.name}').toList();
      }
      return fallback;
    } catch (e) {
      AppLogger.data('Failed to load popular tags: $e', isError: true);
      return fallback;
    }
  }

  String _formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return '\uBC29\uAE08 \uC804';

    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) {
      return '${diff.inDays}\uC77C \uC804';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}\uC2DC\uAC04 \uC804';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}\uBD84 \uC804';
    }
    return '\uBC29\uAE08 \uC804';
  }
}
