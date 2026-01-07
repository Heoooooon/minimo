import 'package:flutter/material.dart';
import '../../../theme/app_text_styles.dart';

/// 꿀팁 데이터 모델
class TipData {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color? iconBgColor;
  final Color? iconColor;

  const TipData({
    required this.id,
    required this.title,
    required this.description,
    this.icon = Icons.lightbulb_outline,
    this.iconBgColor,
    this.iconColor,
  });
}

/// 꿀팁 카드 위젯
///
/// Figma 디자인: 파스텔 배경 + 오른쪽 일러스트 스타일
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
    // 첫 번째 카드: 연한 파란색, 두 번째 카드: 연한 분홍색
    final bgColor = isFirst ? const Color(0xFFEDF8FF) : const Color(0xFFFFF0F0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        height: 100,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            // Background decorative elements (bubbles/fish)
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: _buildDecorativeElement(),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    data.title,
                    style: AppTextStyles.bodyMediumMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data.description,
                    style: AppTextStyles.captionRegular.copyWith(
                      color: const Color(0xFF666666),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecorativeElement() {
    return Opacity(
      opacity: 0.3,
      child: Icon(
        isFirst ? Icons.water_drop : Icons.restaurant,
        size: 60,
        color: isFirst ? const Color(0xFF0066FF) : const Color(0xFFFF6B6B),
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
          padding: const EdgeInsets.only(bottom: 12),
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
