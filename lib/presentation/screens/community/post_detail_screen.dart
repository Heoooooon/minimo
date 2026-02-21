import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/di/app_dependencies.dart';
import '../../../data/services/comment_service.dart';
import '../../../data/services/community_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/follow_service.dart';
import '../../../domain/models/comment_data.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';
import '../../viewmodels/community_post_viewmodel.dart';
import '../../viewmodels/community_following_viewmodel.dart';
import '../../widgets/community/post_card.dart';
import 'widgets/post_author_section.dart';
import 'widgets/post_image_carousel.dart';
import 'widgets/post_content_section.dart';
import 'widgets/post_interaction_bar.dart';
import 'widgets/post_comments_section.dart';
import 'widgets/post_comment_input.dart';
import 'widgets/post_options_dialogs.dart';

/// 게시글 상세 화면
class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({super.key});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late final AppDependencies _dependencies;
  late final CommentService _commentService;
  late final CommunityService _communityService;
  late final FollowService _followService;
  late final AuthService _authService;
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  PostData? _post;
  String? _postId;
  String? _authorId; // 게시글 작성자 ID
  List<CommentData> _comments = [];
  bool _isLoading = true;
  bool _isLoadingComments = false;
  String? _errorMessage;
  bool _isSubmitting = false;
  bool _isDeleting = false;
  bool _isFollowing = false;
  bool _isFollowLoading = false;
  bool _isDependenciesReady = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isDependenciesReady) return;

    _dependencies = context.read<AppDependencies>();
    _commentService = _dependencies.commentService;
    _communityService = _dependencies.communityService;
    _followService = _dependencies.followService;
    _authService = _dependencies.authService;
    _isDependenciesReady = true;

    _loadPost();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadPost() async {
    _postId = ModalRoute.of(context)?.settings.arguments as String?;
    if (_postId == null) {
      setState(() {
        _errorMessage = '게시글 ID가 없습니다.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // ViewModel에서 게시글 찾기
      final postViewModel = context.read<CommunityPostViewModel>();
      final followingViewModel = context.read<CommunityFollowingViewModel>();

      // 최신 게시글에서 찾기
      PostData? foundPost;
      for (final post in postViewModel.latestPosts) {
        if (post.id == _postId) {
          foundPost = post;
          break;
        }
      }

      // 팔로잉 게시글에서 찾기
      if (foundPost == null) {
        for (final post in followingViewModel.followingPosts) {
          if (post.id == _postId) {
            foundPost = post;
            break;
          }
        }
      }

      setState(() {
        _post = foundPost;
        _authorId = foundPost?.authorId;
        _isLoading = false;
        if (foundPost == null) {
          _errorMessage = '게시글을 찾을 수 없습니다.';
        }
      });

      // 댓글 로드 및 팔로우 상태 확인
      if (foundPost != null) {
        _loadComments();
        _checkFollowStatus();
      }
    } catch (e) {
      AppLogger.data('게시글 로드 실패: $e', isError: true);
      setState(() {
        _errorMessage = '게시글을 불러오는데 실패했습니다.';
        _isLoading = false;
      });
    }
  }

  Future<void> _checkFollowStatus() async {
    if (_authorId == null || _authorId!.isEmpty) return;

    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    // 자기 자신은 팔로우 불가
    if (currentUser.id == _authorId) return;

    try {
      final isFollowing = await _followService.isFollowing(
        followerId: currentUser.id,
        followingId: _authorId!,
      );
      setState(() {
        _isFollowing = isFollowing;
      });
    } catch (e) {
      AppLogger.data('Failed to check follow status: $e', isError: true);
    }
  }

  Future<void> _toggleFollow() async {
    if (_authorId == null || _authorId!.isEmpty) return;

    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('로그인이 필요합니다.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // 자기 자신은 팔로우 불가
    if (currentUser.id == _authorId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('자신을 팔로우할 수 없습니다.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isFollowLoading = true;
    });

    try {
      final nowFollowing = await _followService.toggleFollow(
        followingId: _authorId!,
      );
      setState(() {
        _isFollowing = nowFollowing;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              nowFollowing
                  ? '${_post?.authorName ?? '사용자'}님을 팔로우합니다.'
                  : '${_post?.authorName ?? '사용자'}님을 언팔로우했습니다.',
            ),
            backgroundColor: nowFollowing
                ? AppColors.success
                : AppColors.textSubtle,
          ),
        );
      }
    } catch (e) {
      AppLogger.data('Failed to toggle follow: $e', isError: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('팔로우 상태 변경에 실패했습니다.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isFollowLoading = false;
      });
    }
  }

  Future<void> _loadComments() async {
    if (_postId == null) {
      AppLogger.data('_loadComments: postId is null');
      return;
    }

    AppLogger.data('_loadComments: Loading comments for postId: $_postId');
    setState(() {
      _isLoadingComments = true;
    });

    try {
      final comments = await _commentService.getComments(postId: _postId!);
      AppLogger.data('_loadComments: Got ${comments.length} comments');
      setState(() {
        _comments = comments;
        _isLoadingComments = false;
      });
    } catch (e) {
      AppLogger.data(
        '_loadComments: Failed to load comments: $e',
        isError: true,
      );
      setState(() {
        _isLoadingComments = false;
      });
    }
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty || _postId == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // 현재 사용자 이름 가져오기
      final currentUser = _authService.currentUser;
      final userName = currentUser?.getStringValue('name') ?? '익명';

      final commentData = CommentData(
        postId: _postId!,
        authorId: currentUser?.id,
        authorName: userName,
        content: _commentController.text.trim(),
      );

      await _commentService.createComment(commentData);

      _commentController.clear();
      _commentFocusNode.unfocus();

      // 댓글 목록 새로고침
      await _loadComments();

      // 댓글 수 업데이트
      if (_post != null) {
        setState(() {
          _post = _post!.copyWith(commentCount: _post!.commentCount + 1);
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('댓글이 등록되었습니다.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      AppLogger.data('댓글 등록 실패: $e', isError: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('댓글 등록에 실패했습니다.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundApp,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textMain),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '게시글',
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textMain,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textMain),
            onPressed: _showOptions,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: PostCommentInput(
        controller: _commentController,
        focusNode: _commentFocusNode,
        isSubmitting: _isSubmitting,
        onSubmit: _submitComment,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading || _isDeleting) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.brand),
            if (_isDeleting) ...[
              const SizedBox(height: 16),
              Text(
                '삭제 중...',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSubtle,
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSubtle,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadPost,
              child: Text(
                '다시 시도',
                style: AppTextStyles.bodyMediumBold.copyWith(
                  color: AppColors.brand,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_post == null) {
      return const Center(child: Text('게시글을 찾을 수 없습니다.'));
    }

    return RefreshIndicator(
      onRefresh: _loadPost,
      color: AppColors.brand,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 작성자 정보
            PostAuthorSection(
              post: _post!,
              authorId: _authorId,
              currentUserId: _authService.currentUser?.id,
              isFollowing: _isFollowing,
              isFollowLoading: _isFollowLoading,
              onToggleFollow: _toggleFollow,
            ),

            // 이미지 캐러셀
            if (_post!.imageUrls.isNotEmpty)
              PostImageCarousel(imageUrls: _post!.imageUrls),

            // 게시글 내용
            PostContentSection(
              post: _post!,
              onTagTap: (tag) {
                final viewModel = context.read<CommunityPostViewModel>();
                viewModel.filterByTag(tag);
                Navigator.pop(context);
              },
            ),

            const Divider(height: 1, color: AppColors.borderLight),

            // 상호작용 바
            Consumer<CommunityPostViewModel>(
              builder: (context, viewModel, child) {
                return PostInteractionBar(
                  post: _post!,
                  onLikeTap: () {
                    viewModel.toggleLike(_post!.id, !_post!.isLiked);
                    setState(() {
                      _post = _post!.copyWith(
                        likeCount: _post!.isLiked
                            ? _post!.likeCount - 1
                            : _post!.likeCount + 1,
                        isLiked: !_post!.isLiked,
                      );
                    });
                  },
                  onCommentTap: () {
                    _commentFocusNode.requestFocus();
                  },
                  onBookmarkTap: () {
                    viewModel.toggleBookmark(_post!.id, !_post!.isBookmarked);
                    setState(() {
                      _post = _post!.copyWith(
                        bookmarkCount: _post!.isBookmarked
                            ? _post!.bookmarkCount - 1
                            : _post!.bookmarkCount + 1,
                        isBookmarked: !_post!.isBookmarked,
                      );
                    });
                  },
                );
              },
            ),

            const Divider(height: 1, color: AppColors.borderLight),

            // 댓글 섹션
            PostCommentsSection(
              comments: _comments,
              isLoading: _isLoadingComments,
              onCommentLike: (commentId) async {
                await _commentService.toggleLike(commentId, true);
                _loadComments();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions() {
    final currentUser = _authService.currentUser;
    final isAuthor = currentUser != null && _authorId == currentUser.id;

    showPostOptionsSheet(
      context,
      isAuthor: isAuthor,
      onEdit: () => showPostEditDialog(
        context,
        currentContent: _post?.content ?? '',
        onUpdate: _updatePost,
      ),
      onDelete: () => showPostDeleteConfirmDialog(
        context,
        onDelete: _deletePost,
      ),
      onReport: () => showPostReportDialog(
        context,
        onReported: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('신고가 접수되었습니다.'),
              backgroundColor: AppColors.success,
            ),
          );
        },
      ),
      onShare: _sharePost,
    );
  }

  /// 게시글 수정
  Future<void> _updatePost(String newContent) async {
    if (_postId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _communityService.updatePost(id: _postId!, content: newContent);

      // 로컬 상태 업데이트
      if (_post != null) {
        setState(() {
          _post = _post!.copyWith(
            title: newContent.length > 30
                ? '${newContent.substring(0, 30)}...'
                : newContent,
            content: newContent,
          );
          _isLoading = false;
        });
      }

      // ViewModel 새로고침
      if (mounted) {
        context.read<CommunityPostViewModel>().refreshAll();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('게시글이 수정되었습니다.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      AppLogger.data('Failed to update post: $e', isError: true);
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('게시글 수정에 실패했습니다.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// 게시글 삭제
  Future<void> _deletePost() async {
    if (_postId == null) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      await _communityService.deletePost(_postId!);

      // ViewModel 새로고침
      if (mounted) {
        context.read<CommunityPostViewModel>().refreshAll();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('게시글이 삭제되었습니다.'),
            backgroundColor: AppColors.success,
          ),
        );
        // 이전 화면으로 돌아가기
        Navigator.pop(context);
      }
    } catch (e) {
      AppLogger.data('Failed to delete post: $e', isError: true);
      setState(() {
        _isDeleting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('게시글 삭제에 실패했습니다.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _sharePost() {
    if (_postId == null) return;

    final shareUrl = 'minimo://post/$_postId';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('링크가 복사되었습니다: $shareUrl'),
        backgroundColor: AppColors.success,
        action: SnackBarAction(
          label: '확인',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
}
