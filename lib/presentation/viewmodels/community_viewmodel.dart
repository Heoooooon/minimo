import '../../config/app_config.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/pb_filter.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/community_service.dart';
import '../../data/services/curious_service.dart';
import '../../data/services/follow_service.dart';
import '../../data/services/tag_service.dart';
import '../../domain/models/question_data.dart';
import '../widgets/community/post_card.dart';
import '../widgets/community/recommendation_card.dart';
import '../widgets/community/qna_question_card.dart';
import '../widgets/community/popular_ranking_card.dart';
import 'base_viewmodel.dart';

/// 커뮤니티 화면 ViewModel
///
/// 추천/팔로잉/Q&A 탭의 데이터를 관리
class CommunityViewModel extends BaseViewModel {
  CommunityViewModel({
    CommunityService? service,
    CuriousService? curiousService,
    FollowService? followService,
    TagService? tagService,
    required AuthService authService,
    bool autoLoad = true,
  }) : _service = service ?? CommunityService.instance,
       _curiousService = curiousService ?? CuriousService.instance,
       _followService = followService ?? FollowService.instance,
       _tagService = tagService ?? TagService.instance,
       _authService = authService {
    if (autoLoad) {
      _init();
    }
  }

  final CommunityService _service;
  final CuriousService _curiousService;
  final FollowService _followService;
  final TagService _tagService;
  final AuthService _authService;
  static const List<String> _defaultRecommendTags = [
    '#베타',
    '#25큐브',
    '#초보자',
    '#구피',
    '#안시',
  ];
  static const List<String> _defaultQnaTags = ['#25큐브', '#구피초보', '#물잡이', '#이끼'];

  // ==================== State ====================

  // 추천 탭
  PopularRankingData? _popularRanking;
  PopularRankingData? get popularRanking => _popularRanking;

  List<String> _tags = [];
  List<String> get tags => _tags;

  List<RecommendationData> _recommendationItems = [];
  List<RecommendationData> get recommendationItems => _recommendationItems;

  List<PostData> _latestPosts = [];
  List<PostData> get latestPosts => _latestPosts;

  // 팔로잉 탭
  List<PostData> _followingPosts = [];
  List<PostData> get followingPosts => _followingPosts;

  // Q&A 탭
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

  // 태그 필터링
  String? _selectedTag;
  String? get selectedTag => _selectedTag;

  List<PostData> _filteredPosts = [];
  List<PostData> get filteredPosts => _filteredPosts;

  bool _isFilteringByTag = false;
  bool get isFilteringByTag => _isFilteringByTag;

  // 탭 로드 캐시 (불필요한 재호출 방지)
  bool _recommendLoaded = false;
  bool _followingLoaded = false;
  String? _followingLoadedUserId;
  bool _qnaLoaded = false;
  DateTime? _recommendLoadedAt;
  DateTime? _followingLoadedAt;
  DateTime? _qnaLoadedAt;
  Future<void>? _recommendLoadInFlight;
  Future<void>? _followingLoadInFlight;
  Future<void>? _qnaLoadInFlight;

  Duration get _recommendTabCacheTtl => Duration(
    seconds: AppConfig.communityRecommendTabCacheTtlSeconds > 0
        ? AppConfig.communityRecommendTabCacheTtlSeconds
        : 60,
  );
  Duration get _followingTabCacheTtl => Duration(
    seconds: AppConfig.communityFollowingTabCacheTtlSeconds > 0
        ? AppConfig.communityFollowingTabCacheTtlSeconds
        : 60,
  );
  Duration get _qnaTabCacheTtl => Duration(
    seconds: AppConfig.communityQnaTabCacheTtlSeconds > 0
        ? AppConfig.communityQnaTabCacheTtlSeconds
        : 60,
  );

  // ==================== Initialization ====================
  Future<void> _init() async {
    await loadRecommendTab();
  }

  // ==================== Recommend Tab ====================
  Future<void> loadRecommendTab({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _recommendLoaded &&
        _isCacheFresh(_recommendLoadedAt, _recommendTabCacheTtl)) {
      return;
    }
    if (_recommendLoadInFlight != null) {
      await _recommendLoadInFlight;
      return;
    }

    final inFlight = _loadRecommendTabInternal();
    _recommendLoadInFlight = inFlight;
    try {
      await inFlight;
    } finally {
      if (identical(_recommendLoadInFlight, inFlight)) {
        _recommendLoadInFlight = null;
      }
    }
  }

  Future<void> _loadRecommendTabInternal() async {
    await runAsync(() async {
      final stopwatch = Stopwatch()..start();
      int postsCount = 0;
      int tagsCount = 0;

      try {
        final postsFuture = _service.getPosts(perPage: 10);
        final tagsFuture = _fetchPopularTagLabels(
          fallback: _defaultRecommendTags,
        );

        // 커뮤니티 포스트 로딩 (sort 파라미터 임시 제거)
        final posts = await postsFuture;
        _tags = await tagsFuture;
        postsCount = posts.length;
        tagsCount = _tags.length;

        // 최신 게시글 변환
        _latestPosts = posts
            .map(
              (post) => PostData(
                id: post.id,
                authorId: post.authorId,
                authorName: post.authorName,
                authorImageUrl: post.authorImageUrl,
                timeAgo: post.timeAgo,
                title: post.content.length > 30
                    ? '${post.content.substring(0, 30)}...'
                    : post.content,
                content: post.content,
                imageUrls: post.imageUrl != null ? [post.imageUrl!] : [],
                tags: post.tags,
                likeCount: post.likeCount,
                commentCount: post.commentCount,
                bookmarkCount: post.bookmarkCount,
                isLiked: post.isLiked,
                isBookmarked: post.isBookmarked,
              ),
            )
            .toList();

        // 추천 게시글 변환 (최신 3개)
        final recommendPosts = posts.take(3);
        _recommendationItems = recommendPosts
            .map(
              (post) => RecommendationData(
                id: post.id,
                title: post.content.length > 30
                    ? '${post.content.substring(0, 30)}...'
                    : post.content,
                content: post.content,
                authorName: post.authorName,
                timeAgo: post.timeAgo,
                imageUrl: post.imageUrl,
              ),
            )
            .toList();

        // 인기 랭킹 (첫 번째 게시글)
        if (posts.isNotEmpty) {
          final topPost = posts.first;
          _popularRanking = PopularRankingData(
            rank: 1,
            title: topPost.content.length > 40
                ? '${topPost.content.substring(0, 40)}...'
                : topPost.content,
            id: topPost.id,
          );
        }

        _recommendLoaded = true;
        _recommendLoadedAt = DateTime.now();
        return posts;
      } finally {
        stopwatch.stop();
        AppLogger.perf(
          'Community.loadRecommendTab',
          stopwatch.elapsed,
          fields: {'posts': postsCount, 'tags': tagsCount},
        );
      }
    }, errorPrefix: '게시글을 불러오는데 실패했습니다');
  }

  // ==================== Following Tab ====================
  Future<void> loadFollowingTab({bool forceRefresh = false}) async {
    final currentUserId = _authService.currentUser?.id;
    if (!forceRefresh &&
        _followingLoaded &&
        _followingLoadedUserId == currentUserId &&
        _isCacheFresh(_followingLoadedAt, _followingTabCacheTtl)) {
      return;
    }
    if (_followingLoadInFlight != null) {
      await _followingLoadInFlight;
      return;
    }

    final inFlight = _loadFollowingTabInternal();
    _followingLoadInFlight = inFlight;
    try {
      await inFlight;
    } finally {
      if (identical(_followingLoadInFlight, inFlight)) {
        _followingLoadInFlight = null;
      }
    }
  }

  Future<void> _loadFollowingTabInternal() async {
    await runAsync(() async {
      final stopwatch = Stopwatch()..start();
      int followingCount = 0;
      int postsCount = 0;

      try {
        // 로그인 여부 확인
        final currentUser = _authService.currentUser;
        if (currentUser == null) {
          _followingPosts = [];
          _followingLoaded = true;
          _followingLoadedUserId = null;
          _followingLoadedAt = DateTime.now();
          return [];
        }

        // 팔로잉 목록 조회
        final followingIds = await _followService.getFollowing(
          userId: currentUser.id,
        );
        followingCount = followingIds.length;

        if (followingIds.isEmpty) {
          _followingPosts = [];
          _followingLoaded = true;
          _followingLoadedUserId = currentUser.id;
          _followingLoadedAt = DateTime.now();
          return [];
        }

        // 팔로잉 사용자들의 게시글만 필터링
        // PocketBase 필터: author_id IN (...)
        final filterParts = followingIds
            .map((id) => PbFilter.eq('author_id', id))
            .toList();
        final filter = filterParts.join(' || ');

        final posts = await _service.getPosts(perPage: 20, filter: filter);
        postsCount = posts.length;

        _followingPosts = posts
            .map(
              (post) => PostData(
                id: post.id,
                authorId: post.authorId,
                authorName: post.authorName,
                authorImageUrl: post.authorImageUrl,
                timeAgo: post.timeAgo,
                title: post.content.length > 30
                    ? '${post.content.substring(0, 30)}...'
                    : post.content,
                content: post.content,
                imageUrls: post.imageUrl != null ? [post.imageUrl!] : [],
                tags: post.tags,
                likeCount: post.likeCount,
                commentCount: post.commentCount,
                bookmarkCount: post.bookmarkCount,
                isLiked: post.isLiked,
                isBookmarked: post.isBookmarked,
              ),
            )
            .toList();

        _followingLoaded = true;
        _followingLoadedUserId = currentUser.id;
        _followingLoadedAt = DateTime.now();
        return posts;
      } finally {
        stopwatch.stop();
        AppLogger.perf(
          'Community.loadFollowingTab',
          stopwatch.elapsed,
          fields: {'following': followingCount, 'posts': postsCount},
        );
      }
    }, errorPrefix: '팔로잉 게시글을 불러오는데 실패했습니다');
  }

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

        // 질문 목록 로딩 (sort 파라미터 임시 제거)
        final questions = await questionsFuture;
        _qnaTags = await tagsFuture;
        questionsCount = questions.length;
        tagsCount = _qnaTags.length;

        // 인기 질문 (view_count 순 또는 최신)
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

        // Featured Question (랜덤 또는 최신)
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
    }, errorPrefix: 'Q&A를 불러오는데 실패했습니다');
  }

  // ==================== My Questions ====================
  Future<void> loadMyQuestions() async {
    try {
      // 현재 로그인한 사용자의 질문만 필터링
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

  // ==================== Actions ====================

  /// 좋아요 토글
  Future<void> toggleLike(String postId, bool isLiked) async {
    try {
      await _service.toggleLike(postId, isLiked);

      // 로컬 상태 업데이트
      _updatePostLikeState(postId, isLiked);
      notifyListeners();
    } catch (e) {
      AppLogger.data('toggleLike error: $e', isError: true);
    }
  }

  /// 북마크 토글
  Future<void> toggleBookmark(String postId, bool isBookmarked) async {
    try {
      await _service.toggleBookmark(postId, isBookmarked);

      // 로컬 상태 업데이트
      _updatePostBookmarkState(postId, isBookmarked);
      notifyListeners();
    } catch (e) {
      AppLogger.data('toggleBookmark error: $e', isError: true);
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

  /// 새로고침
  Future<void> refreshAll() async {
    await loadRecommendTab(forceRefresh: true);
  }

  // ==================== Curious (궁금해요) ====================

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

  // ==================== Tag Filtering ====================

  /// 태그로 게시글 필터링
  Future<void> filterByTag(String tag) async {
    final cleanTag = tag.replaceAll('#', '').trim();
    if (cleanTag.isEmpty) {
      clearTagFilter();
      return;
    }

    await runAsync(() async {
      _selectedTag = cleanTag;
      _isFilteringByTag = true;

      // PocketBase 필터: tags 배열에 해당 태그가 포함된 게시글
      // JSON 배열 필터링: tags ~ "tagName"
      final posts = await _service.getPosts(
        perPage: 50,
        filter: 'tags ~ "${PbFilter.sanitize(cleanTag)}"',
      );

      _filteredPosts = posts
          .map(
            (post) => PostData(
              id: post.id,
              authorId: post.authorId,
              authorName: post.authorName,
              authorImageUrl: post.authorImageUrl,
              timeAgo: post.timeAgo,
              title: post.content.length > 30
                  ? '${post.content.substring(0, 30)}...'
                  : post.content,
              content: post.content,
              imageUrls: post.imageUrl != null ? [post.imageUrl!] : [],
              tags: post.tags,
              likeCount: post.likeCount,
              commentCount: post.commentCount,
              bookmarkCount: post.bookmarkCount,
              isLiked: post.isLiked,
              isBookmarked: post.isBookmarked,
            ),
          )
          .toList();

      return posts;
    }, errorPrefix: '태그 필터링에 실패했습니다');
  }

  /// 태그 필터 해제
  void clearTagFilter() {
    _selectedTag = null;
    _isFilteringByTag = false;
    _filteredPosts = [];
    notifyListeners();
  }

  // ==================== Helpers ====================

  bool _isCacheFresh(DateTime? loadedAt, Duration ttl) {
    if (loadedAt == null) return false;
    return DateTime.now().difference(loadedAt) < ttl;
  }

  /// 태그 목록 조회 + 폴백 적용
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
    if (dateTime == null) return '방금 전';

    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) {
      return '${diff.inDays}일 전';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}시간 전';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}분 전';
    }
    return '방금 전';
  }

  void _updatePostLikeState(String postId, bool isLiked) {
    // 최신 게시글 업데이트
    final latestIndex = _latestPosts.indexWhere((p) => p.id == postId);
    if (latestIndex != -1) {
      final post = _latestPosts[latestIndex];
      _latestPosts[latestIndex] = PostData(
        id: post.id,
        authorName: post.authorName,
        authorImageUrl: post.authorImageUrl,
        timeAgo: post.timeAgo,
        title: post.title,
        content: post.content,
        imageUrls: post.imageUrls,
        likeCount: isLiked ? post.likeCount + 1 : post.likeCount - 1,
        commentCount: post.commentCount,
        bookmarkCount: post.bookmarkCount,
        isLiked: isLiked,
        isBookmarked: post.isBookmarked,
      );
    }

    // 팔로잉 게시글 업데이트
    final followingIndex = _followingPosts.indexWhere((p) => p.id == postId);
    if (followingIndex != -1) {
      final post = _followingPosts[followingIndex];
      _followingPosts[followingIndex] = PostData(
        id: post.id,
        authorName: post.authorName,
        authorImageUrl: post.authorImageUrl,
        timeAgo: post.timeAgo,
        title: post.title,
        content: post.content,
        imageUrls: post.imageUrls,
        likeCount: isLiked ? post.likeCount + 1 : post.likeCount - 1,
        commentCount: post.commentCount,
        bookmarkCount: post.bookmarkCount,
        isLiked: isLiked,
        isBookmarked: post.isBookmarked,
      );
    }
  }

  void _updatePostBookmarkState(String postId, bool isBookmarked) {
    // 최신 게시글 업데이트
    final latestIndex = _latestPosts.indexWhere((p) => p.id == postId);
    if (latestIndex != -1) {
      final post = _latestPosts[latestIndex];
      _latestPosts[latestIndex] = PostData(
        id: post.id,
        authorName: post.authorName,
        authorImageUrl: post.authorImageUrl,
        timeAgo: post.timeAgo,
        title: post.title,
        content: post.content,
        imageUrls: post.imageUrls,
        likeCount: post.likeCount,
        commentCount: post.commentCount,
        bookmarkCount: isBookmarked
            ? post.bookmarkCount + 1
            : post.bookmarkCount - 1,
        isLiked: post.isLiked,
        isBookmarked: isBookmarked,
      );
    }

    // 팔로잉 게시글 업데이트
    final followingIndex = _followingPosts.indexWhere((p) => p.id == postId);
    if (followingIndex != -1) {
      final post = _followingPosts[followingIndex];
      _followingPosts[followingIndex] = PostData(
        id: post.id,
        authorName: post.authorName,
        authorImageUrl: post.authorImageUrl,
        timeAgo: post.timeAgo,
        title: post.title,
        content: post.content,
        imageUrls: post.imageUrls,
        likeCount: post.likeCount,
        commentCount: post.commentCount,
        bookmarkCount: isBookmarked
            ? post.bookmarkCount + 1
            : post.bookmarkCount - 1,
        isLiked: post.isLiked,
        isBookmarked: isBookmarked,
      );
    }
  }
}
