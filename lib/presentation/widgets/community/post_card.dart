import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// 커뮤니티 게시글 데이터 모델
class PostData {
  final String id;
  final String authorName;
  final String? authorImageUrl;
  final String timeAgo;
  final String title;
  final String content;
  final List<String> imageUrls;
  final int likeCount;
  final int commentCount;
  final int bookmarkCount;
  final bool isLiked;
  final bool isBookmarked;

  const PostData({
    required this.id,
    required this.authorName,
    this.authorImageUrl,
    this.timeAgo = '00시간 전',
    required this.title,
    required this.content,
    this.imageUrls = const [],
    this.likeCount = 0,
    this.commentCount = 0,
    this.bookmarkCount = 0,
    this.isLiked = false,
    this.isBookmarked = false,
  });
}

/// 커뮤니티 게시글 카드 위젯 - Figma design 138:5284
class PostCard extends StatefulWidget {
  const PostCard({
    super.key,
    required this.data,
    this.onTap,
    this.onLikeTap,
    this.onCommentTap,
    this.onBookmarkTap,
    this.onMoreTap,
  });

  final PostData data;
  final VoidCallback? onTap;
  final VoidCallback? onLikeTap;
  final VoidCallback? onCommentTap;
  final VoidCallback? onBookmarkTap;
  final VoidCallback? onMoreTap;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Header
          _buildAuthorHeader(),
          const SizedBox(height: 16),

          // Content Section
          _buildContentSection(),

          // Divider
          Container(
            height: 1,
            color: AppColors.borderLight,
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Profile Image
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE8EBF0),
            ),
            child: widget.data.authorImageUrl != null
                ? ClipOval(
                    child: Image.network(
                      widget.data.authorImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholderAvatar(),
                    ),
                  )
                : _buildPlaceholderAvatar(),
          ),
          const SizedBox(width: 13),

          // Author Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.data.authorName,
                  style: AppTextStyles.bodyMediumMedium.copyWith(
                    color: AppColors.textSubtle,
                    fontSize: 16,
                    height: 24 / 16,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  widget.data.timeAgo,
                  style: AppTextStyles.captionRegular.copyWith(
                    color: AppColors.textHint,
                    fontSize: 12,
                    height: 18 / 12,
                    letterSpacing: -0.25,
                  ),
                ),
              ],
            ),
          ),

          // More Button
          GestureDetector(
            onTap: widget.onMoreTap,
            child: Transform.rotate(
              angle: 1.5708, // 90 degrees
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.more_horiz,
                  size: 24,
                  color: AppColors.textMain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderAvatar() {
    return const Center(
      child: Icon(Icons.person, size: 18, color: AppColors.textHint),
    );
  }

  Widget _buildContentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image Carousel (if images exist)
        if (widget.data.imageUrls.isNotEmpty) ...[
          _buildImageCarousel(),
          const SizedBox(height: 16),
        ],

        // Title & Content
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.data.title,
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.textMain,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  height: 26 / 18,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.data.content,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textMain,
                  fontSize: 16,
                  height: 24 / 16,
                  letterSpacing: -0.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // Interaction Bar
        _buildInteractionBar(),
      ],
    );
  }

  Widget _buildImageCarousel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        children: [
          // Image Carousel
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 343,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentImageIndex = index;
                  });
                },
                itemCount: widget.data.imageUrls.length,
                itemBuilder: (context, index) {
                  return Image.network(
                    widget.data.imageUrls[index],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.backgroundApp,
                      child: const Center(
                        child: Icon(Icons.image, size: 40, color: AppColors.textHint),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Gradient Overlay (bottom)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),

          // Pagination Dots
          if (widget.data.imageUrls.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.data.imageUrls.length, (index) {
                  final isActive = index == _currentImageIndex;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: isActive ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.5),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInteractionBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          // Like Button
          _buildInteractionButton(
            icon: widget.data.isLiked ? Icons.favorite : Icons.favorite_border,
            iconColor: widget.data.isLiked ? const Color(0xFFFE5839) : AppColors.textSubtle,
            count: widget.data.likeCount,
            onTap: widget.onLikeTap,
          ),

          // Comment Button
          _buildInteractionButton(
            icon: Icons.chat_bubble_outline,
            iconColor: AppColors.textSubtle,
            count: widget.data.commentCount,
            onTap: widget.onCommentTap,
          ),

          const Spacer(),

          // Bookmark Button
          _buildInteractionButton(
            icon: widget.data.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            iconColor: AppColors.textSubtle,
            count: widget.data.bookmarkCount,
            onTap: widget.onBookmarkTap,
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionButton({
    required IconData icon,
    required Color iconColor,
    required int count,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: iconColor,
            ),
            const SizedBox(width: 8),
            Text(
              count.toString(),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSubtle,
                fontSize: 16,
                height: 24 / 16,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
