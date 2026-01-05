import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// 칩 타입 열거형
enum AppChipType {
  /// Primary: Blue 계열
  primary,

  /// Secondary: Orange 계열
  secondary,

  /// Success: Green 계열
  success,

  /// Error: Red 계열
  error,

  /// Neutral: Gray 계열
  neutral,
}

/// 우물(Oomool) 앱 커스텀 칩 위젯
///
/// 디자인 가이드에 맞춘 칩 컴포넌트
/// - type: primary, secondary, success, error, neutral
/// - 선택 가능 여부 지원
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.type = AppChipType.primary,
    this.isEnabled = true,
    this.isSelected = false,
    this.onTap,
    this.leadingIcon,
    this.trailingIcon,
    this.onDelete,
  });

  /// 칩 라벨 텍스트
  final String label;

  /// 칩 타입
  final AppChipType type;

  /// 활성화 상태
  final bool isEnabled;

  /// 선택 상태
  final bool isSelected;

  /// 탭 콜백
  final VoidCallback? onTap;

  /// 앞 아이콘
  final IconData? leadingIcon;

  /// 뒤 아이콘
  final IconData? trailingIcon;

  /// 삭제 콜백 (설정하면 X 버튼 표시)
  final VoidCallback? onDelete;

  /// 배경색 계산
  Color get _backgroundColor {
    if (!isEnabled) {
      return AppColors.chipDisabledBg;
    }

    switch (type) {
      case AppChipType.primary:
        return AppColors.chipPrimaryBg;
      case AppChipType.secondary:
        return AppColors.chipSecondaryBg;
      case AppChipType.success:
        return AppColors.chipSuccessBg;
      case AppChipType.error:
        return AppColors.chipErrorBg;
      case AppChipType.neutral:
        return AppColors.backgroundApp;
    }
  }

  /// 텍스트 색상 계산
  Color get _textColor {
    if (!isEnabled) {
      return AppColors.chipDisabledText;
    }

    switch (type) {
      case AppChipType.primary:
        return AppColors.chipPrimaryText;
      case AppChipType.secondary:
        return AppColors.chipSecondaryText;
      case AppChipType.success:
        return AppColors.chipSuccessText;
      case AppChipType.error:
        return AppColors.chipErrorText;
      case AppChipType.neutral:
        return AppColors.textMain;
    }
  }

  /// 테두리 색상 계산
  Color? get _borderColor {
    if (!isEnabled) {
      return AppColors.chipDisabledBorder;
    }

    if (isSelected) {
      return _textColor;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: _borderColor != null
              ? Border.all(color: _borderColor!, width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, size: 14, color: _textColor),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTextStyles.captionMedium.copyWith(color: _textColor),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 4),
              Icon(trailingIcon, size: 14, color: _textColor),
            ],
            if (onDelete != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: isEnabled ? onDelete : null,
                child: Icon(Icons.close, size: 14, color: _textColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 선택 가능한 칩 그룹 위젯
class AppChipGroup extends StatelessWidget {
  const AppChipGroup({
    super.key,
    required this.labels,
    required this.selectedIndices,
    required this.onSelectionChanged,
    this.type = AppChipType.primary,
    this.isMultiSelect = true,
    this.isEnabled = true,
    this.spacing = 8,
    this.runSpacing = 8,
  });

  /// 칩 라벨 목록
  final List<String> labels;

  /// 선택된 인덱스들
  final Set<int> selectedIndices;

  /// 선택 변경 콜백
  final ValueChanged<Set<int>> onSelectionChanged;

  /// 칩 타입
  final AppChipType type;

  /// 다중 선택 여부
  final bool isMultiSelect;

  /// 활성화 상태
  final bool isEnabled;

  /// 가로 간격
  final double spacing;

  /// 세로 간격
  final double runSpacing;

  void _handleTap(int index) {
    if (!isEnabled) return;

    final newSelection = Set<int>.from(selectedIndices);

    if (isMultiSelect) {
      if (newSelection.contains(index)) {
        newSelection.remove(index);
      } else {
        newSelection.add(index);
      }
    } else {
      if (newSelection.contains(index)) {
        newSelection.clear();
      } else {
        newSelection.clear();
        newSelection.add(index);
      }
    }

    onSelectionChanged(newSelection);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: List.generate(labels.length, (index) {
        return AppChip(
          label: labels[index],
          type: type,
          isEnabled: isEnabled,
          isSelected: selectedIndices.contains(index),
          onTap: () => _handleTap(index),
        );
      }),
    );
  }
}

/// 필터 칩 위젯 (선택 토글 버전)
class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.isEnabled = true,
  });

  /// 라벨
  final String label;

  /// 선택 상태
  final bool isSelected;

  /// 선택 콜백
  final ValueChanged<bool> onSelected;

  /// 활성화 상태
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: isEnabled ? onSelected : null,
      backgroundColor: AppColors.backgroundApp,
      selectedColor: AppColors.chipPrimaryBg,
      checkmarkColor: AppColors.brand,
      labelStyle: AppTextStyles.captionMedium.copyWith(
        color: isSelected ? AppColors.brand : AppColors.textMain,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? AppColors.brand : AppColors.border,
        ),
      ),
      showCheckmark: true,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}
