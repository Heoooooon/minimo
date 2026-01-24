import '../../core/utils/app_logger.dart';
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
  CommunityViewModel() {
    _init();
  }

  final CommunityService _service = CommunityService.instance;
  final CuriousService _curiousService = CuriousService.instance;
  final FollowService _followService = FollowService.instance;
  final TagService _tagService = TagService.instance;
  final AuthService _authService = AuthService.instance;

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

  // ==================== Initialization ====================
  Future<void> _init() async {
    await loadRecommendTab();
  }

  // ==================== Recommend Tab ====================
  Future<void> loadRecommendTab() async {
    await runAsync(() async {
      // 커뮤니티 포스트 로딩 (sort 파라미터 임시 제거)
      final posts = await _service.getPosts(perPage: 10);

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

      // 인기 태그 로딩 (TagService 연동)
      await _loadPopularTags();

      return posts;
    }, errorPrefix: '게시글을 불러오는데 실패했습니다');
  }

  // ==================== Following Tab ====================
  Future<void> loadFollowingTab() async {
    await runAsync(() async {
      // 로그인 여부 확인
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        _followingPosts = [];
        return [];
      }

      // 팔로잉 목록 조회
      final followingIds = await _followService.getFollowing(
        userId: currentUser.id,
      );

      if (followingIds.isEmpty) {
        _followingPosts = [];
        return [];
      }

      // 팔로잉 사용자들의 게시글만 필터링
      // PocketBase 필터: author_id IN (...)
      final filterParts = followingIds
          .map((id) => 'author_id = "$id"')
          .toList();
      final filter = filterParts.join(' || ');

      final posts = await _service.getPosts(perPage: 20, filter: filter);

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

      return posts;
    }, errorPrefix: '팔로잉 게시글을 불러오는데 실패했습니다');
  }

  // ==================== Q&A Tab ====================
  Future<void> loadQnaTab() async {
    await runAsync(() async {
      // 질문 목록 로딩 (sort 파라미터 임시 제거)
      final questions = await _service.getQuestions(perPage: 20);

      // 인기 질문 (view_count 순 또는 최신)
      final popularQuestions = List<QuestionData>.from(questions);
      popularQuestions.sort((a, b) => b.viewCount.compareTo(a.viewCount));

      _popularQuestions = popularQuestions.take(3).toList().asMap().entries.map(
        (entry) {
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
        },
      ).toList();

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
      waitingQuestions.sort((a, b) => a.commentCount.compareTo(b.commentCount));

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

      // Q&A 인기 태그 로딩 (TagService 연동)
      await _loadQnaTags();

      return questions;
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
        filter: 'author_id = "${currentUser.id}"',
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
    await loadRecommendTab();
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
        filter: 'tags ~ "$cleanTag"',
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

  /// 인기 태그 로딩 (TagService 연동)
  Future<void> _loadPopularTags() async {
    try {
      final popularTags = await _tagService.getPopularTags(limit: 5);
      if (popularTags.isNotEmpty) {
        _tags = popularTags.map((tag) => '#${tag.name}').toList();
      } else {
        // 태그가 없으면 기본값 유지
        _tags = ['#베타', '#25큐브', '#초보자', '#구피', '#안시'];
      }
    } catch (e) {
      AppLogger.data('Failed to load popular tags: $e', isError: true);
      // 에러 시 기본값 유지
      _tags = ['#베타', '#25큐브', '#초보자', '#구피', '#안시'];
    }
  }

  /// Q&A 인기 태그 로딩
  Future<void> _loadQnaTags() async {
    try {
      final popularTags = await _tagService.getPopularTags(
        limit: 5,
        category: 'qna',
      );
      if (popularTags.isNotEmpty) {
        _qnaTags = popularTags.map((tag) => '#${tag.name}').toList();
      } else {
        _qnaTags = ['#25큐브', '#구피초보', '#물잡이', '#이끼'];
      }
    } catch (e) {
      AppLogger.data('Failed to load QnA tags: $e', isError: true);
      _qnaTags = ['#25큐브', '#구피초보', '#물잡이', '#이끼'];
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
