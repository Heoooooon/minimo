import 'package:flutter/material.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';
import '../../../widgets/community/post_card.dart';

/// 게시글 작성자 정보 섹션
class PostAuthorSection extends StatelessWidget {
  final PostData post;
  final String? authorId;
  final String? currentUserId;
  final bool isFollowing;
  final bool isFollowLoading;
  final VoidCallback onToggleFollow;

  const PostAuthorSection({
    super.key,
    required this.post,
    required this.authorId,
    required this.currentUserId,
    required this.isFollowing,
    required this.isFollowLoading,
    required this.onToggleFollow,
  });

  @override
  Widget build(BuildContext context) {
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
              color: AppColors.gray200,
              image: post.authorImageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(post.authorImageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: post.authorImageUrl == null
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
                  post.authorName,
                  style: AppTextStyles.bodyMediumBold.copyWith(
                    color: AppColors.textMain,
                  ),
                ),
                Text(
                  post.timeAgo,
                  style: AppTextStyles.captionRegular.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),

          // 팔로우 버튼 (자기 자신이 아닌 경우에만 표시)
          if (authorId != null && authorId != currentUserId)
            TextButton(
              onPressed: isFollowLoading ? null : onToggleFollow,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                backgroundColor: isFollowing
                    ? AppColors.backgroundApp
                    : AppColors.chipPrimaryBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: isFollowing
                      ? BorderSide(color: AppColors.borderLight)
                      : BorderSide.none,
                ),
              ),
              child: isFollowLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.brand,
                      ),
                    )
                  : Text(
                      isFollowing ? '팔로잉' : '팔로우',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isFollowing
                            ? AppColors.textSubtle
                            : AppColors.brand,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}
