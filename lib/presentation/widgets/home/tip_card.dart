import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
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
/// 사육 꿀팁 섹션에서 표시되는 팁 카드
class TipCard extends StatelessWidget {
  const TipCard({super.key, required this.data, this.onTap});

  final TipData data;
  final VoidCallback? onTap;

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
        ),
        child: Row(
          children: [
            // 텍스트 영역
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: AppTextStyles.bodyMediumMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.description,
                    style: AppTextStyles.captionRegular.copyWith(
                      color: AppColors.textSubtle,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // 아이콘 영역
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: data.iconBgColor ?? AppColors.chipPrimaryBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                data.icon,
                size: 28,
                color: data.iconColor ?? AppColors.brand,
              ),
            ),
          ],
        ),
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
      children: tips.map((tip) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TipCard(data: tip, onTap: () => onTipTap?.call(tip)),
        );
      }).toList(),
    );
  }
}
