import 'package:flutter/foundation.dart';
import '../../data/services/community_service.dart';
import '../../domain/models/question_data.dart';
import '../widgets/community/post_card.dart';
import '../widgets/community/recommendation_card.dart';
import '../widgets/community/qna_question_card.dart';
import '../widgets/community/popular_ranking_card.dart';

/// 커뮤니티 화면 ViewModel
///
/// 추천/팔로잉/Q&A 탭의 데이터를 관리
class CommunityViewModel extends ChangeNotifier {
  CommunityViewModel() {
    _init();
  }

  final CommunityService _service = CommunityService.instance;

  // ==================== State ====================
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

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

  // ==================== Initialization ====================
  Future<void> _init() async {
    await loadRecommendTab();
  }

  // ==================== Recommend Tab ====================
  Future<void> loadRecommendTab() async {
    _setLoading(true);
    _clearError();

    try {
      // 커뮤니티 포스트 로딩 (sort 파라미터 임시 제거)
      final posts = await _service.getPosts(
        perPage: 10,
      );

      // 최신 게시글 변환
      _latestPosts = posts.map((post) => PostData(
        id: post.id,
        authorName: post.authorName,
        authorImageUrl: post.authorImageUrl,
        timeAgo: post.timeAgo,
        title: post.content.length > 30
            ? '${post.content.substring(0, 30)}...'
            : post.content,
        content: post.content,
        imageUrls: post.imageUrl != null ? [post.imageUrl!] : [],
        likeCount: post.likeCount,
        commentCount: post.commentCount,
        bookmarkCount: post.bookmarkCount,
        isLiked: post.isLiked,
        isBookmarked: post.isBookmarked,
      )).toList();

      // 추천 게시글 변환 (최신 3개)
      final recommendPosts = posts.take(3);
      _recommendationItems = recommendPosts.map((post) => RecommendationData(
        id: post.id,
        title: post.content.length > 30
            ? '${post.content.substring(0, 30)}...'
            : post.content,
        content: post.content,
        authorName: post.authorName,
        timeAgo: post.timeAgo,
        imageUrl: post.imageUrl,
      )).toList();

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

      // 태그 (하드코딩 - 추후 태그 시스템 구현 시 교체)
      _tags = ['#베타', '#25큐브', '#초보자', '#구피', '#안시'];

      notifyListeners();
    } catch (e) {
      _setError('게시글을 불러오는데 실패했습니다: $e');
      debugPrint('loadRecommendTab error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ==================== Following Tab ====================
  Future<void> loadFollowingTab() async {
    _setLoading(true);
    _clearError();

    try {
      // TODO: 팔로잉 시스템 구현 후 필터링 추가
      // 현재는 최신 포스트로 대체 (sort 파라미터 임시 제거)
      final posts = await _service.getPosts(
        perPage: 10,
      );

      _followingPosts = posts.map((post) => PostData(
        id: post.id,
        authorName: post.authorName,
        authorImageUrl: post.authorImageUrl,
        timeAgo: post.timeAgo,
        title: post.content.length > 30
            ? '${post.content.substring(0, 30)}...'
            : post.content,
        content: post.content,
        imageUrls: post.imageUrl != null ? [post.imageUrl!] : [],
        likeCount: post.likeCount,
        commentCount: post.commentCount,
        bookmarkCount: post.bookmarkCount,
        isLiked: post.isLiked,
        isBookmarked: post.isBookmarked,
      )).toList();

      notifyListeners();
    } catch (e) {
      _setError('팔로잉 게시글을 불러오는데 실패했습니다: $e');
      debugPrint('loadFollowingTab error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ==================== Q&A Tab ====================
  Future<void> loadQnaTab() async {
    _setLoading(true);
    _clearError();

    try {
      // 질문 목록 로딩 (sort 파라미터 임시 제거)
      final questions = await _service.getQuestions(
        perPage: 20,
      );

      // 인기 질문 (view_count 순 또는 최신)
      final popularQuestions = List<QuestionData>.from(questions);
      popularQuestions.sort((a, b) => b.viewCount.compareTo(a.viewCount));

      _popularQuestions = popularQuestions.take(3).toList().asMap().entries.map((entry) {
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
      }).toList();

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

      _waitingQuestions = waitingQuestions.take(5).map((q) => QnaQuestionData(
        id: q.id ?? '',
        title: q.title,
        content: q.content,
        answerCount: q.commentCount,
        timeAgo: _formatTimeAgo(q.created),
      )).toList();

      // Q&A 태그 (하드코딩 - 추후 태그 시스템 구현 시 교체)
      _qnaTags = ['#25큐브', '#구피초보', '#물잡이', '#이끼'];

      notifyListeners();
    } catch (e) {
      _setError('Q&A를 불러오는데 실패했습니다: $e');
      debugPrint('loadQnaTab error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ==================== My Questions ====================
  Future<void> loadMyQuestions() async {
    try {
      // TODO: 현재 로그인한 사용자의 질문만 필터링
      final questions = await _service.getQuestions(
        perPage: 20,
      );
      _myQuestions = questions;
      notifyListeners();
    } catch (e) {
      debugPrint('loadMyQuestions error: $e');
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
      debugPrint('toggleLike error: $e');
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
      debugPrint('toggleBookmark error: $e');
    }
  }

  /// 조회수 증가
  Future<void> incrementViewCount(String questionId) async {
    try {
      await _service.incrementViewCount(questionId);
    } catch (e) {
      debugPrint('incrementViewCount error: $e');
    }
  }

  /// 새로고침
  Future<void> refreshAll() async {
    await loadRecommendTab();
  }

  // ==================== Helpers ====================
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
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
        bookmarkCount: isBookmarked ? post.bookmarkCount + 1 : post.bookmarkCount - 1,
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
        bookmarkCount: isBookmarked ? post.bookmarkCount + 1 : post.bookmarkCount - 1,
        isLiked: post.isLiked,
        isBookmarked: isBookmarked,
      );
    }
  }
}
