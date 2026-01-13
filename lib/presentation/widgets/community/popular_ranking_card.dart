import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// 인기글 랭킹 데이터 모델
class PopularRankingData {
  final int rank;
  final String title;
  final String id;

  const PopularRankingData({
    required this.rank,
    required this.title,
    required this.id,
  });
}

/// 인기글 랭킹 카드 위젯 - Figma design 138:5255
class PopularRankingCard extends StatelessWidget {
  const PopularRankingCard({
    super.key,
    required this.data,
    this.onTap,
  });

  final PopularRankingData data;
  final VoidCallback? onTap;

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
        child: Row(
          children: [
            // Rank Number
            SizedBox(
              width: 24,
              child: Text(
                '${data.rank}.',
                style: AppTextStyles.bodyMediumMedium.copyWith(
                  color: AppColors.brand,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 24 / 16,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Title
            Expanded(
              child: Text(
                data.title,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textMain,
                  fontSize: 16,
                  height: 24 / 16,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
