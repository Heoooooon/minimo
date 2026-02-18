import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// 설정 화면 행 위젯
///
/// 설정 항목을 표시하는 재사용 가능한 행 위젯
/// 좌측 텍스트 + 우측 chevron 아이콘 구성
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.title,
    this.onTap,
    this.trailing,
    this.showChevron = true,
    this.showDivider = true,
    this.titleStyle,
    this.titleColor,
  });

  /// 항목 제목
  final String title;

  /// 탭 콜백
  final VoidCallback? onTap;

  /// 우측 커스텀 위젯 (chevron 대신 표시)
  final Widget? trailing;

  /// chevron 아이콘 표시 여부
  final bool showChevron;

  /// 하단 구분선 표시 여부
  final bool showDivider;

  /// 커스텀 제목 스타일
  final TextStyle? titleStyle;

  /// 커스텀 제목 색상
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style:
                      titleStyle ??
                      AppTextStyles.bodyLarge.copyWith(
                        color: titleColor ?? AppColors.textMain,
                      ),
                ),
                if (trailing != null)
                  trailing!
                else if (showChevron)
                  const Icon(
                    Icons.chevron_right,
                    size: 24,
                    color: AppColors.textHint,
                  ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 1,
            indent: 20,
            endIndent: 20,
            color: AppColors.borderLight,
          ),
      ],
    );
  }
}

/// 설정 섹션 헤더 위젯
///
/// 섹션 구분을 위한 작은 회색 텍스트
class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader({super.key, required this.title});

  /// 섹션 제목
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 28, bottom: 8),
      child: Text(
        title,
        style: AppTextStyles.captionMedium.copyWith(
          color: AppColors.textSubtle,
        ),
      ),
    );
  }
}
