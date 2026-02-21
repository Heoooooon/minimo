import 'package:flutter/material.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';

/// Q&A 질문 데이터 모델
class QnaQuestionData {
  final String id;
  final int rank;
  final String title;
  final String content;
  final List<String> tags;
  final int answerCount;
  final String timeAgo;
  final String? authorName;
  final String? authorImageUrl;
  final String? imageUrl;

  const QnaQuestionData({
    required this.id,
    this.rank = 0,
    required this.title,
    required this.content,
    this.tags = const [],
    this.answerCount = 0,
    this.timeAgo = '00분 전',
    this.authorName,
    this.authorImageUrl,
    this.imageUrl,
  });
}

/// Q&A 인기 질문 카드 위젯 - Figma design Q&A 탭
class QnaPopularCard extends StatelessWidget {
  const QnaPopularCard({super.key, required this.data, this.onTap});

  final QnaQuestionData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rank Number
            if (data.rank > 0)
              Container(
                width: 20,
                margin: const EdgeInsets.only(right: 8),
                child: Text(
                  '${data.rank}',
                  style: AppTextStyles.bodyMediumBold.copyWith(
                    color: AppColors.brand,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 20 / 14,
                    letterSpacing: -0.25,
                  ),
                ),
              ),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    data.title,
                    style: AppTextStyles.bodyMediumBold.copyWith(
                      color: AppColors.textMain,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 20 / 14,
                      letterSpacing: -0.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Content Preview
                  Text(
                    data.content,
                    style: AppTextStyles.captionRegular.copyWith(
                      color: AppColors.textHint,
                      fontSize: 12,
                      height: 18 / 12,
                      letterSpacing: -0.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Meta Info
                  Row(
                    children: [
                      // Answer Count
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.chipPrimaryBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '답변 ${data.answerCount}',
                          style: AppTextStyles.captionRegular.copyWith(
                            color: AppColors.brand,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 18 / 12,
                            letterSpacing: -0.25,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Time
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Q&A 답변 대기 질문 카드 위젯
class QnaWaitingCard extends StatelessWidget {
  const QnaWaitingCard({
    super.key,
    required this.data,
    this.onTap,
    this.onCuriousTap,
    this.onAnswerTap,
  });

  final QnaQuestionData data;
  final VoidCallback? onTap;
  final VoidCallback? onCuriousTap;
  final VoidCallback? onAnswerTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFDFDFF),
          borderRadius: BorderRadius.circular(12),
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
            // Question Label
            Row(
              children: [
                Text(
                  'Q.',
                  style: AppTextStyles.bodyMediumBold.copyWith(
                    color: AppColors.brand,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 24 / 16,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    data.title,
                    style: AppTextStyles.bodyMediumBold.copyWith(
                      color: AppColors.textMain,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 24 / 16,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Content
            Text(
              data.content,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSubtle,
                fontSize: 14,
                height: 20 / 14,
                letterSpacing: -0.25,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // Image Preview (if exists)
            if (data.imageUrl != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  data.imageUrl!,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Meta Row
            Row(
              children: [
                // Views
                Text(
                  '조회 ${data.answerCount}',
                  style: AppTextStyles.captionRegular.copyWith(
                    color: AppColors.textHint,
                    fontSize: 12,
                    height: 18 / 12,
                    letterSpacing: -0.25,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '답변 ${data.answerCount}',
                  style: AppTextStyles.captionRegular.copyWith(
                    color: AppColors.textHint,
                    fontSize: 12,
                    height: 18 / 12,
                    letterSpacing: -0.25,
                  ),
                ),
                const SizedBox(width: 8),
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
        ),
      ),
    );
  }
}

/// 미니모님이 커뮤니티에 질문 카드
class QnaAskCard extends StatelessWidget {
  const QnaAskCard({
    super.key,
    required this.userName,
    required this.question,
    this.onCuriousTap,
    this.onAnswerTap,
  });

  final String userName;
  final QnaQuestionData question;
  final VoidCallback? onCuriousTap;
  final VoidCallback? onAnswerTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.brand.withValues(alpha: 0.1),
            AppColors.blue50,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          RichText(
            text: TextSpan(
              style: AppTextStyles.bodyMediumBold.copyWith(
                color: AppColors.textMain,
                fontSize: 14,
                height: 20 / 14,
                letterSpacing: -0.25,
              ),
              children: [
                TextSpan(text: '$userName님이 커뮤니티에 '),
                TextSpan(
                  text:
                      '#${question.tags.isNotEmpty ? question.tags.first : '질문'}',
                  style: AppTextStyles.bodyMediumBold.copyWith(
                    color: AppColors.brand,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 20 / 14,
                    letterSpacing: -0.25,
                  ),
                ),
                const TextSpan(text: ' 질문'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Question Content
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                // Question Icon
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.chipPrimaryBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      'Q',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.brand,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Question Text
                Expanded(
                  child: Text(
                    question.title,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMain,
                      fontSize: 14,
                      height: 20 / 14,
                      letterSpacing: -0.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label: '궁금해요',
                  icon: Icons.lightbulb_outline,
                  isPrimary: false,
                  onTap: onCuriousTap,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  label: '답변하기',
                  icon: Icons.edit_outlined,
                  isPrimary: true,
                  onTap: onAnswerTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required bool isPrimary,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.brand : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: isPrimary ? null : Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isPrimary ? Colors.white : AppColors.textSubtle,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isPrimary ? Colors.white : AppColors.textSubtle,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 20 / 14,
                letterSpacing: -0.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
