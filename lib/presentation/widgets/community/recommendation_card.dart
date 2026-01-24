import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// 추천 게시글 데이터 모델
class RecommendationData {
  final String id;
  final String title;
  final String content;
  final String authorName;
  final String timeAgo;
  final String? imageUrl;

  const RecommendationData({
    required this.id,
    required this.title,
    required this.content,
    required this.authorName,
    this.timeAgo = '00분 전',
    this.imageUrl,
  });
}

/// 추천 게시글 카드 위젯 - Figma design 138:5137
///
/// 그라디언트 배경과 블러 효과가 있는 추천 콘텐츠 카드
class RecommendationCard extends StatelessWidget {
  const RecommendationCard({super.key, required this.data, this.onTap});

  final RecommendationData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 248,
        height: 260,
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
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Background Image
            if (data.imageUrl != null)
              Positioned.fill(
                child: Image.network(
                  data.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.brand.withValues(alpha: 0.6),
                          const Color(0xFF00183C).withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.brand.withValues(alpha: 0.6),
                        const Color(0xFF00183C).withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                ),
              ),

            // Gradient Overlay (Blue gradient from top)
            Positioned(
              left: -5,
              top: -28,
              child: Container(
                width: 297,
                height: 316,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF0165FE).withValues(alpha: 0.0),
                      const Color(0xFF0165FE).withValues(alpha: 0.5),
                    ],
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.title,
                          style: AppTextStyles.bodyMediumMedium.copyWith(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            height: 24 / 16,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 9),
                        Expanded(
                          child: Text(
                            data.content,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 20 / 14,
                              letterSpacing: -0.25,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 7,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Author & Time
                  Row(
                    children: [
                      Text(
                        data.authorName,
                        style: AppTextStyles.captionRegular.copyWith(
                          color: Colors.white,
                          fontSize: 12,
                          height: 18 / 12,
                          letterSpacing: -0.25,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 2,
                        height: 2,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        data.timeAgo,
                        style: AppTextStyles.captionRegular.copyWith(
                          color: Colors.white,
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

/// 추천 게시글 카드 리스트 (가로 스크롤)
class RecommendationCardList extends StatelessWidget {
  const RecommendationCardList({
    super.key,
    required this.items,
    this.onItemTap,
  });

  final List<RecommendationData> items;
  final void Function(RecommendationData)? onItemTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final item = items[index];
          return RecommendationCard(
            data: item,
            onTap: () => onItemTap?.call(item),
          );
        },
      ),
    );
  }
}
