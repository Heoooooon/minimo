import '../../config/app_config.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/pb_filter.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/community_service.dart';
import '../../data/services/follow_service.dart';
import '../widgets/community/post_card.dart';
import 'base_viewmodel.dart';

/// 커뮤니티 팔로잉 탭 ViewModel
///
/// 팔로잉 사용자들의 게시글 데이터를 관리
class CommunityFollowingViewModel extends BaseViewModel {
  CommunityFollowingViewModel({
    CommunityService? service,
    FollowService? followService,
    required AuthService authService,
  }) : _service = service ?? CommunityService.instance,
       _followService = followService ?? FollowService.instance,
       _authService = authService;

  final CommunityService _service;
  final FollowService _followService;
  final AuthService _authService;

  // ==================== State ====================

  List<PostData> _followingPosts = [];
  List<PostData> get followingPosts => _followingPosts;

  // 캐시
  bool _followingLoaded = false;
  String? _followingLoadedUserId;
  DateTime? _followingLoadedAt;
  Future<void>? _followingLoadInFlight;

  Duration get _followingTabCacheTtl => Duration(
    seconds: AppConfig.communityFollowingTabCacheTtlSeconds > 0
        ? AppConfig.communityFollowingTabCacheTtlSeconds
        : 60,
  );

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
        final currentUser = _authService.currentUser;
        if (currentUser == null) {
          _followingPosts = [];
          _followingLoaded = true;
          _followingLoadedUserId = null;
          _followingLoadedAt = DateTime.now();
          return <dynamic>[];
        }

        final followingIds = await _followService.getFollowing(
          userId: currentUser.id,
        );
        followingCount = followingIds.length;

        if (followingIds.isEmpty) {
          _followingPosts = [];
          _followingLoaded = true;
          _followingLoadedUserId = currentUser.id;
          _followingLoadedAt = DateTime.now();
          return <dynamic>[];
        }

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
    }, errorPrefix: '\uD314\uB85C\uC789 \uAC8C\uC2DC\uAE00\uC744 \uBD88\uB7EC\uC624\uB294\uB370 \uC2E4\uD328\uD588\uC2B5\uB2C8\uB2E4');
  }

  /// 좋아요 토글 (팔로잉 게시글 로컬 상태 업데이트)
  void updatePostLikeState(String postId, bool isLiked) {
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
      notifyListeners();
    }
  }

  /// 북마크 토글 (팔로잉 게시글 로컬 상태 업데이트)
  void updatePostBookmarkState(String postId, bool isBookmarked) {
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
      notifyListeners();
    }
  }

  // ==================== Helpers ====================

  bool _isCacheFresh(DateTime? loadedAt, Duration ttl) {
    if (loadedAt == null) return false;
    return DateTime.now().difference(loadedAt) < ttl;
  }
}
