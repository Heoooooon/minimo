import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../common/app_button.dart';
import '../common/app_chip.dart';

/// Q&A 데이터 모델
class QnAData {
  final String id;
  final String authorName;
  final String? authorImageUrl;
  final String title;
  final String content;
  final List<String> tags;
  final int viewCount;
  final String timeAgo;
  final int curiousCount;
  final bool isCurious;

  const QnAData({
    required this.id,
    required this.authorName,
    this.authorImageUrl,
    required this.title,
    required this.content,
    this.tags = const [],
    this.viewCount = 0,
    required this.timeAgo,
    this.curiousCount = 0,
    this.isCurious = false,
  });
}

/// Q&A 카드 위젯
///
/// 답변 대기 섹션에서 표시되는 질문 카드
class QnACard extends StatelessWidget {
  const QnACard({
    super.key,
    required this.data,
    this.onTap,
    this.onCuriousTap,
    this.onAnswerTap,
  });

  final QnAData data;
  final VoidCallback? onTap;
  final VoidCallback? onCuriousTap;
  final VoidCallback? onAnswerTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
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
            _buildAuthorRow(),
            const SizedBox(height: 12),

            // 질문 제목
            Text(
              data.title,
              style: AppTextStyles.bodyMediumMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),

            // 질문 내용 요약
            Text(
              data.content,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSubtle,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // 태그
            if (data.tags.isNotEmpty) ...[
              _buildTags(),
              const SizedBox(height: 12),
            ],

            // 메타 정보 & 버튼
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorRow() {
    return Row(
      children: [
        // 프로필 이미지
        Container(
          width: 32,
          height: 32,
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
        const SizedBox(width: 8),
        // 작성자 이름
        Text(data.authorName, style: AppTextStyles.captionMedium),
        const Spacer(),
        // 조회수 & 시간
        Text(
          '조회 ${data.viewCount} · ${data.timeAgo}',
          style: AppTextStyles.captionRegular.copyWith(
            color: AppColors.textHint,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderAvatar() {
    return const Icon(Icons.person, size: 18, color: AppColors.brand);
  }

  Widget _buildTags() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: data.tags.map((tag) {
        return AppChip(label: tag, type: AppChipType.neutral);
      }).toList(),
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        // 궁금해요 버튼
        Expanded(
          child: AppButton(
            text: '궁금해요 ${data.curiousCount > 0 ? data.curiousCount : ''}',
            onPressed: onCuriousTap,
            size: AppButtonSize.small,
            shape: AppButtonShape.square,
            variant: data.isCurious
                ? AppButtonVariant.contained
                : AppButtonVariant.outlined,
            leadingIcon: data.isCurious
                ? Icons.favorite
                : Icons.favorite_border,
          ),
        ),
        const SizedBox(width: 8),
        // 답변하기 버튼
        Expanded(
          child: AppButton(
            text: '답변하기',
            onPressed: onAnswerTap,
            size: AppButtonSize.small,
            shape: AppButtonShape.square,
            variant: AppButtonVariant.contained,
            leadingIcon: Icons.edit_outlined,
          ),
        ),
      ],
    );
  }
}
