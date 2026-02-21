import '../../config/app_config.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/pb_filter.dart';
import '../../data/services/community_service.dart';
import '../../data/services/tag_service.dart';
import '../widgets/community/post_card.dart';
import '../widgets/community/recommendation_card.dart';
import '../widgets/community/popular_ranking_card.dart';
import 'base_viewmodel.dart';

/// 커뮤니티 추천 탭 ViewModel
///
/// 추천 게시글, 인기 랭킹, 태그 필터링, 좋아요/북마크 액션을 관리
class CommunityPostViewModel extends BaseViewModel {
  CommunityPostViewModel({
    CommunityService? service,
    TagService? tagService,
    bool autoLoad = true,
  }) : _service = service ?? CommunityService.instance,
       _tagService = tagService ?? TagService.instance {
    if (autoLoad) {
      _init();
    }
  }

  final CommunityService _service;
  final TagService _tagService;

  static const List<String> _defaultRecommendTags = [
    '#\uBCA0\uD0C0',
    '#25\uD050\uBE0C',
    '#\uCD08\uBCF4\uC790',
    '#\uAD6C\uD53C',
    '#\uC548\uC2DC',
  ];

  // ==================== State ====================

  // \uCD94\uCC9C \uD0ED
  PopularRankingData? _popularRanking;
  PopularRankingData? get popularRanking => _popularRanking;

  List<String> _tags = [];
  List<String> get tags => _tags;

  List<RecommendationData> _recommendationItems = [];
  List<RecommendationData> get recommendationItems => _recommendationItems;

  List<PostData> _latestPosts = [];
  List<PostData> get latestPosts => _latestPosts;

  // \uD0DC\uADF8 \uD544\uD130\uB9C1
  String? _selectedTag;
  String? get selectedTag => _selectedTag;

  List<PostData> _filteredPosts = [];
  List<PostData> get filteredPosts => _filteredPosts;

  bool _isFilteringByTag = false;
  bool get isFilteringByTag => _isFilteringByTag;

  // \uCE90\uC2DC
  bool _recommendLoaded = false;
  DateTime? _recommendLoadedAt;
  Future<void>? _recommendLoadInFlight;

  Duration get _recommendTabCacheTtl => Duration(
    seconds: AppConfig.communityRecommendTabCacheTtlSeconds > 0
        ? AppConfig.communityRecommendTabCacheTtlSeconds
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

        final posts = await postsFuture;
        _tags = await tagsFuture;
        postsCount = posts.length;
        tagsCount = _tags.length;

        // \uCD5C\uC2E0 \uAC8C\uC2DC\uAE00 \uBCC0\uD658
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

        // \uCD94\uCC9C \uAC8C\uC2DC\uAE00 \uBCC0\uD658 (\uCD5C\uC2E0 3\uAC1C)
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

        // \uC778\uAE30 \uB7AD\uD0B9 (\uCCAB \uBC88\uC9F8 \uAC8C\uC2DC\uAE00)
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
    }, errorPrefix: '\uAC8C\uC2DC\uAE00\uC744 \uBD88\uB7EC\uC624\uB294\uB370 \uC2E4\uD328\uD588\uC2B5\uB2C8\uB2E4');
  }

  // ==================== Actions ====================

  /// \uC88B\uC544\uC694 \uD1A0\uAE00
  Future<void> toggleLike(String postId, bool isLiked) async {
    try {
      await _service.toggleLike(postId, isLiked);
      _updatePostLikeState(postId, isLiked);
      notifyListeners();
    } catch (e) {
      AppLogger.data('toggleLike error: $e', isError: true);
    }
  }

  /// \uBD81\uB9C8\uD06C \uD1A0\uAE00
  Future<void> toggleBookmark(String postId, bool isBookmarked) async {
    try {
      await _service.toggleBookmark(postId, isBookmarked);
      _updatePostBookmarkState(postId, isBookmarked);
      notifyListeners();
    } catch (e) {
      AppLogger.data('toggleBookmark error: $e', isError: true);
    }
  }

  /// \uC0C8\uB85C\uACE0\uCE68
  Future<void> refreshAll() async {
    await loadRecommendTab(forceRefresh: true);
  }

  // ==================== Tag Filtering ====================

  /// \uD0DC\uADF8\uB85C \uAC8C\uC2DC\uAE00 \uD544\uD130\uB9C1
  Future<void> filterByTag(String tag) async {
    final cleanTag = tag.replaceAll('#', '').trim();
    if (cleanTag.isEmpty) {
      clearTagFilter();
      return;
    }

    await runAsync(() async {
      _selectedTag = cleanTag;
      _isFilteringByTag = true;

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
    }, errorPrefix: '\uD0DC\uADF8 \uD544\uD130\uB9C1\uC5D0 \uC2E4\uD328\uD588\uC2B5\uB2C8\uB2E4');
  }

  /// \uD0DC\uADF8 \uD544\uD130 \uD574\uC81C
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

  void _updatePostLikeState(String postId, bool isLiked) {
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
  }

  void _updatePostBookmarkState(String postId, bool isBookmarked) {
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
  }
}
