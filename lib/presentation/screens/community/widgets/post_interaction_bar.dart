import 'package:flutter/material.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';
import '../../../widgets/community/post_card.dart';

/// 게시글 상호작용 바 (좋아요, 댓글, 북마크)
class PostInteractionBar extends StatelessWidget {
  final PostData post;
  final VoidCallback onLikeTap;
  final VoidCallback onCommentTap;
  final VoidCallback onBookmarkTap;

  const PostInteractionBar({
    super.key,
    required this.post,
    required this.onLikeTap,
    required this.onCommentTap,
    required this.onBookmarkTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          // 좋아요 버튼
          _buildInteractionButton(
            icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
            iconColor: post.isLiked
                ? const Color(0xFFFE5839)
                : AppColors.textSubtle,
            count: post.likeCount,
            onTap: onLikeTap,
          ),

          // 댓글 버튼
          _buildInteractionButton(
            icon: Icons.chat_bubble_outline,
            iconColor: AppColors.textSubtle,
            count: post.commentCount,
            onTap: onCommentTap,
          ),

          const Spacer(),

          // 북마크 버튼
          _buildInteractionButton(
            icon: post.isBookmarked
                ? Icons.bookmark
                : Icons.bookmark_border,
            iconColor: AppColors.textSubtle,
            count: post.bookmarkCount,
            onTap: onBookmarkTap,
          ),
        ],
      ),
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
}
