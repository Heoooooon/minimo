import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';
import 'package:cmore_design_system/theme/app_spacing.dart';

/// 팁 일러스트 타입
enum TipIllustrationType {
  equipment,
  feeding,
}

/// 꿀팁 데이터 모델
class TipData {
  final String id;
  final String title;
  final String description;
  final TipIllustrationType illustrationType;

  const TipData({
    required this.id,
    required this.title,
    required this.description,
    this.illustrationType = TipIllustrationType.equipment,
  });
}

/// 꿀팁 카드 위젯 - Figma design 10:747, 10:748
///
/// 오늘의 사육 꿀팁 섹션에서 표시되는 카드
class TipCard extends StatelessWidget {
  const TipCard({
    super.key,
    required this.data,
    this.onTap,
    this.isFirst = true,
  });

  final TipData data;
  final VoidCallback? onTap;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 134,
        decoration: BoxDecoration(
          color: AppColors.backgroundSurface,
          borderRadius: BorderRadius.circular(isFirst ? AppRadius.md : AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            // Content (left side)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title (2 lines)
                  SizedBox(
                    width: 200,
                    child: Text(
                      data.title,
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.textMain,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        height: 26 / 18,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Description (2 lines)
                  SizedBox(
                    width: 220,
                    child: Text(
                      data.description,
                      style: AppTextStyles.captionRegular.copyWith(
                        color: AppColors.textSubtle,
                        fontSize: 12,
                        height: 18 / 12,
                        letterSpacing: -0.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Illustration (right side)
            Positioned(
              right: isFirst ? 0 : -4,
              top: isFirst ? 9 : 0,
              child: _buildIllustration(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration() {
    final size = isFirst ? 120.0 : 140.0;
    final assetPath = data.illustrationType == TipIllustrationType.equipment
        ? 'assets/images/tip_equipment.svg'
        : 'assets/images/tip_feeding.svg';

    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.asset(
        assetPath,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => _buildPlaceholderIllustration(),
      ),
    );
  }

  Widget _buildPlaceholderIllustration() {
    // Fallback decorative element
    final color = data.illustrationType == TipIllustrationType.equipment
        ? AppColors.brand
        : AppColors.error;

    return Opacity(
      opacity: 0.15,
      child: Icon(
        data.illustrationType == TipIllustrationType.equipment
            ? Icons.settings
            : Icons.restaurant,
        size: isFirst ? 100 : 120,
        color: color,
      ),
    );
  }
}

/// 꿀팁 리스트 위젯 (가로 스크롤)
class TipList extends StatelessWidget {
  const TipList({super.key, required this.tips, this.onTipTap});

  final List<TipData> tips;
  final void Function(TipData)? onTipTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 134,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16, right: 16),
        itemCount: tips.length,
        itemBuilder: (context, index) {
          final tip = tips[index];
          return Padding(
            padding: EdgeInsets.only(right: index < tips.length - 1 ? 11 : 0),
            child: TipCardHorizontal(
              data: tip,
              onTap: () => onTipTap?.call(tip),
            ),
          );
        },
      ),
    );
  }
}

/// 가로 스크롤용 꿀팁 카드 위젯
class TipCardHorizontal extends StatelessWidget {
  const TipCardHorizontal({
    super.key,
    required this.data,
    this.onTap,
  });

  final TipData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        height: 134,
        decoration: BoxDecoration(
          color: AppColors.backgroundSurface,
          borderRadius: AppRadius.mdBorderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            // Content (left side)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title (2 lines)
                  SizedBox(
                    width: 160,
                    child: Text(
                      data.title,
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.textMain,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        height: 26 / 18,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Description (2 lines)
                  SizedBox(
                    width: 180,
                    child: Text(
                      data.description,
                      style: AppTextStyles.captionRegular.copyWith(
                        color: AppColors.textSubtle,
                        fontSize: 12,
                        height: 18 / 12,
                        letterSpacing: -0.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Illustration (right side)
            Positioned(
              right: 0,
              top: 9,
              child: _buildIllustration(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration() {
    final assetPath = data.illustrationType == TipIllustrationType.equipment
        ? 'assets/images/tip_equipment.svg'
        : 'assets/images/tip_feeding.svg';

    return SizedBox(
      width: 100,
      height: 100,
      child: SvgPicture.asset(
        assetPath,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => _buildPlaceholderIllustration(),
      ),
    );
  }

  Widget _buildPlaceholderIllustration() {
    final color = data.illustrationType == TipIllustrationType.equipment
        ? AppColors.brand
        : AppColors.error;

    return Opacity(
      opacity: 0.15,
      child: Icon(
        data.illustrationType == TipIllustrationType.equipment
            ? Icons.settings
            : Icons.restaurant,
        size: 80,
        color: color,
      ),
    );
  }
}
