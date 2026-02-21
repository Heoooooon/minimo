import 'package:flutter/material.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';
import 'package:cmore_design_system/theme/app_spacing.dart';

/// 커뮤니티 콘텐츠 데이터 모델
class CommunityData {
  final String id;
  final String? authorId;
  final String authorName;
  final String? authorImageUrl;
  final String timeAgo;
  final String content;
  final String? imageUrl;
  final List<String> tags;
  final int likeCount;
  final int commentCount;
  final int bookmarkCount;
  final bool isLiked;
  final bool isBookmarked;

  const CommunityData({
    required this.id,
    this.authorId,
    required this.authorName,
    this.authorImageUrl,
    this.timeAgo = '00시간 전',
    required this.content,
    this.imageUrl,
    this.tags = const [],
    this.likeCount = 0,
    this.commentCount = 0,
    this.bookmarkCount = 0,
    this.isLiked = false,
    this.isBookmarked = false,
  });
}

/// 커뮤니티 카드 위젯 - Figma design 10:690
///
/// 추천 콘텐츠 섹션에서 가로 스크롤로 표시되는 카드
class CommunityCard extends StatelessWidget {
  const CommunityCard({
    super.key,
    required this.data,
    this.onTap,
    this.onLikeTap,
    this.onCommentTap,
    this.onBookmarkTap,
    this.isActive = true,
  });

  final CommunityData data;
  final VoidCallback? onTap;
  final VoidCallback? onLikeTap;
  final VoidCallback? onCommentTap;
  final VoidCallback? onBookmarkTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isActive ? 1.0 : 0.7,
        child: Container(
          width: 311,
          padding: const EdgeInsets.all(AppSpacing.lg),
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: AppColors.backgroundSurface,
            borderRadius: AppRadius.lgBorderRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author Profile Row
              _buildAuthorProfile(),
              const SizedBox(height: 13),

              // Content Text (flexible to fit remaining space)
              Expanded(child: _buildContentText()),

              // Optional Image
              if (data.imageUrl != null) ...[
                const SizedBox(height: 13),
                _buildImage(),
              ],

              const SizedBox(height: 4),

              // Interaction Bar
              _buildInteractionBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthorProfile() {
    return Row(
      children: [
        // Profile Image
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.borderLight,
          ),
          child: data.authorImageUrl != null
              ? ClipOval(
                  child: Image.network(
                    data.authorImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildPlaceholderAvatar(),
                  ),
                )
              : _buildPlaceholderAvatar(),
        ),
        const SizedBox(width: 13),

        // Author Info
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.authorName,
              style: AppTextStyles.bodyMediumBold.copyWith(
                color: AppColors.textSubtle,
                fontSize: 16,
                height: 24 / 16,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              data.timeAgo,
              style: AppTextStyles.captionRegular.copyWith(
                color: AppColors.textHint,
                fontSize: 12,
                height: 18 / 12,
                letterSpacing: -0.25,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlaceholderAvatar() {
    return const Center(
      child: Icon(Icons.person, size: 18, color: AppColors.textHint),
    );
  }

  Widget _buildContentText() {
    // Check if content has "더보기" link
    final hasMoreLink = data.content.contains('더보기');
    // Reduce maxLines when image is present to prevent overflow
    final maxLines = data.imageUrl != null ? 3 : 8;

    if (hasMoreLink) {
      final parts = data.content.split('더보기');
      return RichText(
        text: TextSpan(
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textMain,
            fontSize: 16,
            height: 24 / 16,
            letterSpacing: -0.5,
          ),
          children: [
            TextSpan(text: parts[0]),
            TextSpan(
              text: '더보기',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textHint,
                fontSize: 14,
                height: 20 / 14,
                letterSpacing: -0.25,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Text(
      data.content,
      style: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.textMain,
        fontSize: 16,
        height: 24 / 16,
        letterSpacing: -0.5,
      ),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildImage() {
    return ClipRRect(
      borderRadius: AppRadius.mdBorderRadius,
      child: Image.network(
        data.imageUrl!,
        height: 164,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 164,
          color: AppColors.backgroundApp,
          child: const Center(
            child: Icon(Icons.image, size: 40, color: AppColors.textHint),
          ),
        ),
      ),
    );
  }

  Widget _buildInteractionBar() {
    return Row(
      children: [
        // Like Box
        _buildInteractionItem(
          icon: Icons.favorite_border,
          count: data.likeCount,
          onTap: onLikeTap,
        ),

        // Comment Box
        _buildInteractionItem(
          icon: Icons.chat_bubble_outline,
          count: data.commentCount,
          onTap: onCommentTap,
        ),

        const Spacer(),

        // Bookmark Box
        _buildInteractionItem(
          icon: Icons.bookmark_border,
          count: data.bookmarkCount,
          onTap: onBookmarkTap,
        ),
      ],
    );
  }

  Widget _buildInteractionItem({
    required IconData icon,
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
            Icon(icon, size: 16, color: AppColors.textSubtle),
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

/// 커뮤니티 카드 리스트 (가로 스크롤)
class CommunityCardList extends StatelessWidget {
  const CommunityCardList({super.key, required this.items, this.onItemTap});

  final List<CommunityData> items;
  final void Function(CommunityData)? onItemTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 340,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return CommunityCard(data: item, onTap: () => onItemTap?.call(item));
        },
      ),
    );
  }
}
