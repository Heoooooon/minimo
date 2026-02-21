import 'package:flutter/material.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';
import 'package:cmore_design_system/widgets/empty_state.dart';
import '../../../../domain/models/comment_data.dart';

/// 댓글 섹션 (댓글 목록 표시)
class PostCommentsSection extends StatelessWidget {
  final List<CommentData> comments;
  final bool isLoading;
  final Future<void> Function(String commentId) onCommentLike;

  const PostCommentsSection({
    super.key,
    required this.comments,
    required this.isLoading,
    required this.onCommentLike,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '댓글 ${comments.length}',
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.textMain,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // 로딩 중
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: AppColors.brand),
              ),
            )
          // 댓글이 없는 경우
          else if (comments.isEmpty)
            EmptyStatePresets.noComments()
          // 댓글 목록
          else
            ...comments.map((comment) => _buildCommentItem(comment)),
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
              color: AppColors.gray200,
            ),
            child: const Icon(
              Icons.person,
              size: 18,
              color: AppColors.textHint,
            ),
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
                      onTap: () {
                        if (comment.id != null) {
                          onCommentLike(comment.id!);
                        }
                      },
                      child: Row(
                        children: [
                          const Icon(
                            Icons.favorite_border,
                            size: 16,
                            color: AppColors.textHint,
                          ),
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
