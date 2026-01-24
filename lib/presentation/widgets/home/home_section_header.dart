import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// 홈 화면 섹션 헤더
///
/// 타이틀과 "더보기 >" 링크를 포함한 공통 섹션 헤더
class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({
    super.key,
    required this.title,
    this.showMore = true,
    this.onMoreTap,
  });

  /// 섹션 타이틀
  final String title;

  /// "더보기" 버튼 표시 여부
  final bool showMore;

  /// "더보기" 버튼 콜백
  final VoidCallback? onMoreTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              height: 26 / 18,
              letterSpacing: -0.5,
              color: AppColors.textMain,
            ),
          ),
          if (showMore)
            GestureDetector(
              onTap: onMoreTap,
              child: Row(
                children: [
                  Text(
                    '더보기',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.brand,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      height: 20 / 14,
                      letterSpacing: -0.25,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Transform.rotate(
                    angle: 3.14159, // 180 degrees
                    child: const Icon(
                      Icons.keyboard_arrow_left,
                      size: 16,
                      color: AppColors.brand,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
