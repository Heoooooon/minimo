import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';
import 'package:cmore_design_system/theme/app_spacing.dart';

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

/// Q&A 카드 위젯 - Figma design 10:742
///
/// 답변을 기다리고 있어요 섹션에서 표시되는 카드
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
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.lg),
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
            // Author Row with Minimo Icon
            _buildAuthorRow(),
            const SizedBox(height: 12),

            // Title
            _buildTitle(),
            const SizedBox(height: 8),

            // Content
            _buildContent(),
            const SizedBox(height: 8),

            // Tags
            if (data.tags.isNotEmpty) ...[
              _buildTags(),
              const SizedBox(height: 8),
            ],

            // Meta Info (view count + time)
            _buildMetaInfo(),
            const SizedBox(height: 12),

            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorRow() {
    return Row(
      children: [
        // Minimo Character Icon with gradient background
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgBorderRadius,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFD6EEFF), // background/brand/subtle
                Color(0xFF83D5FF), // blue/300
              ],
            ),
          ),
          child: Center(
            child: SvgPicture.asset(
              'assets/images/minimo_icon.svg',
              width: 22,
              height: 18,
              placeholderBuilder: (_) => const Icon(
                Icons.pets,
                size: 16,
                color: AppColors.brand,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Author Name
        Text(
          data.authorName,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSubtle,
            fontSize: 14,
            height: 20 / 14,
            letterSpacing: -0.25,
          ),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Text(
      data.title,
      style: AppTextStyles.bodyMediumBold.copyWith(
        color: AppColors.textMain,
        fontSize: 16,
        height: 24 / 16,
        letterSpacing: -0.5,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildContent() {
    return Text(
      data.content,
      style: AppTextStyles.bodySmall.copyWith(
        color: AppColors.textSubtle,
        fontSize: 14,
        height: 20 / 14,
        letterSpacing: -0.25,
      ),
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildTags() {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: data.tags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.blue50,
            borderRadius: AppRadius.xsBorderRadius,
          ),
          child: Text(
            tag,
            style: AppTextStyles.captionMedium.copyWith(
              color: AppColors.brand,
              fontSize: 12,
              height: 18 / 12,
              letterSpacing: -0.25,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMetaInfo() {
    return Row(
      children: [
        // View Count
        Expanded(
          child: Row(
            children: [
              Text(
                '조회수',
                style: AppTextStyles.captionRegular.copyWith(
                  color: AppColors.textHint,
                  fontSize: 12,
                  height: 18 / 12,
                  letterSpacing: -0.25,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                data.viewCount.toString(),
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

        // Time
        Row(
          children: [
            Text(
              data.timeAgo.replaceAll('시간 전', ''),
              style: AppTextStyles.captionRegular.copyWith(
                color: AppColors.textHint,
                fontSize: 12,
                height: 18 / 12,
                letterSpacing: -0.25,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              '시간 전',
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

  Widget _buildActionButtons() {
    return Row(
      children: [
        // 궁금해요 Button (Outlined / Pill)
        Expanded(
          child: GestureDetector(
            onTap: onCuriousTap,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: data.isCurious ? AppColors.brand : AppColors.backgroundSurface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppColors.brand,
                  width: 1.071,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    data.isCurious ? Icons.favorite : Icons.favorite_border,
                    size: 16,
                    color: data.isCurious ? AppColors.textInverse : AppColors.brand,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '궁금해요',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: data.isCurious ? AppColors.textInverse : AppColors.brand,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      height: 20 / 14,
                      letterSpacing: -0.25,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // 답변하기 Button (Filled / Pill)
        Expanded(
          child: GestureDetector(
            onTap: onAnswerTap,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.brand,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: AppColors.textInverse,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '답변하기',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textInverse,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      height: 20 / 14,
                      letterSpacing: -0.25,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
