import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// 어항 유형 열거형
enum AquariumType {
  freshwater('담수'),
  saltwater('해수');

  const AquariumType(this.label);
  final String label;
}

/// 어항 유형 토글 버튼 위젯
///
/// 담수/해수 선택을 위한 세그먼트 컨트롤 스타일 버튼
class TypeToggleButton extends StatelessWidget {
  const TypeToggleButton({
    super.key,
    required this.label,
    required this.selectedType,
    required this.onChanged,
  });

  /// 필드 라벨
  final String label;

  /// 선택된 유형
  final AquariumType? selectedType;

  /// 선택 변경 콜백
  final ValueChanged<AquariumType> onChanged;

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

        // 토글 버튼들
        Row(
          children: AquariumType.values.map((type) {
            final isSelected = selectedType == type;
            final isFirst = type == AquariumType.values.first;
            final isLast = type == AquariumType.values.last;

            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.chipPrimaryBg
                        : AppColors.backgroundSurface,
                    borderRadius: BorderRadius.horizontal(
                      left: isFirst ? const Radius.circular(12) : Radius.zero,
                      right: isLast ? const Radius.circular(12) : Radius.zero,
                    ),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.brand
                          : AppColors.borderLight,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      type.label,
                      style: AppTextStyles.bodyMediumMedium.copyWith(
                        color: isSelected
                            ? AppColors.brand
                            : AppColors.textHint,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
