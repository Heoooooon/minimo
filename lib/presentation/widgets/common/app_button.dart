import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// 버튼 크기 열거형
enum AppButtonSize {
  /// Small: Height 32px, Text Caption M (12px)
  small,

  /// Medium: Height 40px, Text Body M Medium (16px)
  medium,

  /// Large: Height 56px, Text Body M Medium (16px)
  large,
}

/// 버튼 모양 열거형
enum AppButtonShape {
  /// Square: Border Radius 8px
  square,

  /// Round: StadiumBorder (완전 둥근 모서리)
  round,
}

/// 버튼 변형 열거형
enum AppButtonVariant {
  /// Contained: 채워진 배경
  contained,

  /// Outlined: 테두리만 있는
  outlined,

  /// Text: 텍스트만 있는
  text,
}

/// 우물(Oomool) 앱 커스텀 버튼 위젯
///
/// 디자인 가이드에 맞춘 버튼 컴포넌트
/// - size: small (32px), medium (40px), large (56px)
/// - shape: square (radius 8px), round (stadium)
/// - variant: contained, outlined, text
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.size = AppButtonSize.medium,
    this.shape = AppButtonShape.square,
    this.variant = AppButtonVariant.contained,
    this.isEnabled = true,
    this.isLoading = false,
    this.leadingIcon,
    this.trailingIcon,
    this.width,
    this.expanded = false,
  });

  /// 버튼 텍스트
  final String text;

  /// 클릭 콜백
  final VoidCallback? onPressed;

  /// 버튼 크기
  final AppButtonSize size;

  /// 버튼 모양
  final AppButtonShape shape;

  /// 버튼 변형
  final AppButtonVariant variant;

  /// 활성화 상태
  final bool isEnabled;

  /// 로딩 상태
  final bool isLoading;

  /// 텍스트 앞 아이콘
  final IconData? leadingIcon;

  /// 텍스트 뒤 아이콘
  final IconData? trailingIcon;

  /// 고정 너비 (null이면 컨텐츠에 맞춤)
  final double? width;

  /// 전체 너비 확장
  final bool expanded;

  /// 버튼 높이 계산
  double get _height {
    switch (size) {
      case AppButtonSize.small:
        return 32;
      case AppButtonSize.medium:
        return 40;
      case AppButtonSize.large:
        return 56;
    }
  }

  /// 버튼 수평 패딩 계산
  EdgeInsets get _padding {
    switch (size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12);
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 16);
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 24);
    }
  }

  /// 텍스트 스타일 계산
  TextStyle get _textStyle {
    switch (size) {
      case AppButtonSize.small:
        return AppTextStyles.buttonSmall;
      case AppButtonSize.medium:
      case AppButtonSize.large:
        return AppTextStyles.buttonLarge;
    }
  }

  /// 아이콘 크기 계산
  double get _iconSize {
    switch (size) {
      case AppButtonSize.small:
        return 16;
      case AppButtonSize.medium:
        return 18;
      case AppButtonSize.large:
        return 20;
    }
  }

  /// 로딩 인디케이터 크기
  double get _loadingSize {
    switch (size) {
      case AppButtonSize.small:
        return 14;
      case AppButtonSize.medium:
        return 18;
      case AppButtonSize.large:
        return 22;
    }
  }

  /// Border Radius 계산
  BorderRadius get _borderRadius {
    switch (shape) {
      case AppButtonShape.square:
        return BorderRadius.circular(8);
      case AppButtonShape.round:
        return BorderRadius.circular(_height / 2);
    }
  }

  /// 텍스트 색상 계산
  Color _getTextColor(bool enabled) {
    if (!enabled) {
      return AppColors.disabledText;
    }

    switch (variant) {
      case AppButtonVariant.contained:
        return AppColors.textInverse;
      case AppButtonVariant.outlined:
      case AppButtonVariant.text:
        return AppColors.brand;
    }
  }

  /// 배경색 계산
  Color _getBackgroundColor(bool enabled) {
    if (!enabled) {
      return variant == AppButtonVariant.text
          ? Colors.transparent
          : AppColors.disabled;
    }

    switch (variant) {
      case AppButtonVariant.contained:
        return AppColors.brand;
      case AppButtonVariant.outlined:
      case AppButtonVariant.text:
        return Colors.transparent;
    }
  }

  /// 테두리 계산
  BorderSide? _getBorderSide(bool enabled) {
    if (variant != AppButtonVariant.outlined) {
      return null;
    }

    if (!enabled) {
      return const BorderSide(color: AppColors.disabled, width: 1);
    }

    return const BorderSide(color: AppColors.brand, width: 1);
  }

  @override
  Widget build(BuildContext context) {
    final bool effectiveEnabled = isEnabled && !isLoading;
    final Color textColor = _getTextColor(effectiveEnabled);
    final Color backgroundColor = _getBackgroundColor(effectiveEnabled);
    final BorderSide? borderSide = _getBorderSide(effectiveEnabled);

    Widget buttonContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: _loadingSize,
            height: _loadingSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          ),
          const SizedBox(width: 8),
        ] else if (leadingIcon != null) ...[
          Icon(leadingIcon, size: _iconSize, color: textColor),
          const SizedBox(width: 8),
        ],
        Text(text, style: _textStyle.copyWith(color: textColor)),
        if (trailingIcon != null && !isLoading) ...[
          const SizedBox(width: 8),
          Icon(trailingIcon, size: _iconSize, color: textColor),
        ],
      ],
    );

    Widget button = Material(
      color: backgroundColor,
      borderRadius: _borderRadius,
      child: InkWell(
        onTap: effectiveEnabled ? onPressed : null,
        borderRadius: _borderRadius,
        splashColor: variant == AppButtonVariant.contained
            ? AppColors.pressedOverlay
            : AppColors.brand.withValues(alpha: 0.1),
        highlightColor: variant == AppButtonVariant.contained
            ? AppColors.pressedOverlay
            : AppColors.brand.withValues(alpha: 0.05),
        child: Container(
          height: _height,
          padding: _padding,
          decoration: BoxDecoration(
            borderRadius: _borderRadius,
            border: borderSide != null
                ? Border.fromBorderSide(borderSide)
                : null,
          ),
          child: buttonContent,
        ),
      ),
    );

    if (expanded) {
      return SizedBox(width: double.infinity, child: button);
    }

    if (width != null) {
      return SizedBox(width: width, child: button);
    }

    return button;
  }
}

/// 확장된 팩토리 생성자들
extension AppButtonFactories on AppButton {
  /// Large Square Contained 버튼 팩토리
  static AppButton largePrimary({
    required String text,
    required VoidCallback? onPressed,
    bool isEnabled = true,
    bool isLoading = false,
    IconData? leadingIcon,
    IconData? trailingIcon,
    bool expanded = false,
  }) {
    return AppButton(
      text: text,
      onPressed: onPressed,
      size: AppButtonSize.large,
      shape: AppButtonShape.square,
      variant: AppButtonVariant.contained,
      isEnabled: isEnabled,
      isLoading: isLoading,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      expanded: expanded,
    );
  }

  /// Medium Round Contained 버튼 팩토리
  static AppButton mediumRound({
    required String text,
    required VoidCallback? onPressed,
    bool isEnabled = true,
    bool isLoading = false,
    IconData? leadingIcon,
    IconData? trailingIcon,
    bool expanded = false,
  }) {
    return AppButton(
      text: text,
      onPressed: onPressed,
      size: AppButtonSize.medium,
      shape: AppButtonShape.round,
      variant: AppButtonVariant.contained,
      isEnabled: isEnabled,
      isLoading: isLoading,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      expanded: expanded,
    );
  }

  /// Small Outlined 버튼 팩토리
  static AppButton smallOutlined({
    required String text,
    required VoidCallback? onPressed,
    bool isEnabled = true,
    IconData? leadingIcon,
    IconData? trailingIcon,
  }) {
    return AppButton(
      text: text,
      onPressed: onPressed,
      size: AppButtonSize.small,
      shape: AppButtonShape.square,
      variant: AppButtonVariant.outlined,
      isEnabled: isEnabled,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
    );
  }
}
