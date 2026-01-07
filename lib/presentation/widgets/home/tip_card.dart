import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

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
          color: const Color(0xFFFDFDFF),
          borderRadius: BorderRadius.circular(isFirst ? 12 : 16),
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
        ? 'assets/images/tip_equipment.png'
        : 'assets/images/tip_feeding.png';

    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildPlaceholderIllustration(),
      ),
    );
  }

  Widget _buildPlaceholderIllustration() {
    // Fallback decorative element
    final color = data.illustrationType == TipIllustrationType.equipment
        ? const Color(0xFF0066FF)
        : const Color(0xFFFF6B6B);

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

/// 꿀팁 리스트 위젯
class TipList extends StatelessWidget {
  const TipList({super.key, required this.tips, this.onTipTap});

  final List<TipData> tips;
  final void Function(TipData)? onTipTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: tips.asMap().entries.map((entry) {
        final index = entry.key;
        final tip = entry.value;
        return Padding(
          padding: EdgeInsets.only(bottom: index < tips.length - 1 ? 11 : 0),
          child: TipCard(
            data: tip,
            isFirst: index == 0,
            onTap: () => onTipTap?.call(tip),
          ),
        );
      }).toList(),
    );
  }
}
