import 'package:flutter/material.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';

/// 라벨 + 텍스트 필드 위젯
///
/// 어항 등록 폼에서 사용되는 라벨이 포함된 입력 필드
class LabelTextField extends StatelessWidget {
  const LabelTextField({
    super.key,
    required this.label,
    this.hintText,
    this.controller,
    this.onChanged,
    this.keyboardType,
    this.suffixIcon,
    this.onTap,
    this.readOnly = false,
    this.enabled = true,
  });

  /// 필드 라벨
  final String label;

  /// 힌트 텍스트
  final String? hintText;

  /// 텍스트 컨트롤러
  final TextEditingController? controller;

  /// 값 변경 콜백
  final ValueChanged<String>? onChanged;

  /// 키보드 타입
  final TextInputType? keyboardType;

  /// 우측 아이콘
  final Widget? suffixIcon;

  /// 탭 콜백 (날짜 선택 등)
  final VoidCallback? onTap;

  /// 읽기 전용 여부
  final bool readOnly;

  /// 활성화 여부
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 라벨
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSubtle,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),

        // 입력 필드
        GestureDetector(
          onTap: readOnly ? onTap : null,
          child: AbsorbPointer(
            absorbing: readOnly,
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              keyboardType: keyboardType,
              readOnly: readOnly,
              enabled: enabled,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMain,
              ),
              decoration: InputDecoration(
                hintText: hintText ?? label,
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textHint,
                ),
                filled: true,
                fillColor: AppColors.backgroundSurface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.brand,
                    width: 1.5,
                  ),
                ),
                suffixIcon: suffixIcon,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 날짜 선택 필드 위젯
class LabelDateField extends StatelessWidget {
  const LabelDateField({
    super.key,
    required this.label,
    this.hintText,
    this.value,
    required this.onTap,
  });

  final String label;
  final String? hintText;
  final DateTime? value;
  final VoidCallback onTap;

  String get _displayText {
    if (value == null) return hintText ?? label;
    return '${value!.year}.${value!.month.toString().padLeft(2, '0')}.${value!.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSubtle,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.backgroundSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _displayText,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: value != null
                          ? AppColors.textMain
                          : AppColors.textHint,
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 20,
                  color: AppColors.textSubtle,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
