import 'package:flutter/material.dart';
import '../../../theme/app_text_styles.dart';

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
/// Figma 디자인: 20px radius, subtle shadow, tag chips, pill buttons
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              data.title,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Content
            Text(
              data.content,
              style: AppTextStyles.bodySmall.copyWith(
                color: const Color(0xFF666666),
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Tags
            if (data.tags.isNotEmpty) ...[
              _buildTags(),
              const SizedBox(height: 12),
            ],

            // Meta Info
            Row(
              children: [
                Icon(
                  Icons.visibility_outlined,
                  size: 14,
                  color: const Color(0xFF999999),
                ),
                const SizedBox(width: 4),
                Text(
                  '조회수 ${data.viewCount}',
                  style: AppTextStyles.captionRegular.copyWith(
                    color: const Color(0xFF999999),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  data.timeAgo,
                  style: AppTextStyles.captionRegular.copyWith(
                    color: const Color(0xFF999999),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTags() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: data.tags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F6FF),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '#$tag',
            style: AppTextStyles.captionMedium.copyWith(
              color: const Color(0xFF0066FF),
            ),
          ),
        );
      }).toList(),
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
              height: 44,
              decoration: BoxDecoration(
                color: data.isCurious ? const Color(0xFF0066FF) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFF0066FF), width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    data.isCurious ? Icons.favorite : Icons.favorite_border,
                    size: 18,
                    color: data.isCurious
                        ? Colors.white
                        : const Color(0xFF0066FF),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '궁금해요${data.curiousCount > 0 ? ' ${data.curiousCount}' : ''}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: data.isCurious
                          ? Colors.white
                          : const Color(0xFF0066FF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // 답변하기 Button (Filled / Pill)
        Expanded(
          child: GestureDetector(
            onTap: onAnswerTap,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF0066FF),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '답변하기',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
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
