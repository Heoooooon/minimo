import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_spacing.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';

/// 섹션 라벨
class SectionLabel extends StatelessWidget {
  final String label;

  const SectionLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        label,
        style: AppTextStyles.bodyMediumBold.copyWith(
          color: AppColors.textMain,
        ),
      ),
    );
  }
}

/// 토글 버튼 그룹 (2~4개 옵션 중 택 1)
class ToggleButtonGroup extends StatelessWidget {
  final List<String> options;
  final int? selectedIndex;
  final ValueChanged<int> onSelected;

  const ToggleButtonGroup({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(options.length, (index) {
        final isSelected = selectedIndex == index;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index < options.length - 1 ? 8 : 0,
            ),
            child: GestureDetector(
              onTap: () => onSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.brand.withValues(alpha: 0.08)
                      : AppColors.backgroundSurface,
                  borderRadius: AppRadius.mdBorderRadius,
                  border: Border.all(
                    color: isSelected ? AppColors.brand : AppColors.borderLight,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  options[index],
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isSelected ? AppColors.brand : AppColors.textSubtle,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// 단위 입력 필드 (숫자 + 단위 접미사)
class UnitTextField extends StatelessWidget {
  final TextEditingController controller;
  final String unit;
  final String? hintText;

  const UnitTextField({
    super.key,
    required this.controller,
    required this.unit,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: AppRadius.mdBorderRadius,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: hintText ?? '0',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textHint,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                border: InputBorder.none,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Text(
              unit,
              style: AppTextStyles.bodyMediumBold.copyWith(
                color: AppColors.textSubtle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 슬라이더 + 라벨 (문제 / 의심 / 보통 / 좋음)
class LabeledSlider extends StatelessWidget {
  final double value;
  final List<String> labels;
  final ValueChanged<double> onChanged;

  const LabeledSlider({
    super.key,
    required this.value,
    required this.labels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.brand,
            inactiveTrackColor: AppColors.borderLight,
            thumbColor: Colors.white,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 12,
              elevation: 2,
            ),
            trackHeight: 6,
            overlayColor: AppColors.brand.withValues(alpha: 0.1),
          ),
          child: Slider(
            value: value,
            min: 0,
            max: (labels.length - 1).toDouble(),
            divisions: labels.length - 1,
            onChanged: onChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels.asMap().entries.map((entry) {
              final isActive = entry.key == value.round();
              return Text(
                entry.value,
                style: AppTextStyles.captionRegular.copyWith(
                  color: isActive ? AppColors.brand : AppColors.textSubtle,
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// 시간 피커 (HH:MM AM/PM)
class TimePicker extends StatelessWidget {
  final int hour;
  final int minute;
  final bool isAm;
  final ValueChanged<int> onHourChanged;
  final ValueChanged<int> onMinuteChanged;
  final ValueChanged<bool> onAmPmChanged;

  const TimePicker({
    super.key,
    required this.hour,
    required this.minute,
    required this.isAm,
    required this.onHourChanged,
    required this.onMinuteChanged,
    required this.onAmPmChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 시
        _buildScrollColumn(
          value: hour,
          max: 12,
          min: 1,
          onChanged: onHourChanged,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            ':',
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textMain,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // 분
        _buildScrollColumn(
          value: minute,
          max: 59,
          min: 0,
          onChanged: onMinuteChanged,
          padZero: true,
        ),
        const SizedBox(width: 16),
        // AM/PM
        Column(
          children: [
            GestureDetector(
              onTap: () => onAmPmChanged(true),
              child: Text(
                'AM',
                style: AppTextStyles.bodyMediumBold.copyWith(
                  color: isAm ? AppColors.brand : AppColors.textHint,
                ),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => onAmPmChanged(false),
              child: Text(
                'PM',
                style: AppTextStyles.bodyMediumBold.copyWith(
                  color: !isAm ? AppColors.brand : AppColors.textHint,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScrollColumn({
    required int value,
    required int max,
    required int min,
    required ValueChanged<int> onChanged,
    bool padZero = false,
  }) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: AppRadius.mdBorderRadius,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => onChanged(value < max ? value + 1 : min),
            child: Icon(
              Icons.keyboard_arrow_up,
              color: AppColors.textSubtle,
              size: 20,
            ),
          ),
          Text(
            padZero
                ? value.toString().padLeft(2, '0')
                : value.toString().padLeft(2, '0'),
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textMain,
              fontWeight: FontWeight.w600,
            ),
          ),
          GestureDetector(
            onTap: () => onChanged(value > min ? value - 1 : max),
            child: Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.textSubtle,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

/// 섹터 디테일 시트의 공통 레이아웃
class SectorDetailSheetLayout extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final VoidCallback onSave;

  const SectorDetailSheetLayout({
    super.key,
    required this.title,
    required this.children,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.backgroundApp,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 드래그 인디케이터
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 타이틀
            Text(
              title,
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),

            // 폼 내용
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                ),
              ),
            ),

            // 저장하기 버튼
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.mdBorderRadius,
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    '저장하기',
                    style: AppTextStyles.bodyMediumBold.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
