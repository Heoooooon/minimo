import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// 커뮤니티 콘텐츠 데이터 모델
class CommunityData {
  final String id;
  final String authorName;
  final String? authorImageUrl;
  final String content;
  final String? imageUrl;
  final int likeCount;
  final int commentCount;
  final int bookmarkCount;
  final bool isLiked;
  final bool isBookmarked;

  const CommunityData({
    required this.id,
    required this.authorName,
    this.authorImageUrl,
    required this.content,
    this.imageUrl,
    this.likeCount = 0,
    this.commentCount = 0,
    this.bookmarkCount = 0,
    this.isLiked = false,
    this.isBookmarked = false,
  });
}

/// 커뮤니티 카드 위젯
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
  });

  final CommunityData data;
  final VoidCallback? onTap;
  final VoidCallback? onLikeTap;
  final VoidCallback? onCommentTap;
  final VoidCallback? onBookmarkTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 작성자 프로필
            _buildAuthorProfile(),
            const SizedBox(height: 12),

            // 콘텐츠 본문
            Text(
              data.content,
              style: AppTextStyles.bodySmall,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),

            // 인터랙션 버튼들
            _buildInteractionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorProfile() {
    return Row(
      children: [
        // 프로필 이미지
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.chipPrimaryBg,
          ),
          child: data.authorImageUrl != null
              ? ClipOval(
                  child: Image.network(
                    data.authorImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholderAvatar(),
                  ),
                )
              : _buildPlaceholderAvatar(),
        ),
        const SizedBox(width: 10),
        // 작성자 이름
        Text(
          data.authorName,
          style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildPlaceholderAvatar() {
    return const Icon(Icons.person, size: 20, color: AppColors.brand);
  }

  Widget _buildInteractionBar() {
    return Row(
      children: [
        // 좋아요
        _buildInteractionButton(
          icon: data.isLiked ? Icons.favorite : Icons.favorite_border,
          count: data.likeCount,
          isActive: data.isLiked,
          onTap: onLikeTap,
        ),
        const SizedBox(width: 16),
        // 댓글
        _buildInteractionButton(
          icon: Icons.chat_bubble_outline,
          count: data.commentCount,
          onTap: onCommentTap,
        ),
        const Spacer(),
        // 북마크
        GestureDetector(
          onTap: onBookmarkTap,
          child: Icon(
            data.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            size: 20,
            color: data.isBookmarked ? AppColors.brand : AppColors.textSubtle,
          ),
        ),
      ],
    );
  }

  Widget _buildInteractionButton({
    required IconData icon,
    required int count,
    bool isActive = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isActive ? AppColors.error : AppColors.textSubtle,
          ),
          const SizedBox(width: 4),
          Text(
            count.toString(),
            style: AppTextStyles.captionRegular.copyWith(
              color: AppColors.textSubtle,
            ),
          ),
        ],
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
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return CommunityCard(data: item, onTap: () => onItemTap?.call(item));
        },
      ),
    );
  }
}
