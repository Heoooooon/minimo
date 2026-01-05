import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 우물(Oomool) 앱 타이포그래피 시스템
///
/// Font Family: Wanted Sans (시스템 폴백 적용)
/// Line Height 계산: fontSize * lineHeightMultiplier
class AppTextStyles {
  AppTextStyles._();

  /// 기본 폰트 패밀리
  /// Wanted Sans가 없을 경우 시스템 폰트로 폴백
  static const String fontFamily = 'WantedSans';

  /// 폴백 폰트 패밀리 리스트
  static const List<String> fontFamilyFallback = [
    'Pretendard',
    'Apple SD Gothic Neo',
    'Noto Sans KR',
    'sans-serif',
  ];

  // ============================================
  // Display Styles (대형 제목)
  // ============================================

  /// Display Large - 32px Bold
  static TextStyle get displayLarge => const TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.25, // 40px
    letterSpacing: -0.5,
    color: AppColors.textMain,
  );

  /// Display Medium - 28px Bold
  static TextStyle get displayMedium => const TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.29, // 36px
    letterSpacing: -0.5,
    color: AppColors.textMain,
  );

  /// Display Small - 24px Bold
  static TextStyle get displaySmall => const TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.33, // 32px
    letterSpacing: -0.25,
    color: AppColors.textMain,
  );

  // ============================================
  // Headline Styles (제목)
  // ============================================

  /// Headline Large - 24px SemiBold
  static TextStyle get headlineLarge => const TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.33, // 32px
    letterSpacing: -0.25,
    color: AppColors.textMain,
  );

  /// Headline Medium - 20px SemiBold
  static TextStyle get headlineMedium => const TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4, // 28px
    letterSpacing: -0.25,
    color: AppColors.textMain,
  );

  /// Headline Small - 18px SemiBold
  static TextStyle get headlineSmall => const TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.44, // 26px
    letterSpacing: 0,
    color: AppColors.textMain,
  );

  // ============================================
  // Title Styles (소제목)
  // ============================================

  /// Title Large - 18px Medium
  static TextStyle get titleLarge => const TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.44, // 26px
    letterSpacing: 0,
    color: AppColors.textMain,
  );

  /// Title Medium - 16px Medium
  static TextStyle get titleMedium => const TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5, // 24px
    letterSpacing: 0,
    color: AppColors.textMain,
  );

  /// Title Small - 14px Medium
  static TextStyle get titleSmall => const TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.43, // 20px
    letterSpacing: 0,
    color: AppColors.textMain,
  );

  // ============================================
  // Body Styles (본문)
  // ============================================

  /// Body Large - 16px Regular
  static TextStyle get bodyLarge => const TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5, // 24px
    letterSpacing: 0,
    color: AppColors.textMain,
  );

  /// Body Medium Regular - 16px Regular (버튼 텍스트)
  static TextStyle get bodyMedium => const TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5, // 24px
    letterSpacing: 0,
    color: AppColors.textMain,
  );

  /// Body Medium Medium - 16px Medium (Large/Medium 버튼 텍스트)
  static TextStyle get bodyMediumMedium => const TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5, // 24px
    letterSpacing: 0,
    color: AppColors.textMain,
  );

  /// Body Small - 14px Regular
  static TextStyle get bodySmall => const TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.43, // 20px
    letterSpacing: 0,
    color: AppColors.textMain,
  );

  // ============================================
  // Label Styles (라벨)
  // ============================================

  /// Label Large - 14px Medium
  static TextStyle get labelLarge => const TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.43, // 20px
    letterSpacing: 0.1,
    color: AppColors.textMain,
  );

  /// Label Medium - 12px Medium
  static TextStyle get labelMedium => const TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.33, // 16px
    letterSpacing: 0.1,
    color: AppColors.textMain,
  );

  /// Label Small - 11px Medium
  static TextStyle get labelSmall => const TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.45, // 16px
    letterSpacing: 0.1,
    color: AppColors.textMain,
  );

  // ============================================
  // Caption Styles (캡션)
  // ============================================

  /// Caption Medium - 12px Medium (Small 버튼 텍스트)
  static TextStyle get captionMedium => const TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.33, // 16px
    letterSpacing: 0,
    color: AppColors.textMain,
  );

  /// Caption Regular - 12px Regular
  static TextStyle get captionRegular => const TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.33, // 16px
    letterSpacing: 0,
    color: AppColors.textMain,
  );

  // ============================================
  // Button Text Styles
  // ============================================

  /// Large/Medium Button Text - Body M Medium (16px)
  static TextStyle get buttonLarge => bodyMediumMedium;

  /// Small Button Text - Caption M (12px)
  static TextStyle get buttonSmall => captionMedium;

  // ============================================
  // Helper Methods
  // ============================================

  /// 색상 변경 헬퍼
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// 폰트 웨이트 변경 헬퍼
  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(fontWeight: weight);
  }
}
