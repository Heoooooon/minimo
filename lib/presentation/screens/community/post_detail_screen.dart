import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/services/comment_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../domain/models/comment_data.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../viewmodels/community_viewmodel.dart';
import '../../widgets/community/post_card.dart';

/// 게시글 상세 화면
class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({super.key});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final CommentService _commentService = CommentService.instance;
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  PostData? _post;
  String? _postId;
  List<CommentData> _comments = [];
  bool _isLoading = true;
  bool _isLoadingComments = false;
  String? _errorMessage;
  bool _isSubmitting = false;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPost();
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    _pageController.dispose();
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
      final viewModel = context.read<CommunityViewModel>();

      // 최신 게시글에서 찾기
      PostData? foundPost;
      for (final post in viewModel.latestPosts) {
        if (post.id == _postId) {
          foundPost = post;
          break;
        }
      }

      // 팔로잉 게시글에서 찾기
      if (foundPost == null) {
        for (final post in viewModel.followingPosts) {
          if (post.id == _postId) {
            foundPost = post;
            break;
          }
        }
      }

      setState(() {
        _post = foundPost;
        _isLoading = false;
        if (foundPost == null) {
          _errorMessage = '게시글을 찾을 수 없습니다.';
        }
      });

      // 댓글 로드
      if (foundPost != null) {
        _loadComments();
      }
    } catch (e) {
      setState(() {
        _errorMessage = '게시글을 불러오는데 실패했습니다.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadComments() async {
    if (_postId == null) {
      debugPrint('_loadComments: postId is null');
      return;
    }

    debugPrint('_loadComments: Loading comments for postId: $_postId');
    setState(() {
      _isLoadingComments = true;
    });

    try {
      final comments = await _commentService.getComments(postId: _postId!);
      debugPrint('_loadComments: Got ${comments.length} comments');
      setState(() {
        _comments = comments;
        _isLoadingComments = false;
      });
    } catch (e) {
      debugPrint('_loadComments: Failed to load comments: $e');
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
      final currentUser = AuthService.instance.currentUser;
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
          _post = PostData(
            id: _post!.id,
            authorName: _post!.authorName,
            authorImageUrl: _post!.authorImageUrl,
            timeAgo: _post!.timeAgo,
            title: _post!.title,
            content: _post!.content,
            imageUrls: _post!.imageUrls,
            likeCount: _post!.likeCount,
            commentCount: _post!.commentCount + 1,
            bookmarkCount: _post!.bookmarkCount,
            isLiked: _post!.isLiked,
            isBookmarked: _post!.isBookmarked,
          );
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
      bottomNavigationBar: _buildCommentInput(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.brand),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSubtle),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadPost,
              child: Text(
                '다시 시도',
                style: AppTextStyles.bodyMediumMedium.copyWith(color: AppColors.brand),
              ),
            ),
          ],
        ),
      );
    }

    if (_post == null) {
      return const Center(
        child: Text('게시글을 찾을 수 없습니다.'),
      );
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
            _buildAuthorSection(),

            // 이미지 캐러셀
            if (_post!.imageUrls.isNotEmpty) _buildImageCarousel(),

            // 게시글 내용
            _buildContentSection(),

            const Divider(height: 1, color: AppColors.borderLight),

            // 상호작용 바
            _buildInteractionBar(),

            const Divider(height: 1, color: AppColors.borderLight),

            // 댓글 섹션
            _buildCommentsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 프로필 이미지
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE8EBF0),
              image: _post!.authorImageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(_post!.authorImageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _post!.authorImageUrl == null
                ? const Icon(Icons.person, size: 22, color: AppColors.textHint)
                : null,
          ),
          const SizedBox(width: 12),

          // 작성자 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _post!.authorName,
                  style: AppTextStyles.bodyMediumMedium.copyWith(
                    color: AppColors.textMain,
                  ),
                ),
                Text(
                  _post!.timeAgo,
                  style: AppTextStyles.captionRegular.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),

          // 팔로우 버튼
          TextButton(
            onPressed: () {
              // TODO: 팔로우 기능
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              backgroundColor: AppColors.chipPrimaryBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              '팔로우',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.brand,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel() {
    return Stack(
      children: [
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemCount: _post!.imageUrls.length,
            itemBuilder: (context, index) {
              return Image.network(
                _post!.imageUrls[index],
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.backgroundApp,
                  child: const Center(
                    child: Icon(Icons.image, size: 48, color: AppColors.textHint),
                  ),
                ),
              );
            },
          ),
        ),

        // 페이지 인디케이터
        if (_post!.imageUrls.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_post!.imageUrls.length, (index) {
                final isActive = index == _currentImageIndex;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: isActive
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildContentSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목
          Text(
            _post!.title,
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textMain,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // 내용
          Text(
            _post!.content,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textMain,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionBar() {
    return Consumer<CommunityViewModel>(
      builder: (context, viewModel, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              // 좋아요 버튼
              _buildInteractionButton(
                icon: _post!.isLiked ? Icons.favorite : Icons.favorite_border,
                iconColor: _post!.isLiked ? const Color(0xFFFE5839) : AppColors.textSubtle,
                count: _post!.likeCount,
                onTap: () {
                  viewModel.toggleLike(_post!.id, !_post!.isLiked);
                  setState(() {
                    _post = PostData(
                      id: _post!.id,
                      authorName: _post!.authorName,
                      authorImageUrl: _post!.authorImageUrl,
                      timeAgo: _post!.timeAgo,
                      title: _post!.title,
                      content: _post!.content,
                      imageUrls: _post!.imageUrls,
                      likeCount: _post!.isLiked
                          ? _post!.likeCount - 1
                          : _post!.likeCount + 1,
                      commentCount: _post!.commentCount,
                      bookmarkCount: _post!.bookmarkCount,
                      isLiked: !_post!.isLiked,
                      isBookmarked: _post!.isBookmarked,
                    );
                  });
                },
              ),

              // 댓글 버튼
              _buildInteractionButton(
                icon: Icons.chat_bubble_outline,
                iconColor: AppColors.textSubtle,
                count: _post!.commentCount,
                onTap: () {
                  _commentFocusNode.requestFocus();
                },
              ),

              const Spacer(),

              // 북마크 버튼
              _buildInteractionButton(
                icon: _post!.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                iconColor: AppColors.textSubtle,
                count: _post!.bookmarkCount,
                onTap: () {
                  viewModel.toggleBookmark(_post!.id, !_post!.isBookmarked);
                  setState(() {
                    _post = PostData(
                      id: _post!.id,
                      authorName: _post!.authorName,
                      authorImageUrl: _post!.authorImageUrl,
                      timeAgo: _post!.timeAgo,
                      title: _post!.title,
                      content: _post!.content,
                      imageUrls: _post!.imageUrls,
                      likeCount: _post!.likeCount,
                      commentCount: _post!.commentCount,
                      bookmarkCount: _post!.isBookmarked
                          ? _post!.bookmarkCount - 1
                          : _post!.bookmarkCount + 1,
                      isLiked: _post!.isLiked,
                      isBookmarked: !_post!.isBookmarked,
                    );
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInteractionButton({
    required IconData icon,
    required Color iconColor,
    required int count,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 6),
            Text(
              count.toString(),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSubtle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '댓글 ${_comments.length}',
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.textMain,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // 로딩 중
          if (_isLoadingComments)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: AppColors.brand),
              ),
            )
          // 댓글이 없는 경우
          else if (_comments.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  Text(
                    '아직 댓글이 없습니다.\n첫 번째 댓글을 작성해보세요!',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSubtle,
                    ),
                  ),
                ],
              ),
            )
          // 댓글 목록
          else
            ..._comments.map((comment) => _buildCommentItem(comment)),
        ],
      ),
    );
  }

  Widget _buildCommentItem(CommentData comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 프로필 아바타
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE8EBF0),
            ),
            child: const Icon(Icons.person, size: 18, color: AppColors.textHint),
          ),
          const SizedBox(width: 12),

          // 댓글 내용
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.authorName,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMain,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTimeAgo(comment.created),
                      style: AppTextStyles.captionRegular.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 8),

                // 좋아요 버튼
                Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        if (comment.id != null) {
                          await _commentService.toggleLike(comment.id!, true);
                          _loadComments();
                        }
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.favorite_border, size: 16, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          Text(
                            '${comment.likeCount}',
                            style: AppTextStyles.captionRegular.copyWith(
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFF),
        border: Border(
          top: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              focusNode: _commentFocusNode,
              decoration: InputDecoration(
                hintText: '댓글을 입력하세요...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textHint,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppColors.brand),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submitComment(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isSubmitting ? null : _submitComment,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.brand,
                shape: BoxShape.circle,
              ),
              child: _isSubmitting
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('신고하기'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 신고 기능
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('공유하기'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 공유 기능
              },
            ),
          ],
        ),
      ),
    );
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
}
