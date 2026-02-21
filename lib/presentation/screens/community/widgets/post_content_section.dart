import 'package:flutter/material.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';
import '../../../widgets/community/post_card.dart';

/// 게시글 내용 섹션 (제목 + 본문 + 태그)
class PostContentSection extends StatelessWidget {
  final PostData post;
  final void Function(String tag) onTagTap;

  const PostContentSection({
    super.key,
    required this.post,
    required this.onTagTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목
          Text(
            post.title,
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textMain,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // 내용
          Text(
            post.content,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textMain,
              height: 1.6,
            ),
          ),

          // 태그
          if (post.tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: post.tags.map((tag) => _buildTagChip(tag)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    return GestureDetector(
      onTap: () => onTagTap(tag),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.chipPrimaryBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '#$tag',
          style: AppTextStyles.captionMedium.copyWith(
            color: AppColors.brand,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
