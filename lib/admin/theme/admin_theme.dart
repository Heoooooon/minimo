import 'package:flutter/material.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_spacing.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';

/// 관리자 패널 전용 테마
///
/// 사이드바 친화적인 다크 팔레트 + Material 3 기반
class AdminTheme {
  AdminTheme._();

  // 사이드바 색상
  static const Color sidebarBg = AppColors.slate800;
  static const Color sidebarText = AppColors.slate300;
  static const Color sidebarActiveText = Colors.white;
  static const Color sidebarActiveBg = AppColors.slate700;

  // 레이아웃 색상
  static const Color headerBg = AppColors.backgroundSurface;
  static const Color contentBg = AppColors.gray100;

  /// 라이트 테마
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: AppColors.brand,
        secondary: AppColors.secondary,
        error: AppColors.error,
        surface: AppColors.backgroundSurface,
        onPrimary: AppColors.textInverse,
        onSecondary: AppColors.textInverse,
        onSurface: AppColors.textMain,
        onError: AppColors.textInverse,
        outline: AppColors.border,
      ),

      // Scaffold Background
      scaffoldBackgroundColor: contentBg,

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: headerBg,
        foregroundColor: AppColors.textMain,
        elevation: 0,
        titleTextStyle: AppTextStyles.headlineMedium,
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,
        displaySmall: AppTextStyles.displaySmall,
        headlineLarge: AppTextStyles.headlineLarge,
        headlineMedium: AppTextStyles.headlineMedium,
        headlineSmall: AppTextStyles.headlineSmall,
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        titleSmall: AppTextStyles.titleSmall,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge,
        labelMedium: AppTextStyles.labelMedium,
        labelSmall: AppTextStyles.labelSmall,
      ),

      // Card Theme
      cardTheme: const CardThemeData(
        color: AppColors.backgroundSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdBorderRadius,
          side: BorderSide(color: AppColors.borderLight),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundSurface,
        border: OutlineInputBorder(
          borderRadius: AppRadius.smBorderRadius,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.smBorderRadius,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.smBorderRadius,
          borderSide: const BorderSide(color: AppColors.brand, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),

      // DataTable Theme
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(AppColors.slate50),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) return AppColors.gray100;
          return AppColors.backgroundSurface;
        }),
        headingTextStyle: AppTextStyles.labelLarge.copyWith(color: AppColors.textSubtle),
        dataTextStyle: AppTextStyles.bodySmall,
      ),
    );
  }
}
