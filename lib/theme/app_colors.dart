import 'package:flutter/material.dart';

/// 우물(Oomool) 앱 컬러 시스템
///
/// 디자인 가이드 기반 색상 정의
class AppColors {
  AppColors._();

  // ============================================
  // Brand Colors
  // ============================================

  /// Primary Brand Color - 버튼 배경, 선택 상태
  static const Color brand = Color(0xFF0165FE);

  /// Secondary Brand Color - Chips Secondary
  static const Color secondary = Color(0xFFEB6821);

  // ============================================
  // Text Colors
  // ============================================

  /// Main Text Color
  static const Color textMain = Color(0xFF212529);

  /// Inverse Text Color (Filled Button Text)
  static const Color textInverse = Color(0xFFFFFFFF);

  /// Subtle Text Color
  static const Color textSubtle = Color(0xFF6C757D);

  /// Hint/Placeholder Text Color
  static const Color textHint = Color(0xFF9CA5AE);

  // ============================================
  // Background Colors
  // ============================================

  /// App Background
  static const Color backgroundApp = Color(0xFFF9FAFC);

  /// Card/Surface Background
  static const Color backgroundSurface = Color(0xFFFFFFFF);

  /// Disabled Background
  static const Color backgroundDisabled = Color(0xFFE8EBF0);

  // ============================================
  // Border Colors
  // ============================================

  /// Default Border Color
  static const Color border = Color(0xFFCCD3D9);

  /// Light Border Color
  static const Color borderLight = Color(0xFFE8EBF0);

  // ============================================
  // Semantic Colors
  // ============================================

  /// 비활성 일요일/에러 라이트 색상
  static const Color sundayLight = Color(0xFFFF9F8D);

  /// Error Color
  static const Color error = Color(0xFFE72A07);

  /// Success Color
  static const Color success = Color(0xFF049149);

  /// Warning Color
  static const Color warning = Color(0xFFFFAA00);

  /// Info Color
  static const Color info = Color(0xFF0165FE);

  // ============================================
  // Disabled State Colors
  // ============================================

  /// Disabled Background
  static const Color disabled = Color(0xFFE8EBF0);

  /// Disabled Text/Icon
  static const Color disabledText = Color(0xFF9CA5AE);

  // ============================================
  // Chip Colors
  // ============================================

  /// Primary Chip Background (Blue50)
  static const Color chipPrimaryBg = Color(0xFFEDF8FF);

  /// Primary Chip Text
  static const Color chipPrimaryText = Color(0xFF0165FE);

  /// Secondary Chip Background (Orange50)
  static const Color chipSecondaryBg = Color(0xFFFFF1E6);

  /// Secondary Chip Text
  static const Color chipSecondaryText = Color(0xFFEB6821);

  /// Orange 50 (치료항 배경)
  static const Color orange50 = Color(0xFFFFF1E6);

  /// Orange 500 (치료항 텍스트)
  static const Color orange500 = Color(0xFFFE8A24);

  /// Orange 700 (치료항 D-day)
  static const Color orange700 = Color(0xFFD94C00);

  /// Blue 50 (담수항 배경)
  static const Color blue50 = Color(0xFFEDF8FF);

  /// Success Chip Background (Success100)
  static const Color chipSuccessBg = Color(0xFFD7FFE9);

  /// Success Chip Text
  static const Color chipSuccessText = Color(0xFF049149);

  /// Error Chip Background (Error50)
  static const Color chipErrorBg = Color(0xFFFFEAE6);

  /// Error Chip Text
  static const Color chipErrorText = Color(0xFFE72A07);

  /// Disabled Chip Background
  static const Color chipDisabledBg = Color(0xFFF9FAFC);

  /// Disabled Chip Text
  static const Color chipDisabledText = Color(0xFF9CA5AE);

  /// Disabled Chip Border
  static const Color chipDisabledBorder = Color(0xFFE8EBF0);

  // ============================================
  // Switch Colors
  // ============================================

  /// Active Switch Track
  static const Color switchActiveTrack = Color(0xFF0165FE);

  /// Inactive Switch Track
  static const Color switchInactiveTrack = Color(0xFFE8EBF0);

  // ============================================
  // Overlay Colors
  // ============================================

  /// Button Pressed Overlay
  static const Color pressedOverlay = Color(0x1A000000);

  /// Hover Overlay
  static const Color hoverOverlay = Color(0x0A000000);

  /// Shadow Color
  static const Color shadow = Color(0x0D000000);
}
