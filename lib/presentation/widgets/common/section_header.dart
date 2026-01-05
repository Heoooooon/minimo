import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// 섹션 헤더 위젯
///
/// 섹션 제목과 "더보기 >" 링크를 표시
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.onMoreTap,
    this.showMore = true,
    this.moreText = '더보기',
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  });

  /// 섹션 제목
  final String title;

  /// 더보기 탭 콜백
  final VoidCallback? onMoreTap;

  /// 더보기 표시 여부
  final bool showMore;

  /// 더보기 텍스트
  final String moreText;

  /// 패딩
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.titleMedium),
          if (showMore)
            GestureDetector(
              onTap: onMoreTap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    moreText,
                    style: AppTextStyles.captionRegular.copyWith(
                      color: AppColors.textSubtle,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: AppColors.textSubtle,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
