import 'package:flutter/material.dart';
import '../../../domain/models/schedule_data.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';

/// 반복 주기 선택 위젯
///
/// Figma 디자인 기반: 매일 | 격일 | 매주 | 격주 | 매월 가로 배치
class RepeatCycleSelector extends StatelessWidget {
  const RepeatCycleSelector({
    super.key,
    required this.selectedCycle,
    required this.onChanged,
    this.showNone = false,
  });

  /// 선택된 반복 주기
  final RepeatCycle selectedCycle;

  /// 선택 변경 콜백
  final ValueChanged<RepeatCycle> onChanged;

  /// '반복 안함' 옵션 표시 여부
  final bool showNone;

  @override
  Widget build(BuildContext context) {
    final cycles = showNone
        ? RepeatCycle.values
        : RepeatCycle.values.where((c) => c != RepeatCycle.none).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '알림 주기',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSubtle,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: cycles.map((cycle) {
              final isSelected = selectedCycle == cycle;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _CycleChip(
                  label: cycle.label,
                  isSelected: isSelected,
                  onTap: () => onChanged(cycle),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _CycleChip extends StatelessWidget {
  const _CycleChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.chipPrimaryBg : AppColors.backgroundSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.brand : AppColors.borderLight,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isSelected ? AppColors.brand : AppColors.textSubtle,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

/// 알림 종류 드롭다운 위젯
class AlarmTypeDropdown extends StatelessWidget {
  const AlarmTypeDropdown({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  /// 선택된 알림 종류
  final AlarmType selectedType;

  /// 선택 변경 콜백
  final ValueChanged<AlarmType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '알림 종류',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSubtle,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<AlarmType>(
              value: selectedType,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              borderRadius: BorderRadius.circular(12),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.textSubtle,
              ),
              items: AlarmType.values.map((type) {
                return DropdownMenuItem<AlarmType>(
                  value: type,
                  child: Row(
                    children: [
                      Icon(
                        _getIconForType(type),
                        size: 20,
                        color: AppColors.brand,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        type.label,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  onChanged(value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  IconData _getIconForType(AlarmType type) {
    switch (type) {
      case AlarmType.waterChange:
        return Icons.water_drop_outlined;
      case AlarmType.feeding:
        return Icons.restaurant_outlined;
      case AlarmType.cleaning:
        return Icons.cleaning_services_outlined;
      case AlarmType.waterTest:
        return Icons.science_outlined;
      case AlarmType.medication:
        return Icons.medication_outlined;
      case AlarmType.other:
        return Icons.more_horiz;
    }
  }
}
