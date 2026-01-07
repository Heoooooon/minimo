import 'package:flutter/material.dart';
import '../../../domain/models/aquarium_data.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import 'label_text_field.dart';

/// 어항 등록 Step 2: 장비 등록
///
/// 여과기, 바닥재, 제품명, 조명, 히터 정보를 입력받는 화면
class RegisterStepEquipment extends StatelessWidget {
  const RegisterStepEquipment({
    super.key,
    required this.filterType,
    required this.substrateController,
    required this.productNameController,
    required this.lighting,
    required this.hasHeater,
    required this.onFilterTypeChanged,
    required this.onSubstrateChanged,
    required this.onProductNameChanged,
    required this.onLightingChanged,
    required this.onHeaterChanged,
  });

  final FilterType? filterType;
  final TextEditingController substrateController;
  final TextEditingController productNameController;
  final LightingType? lighting;
  final bool? hasHeater;

  final ValueChanged<FilterType?> onFilterTypeChanged;
  final ValueChanged<String> onSubstrateChanged;
  final ValueChanged<String> onProductNameChanged;
  final ValueChanged<LightingType?> onLightingChanged;
  final ValueChanged<bool> onHeaterChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타이틀
          Text(
            '사용 중인 장비를\n등록해 주세요.',
            style: AppTextStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '나중에 수정할 수 있어요.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSubtle,
            ),
          ),
          const SizedBox(height: 32),

          // 여과기 종류
          _buildSectionLabel('여과기'),
          const SizedBox(height: 8),
          _buildFilterTypeSelector(),
          const SizedBox(height: 24),

          // 바닥재
          LabelTextField(
            label: '바닥재',
            hintText: '예: 소일, 모래, 자갈',
            controller: substrateController,
            onChanged: onSubstrateChanged,
          ),
          const SizedBox(height: 24),

          // 제품명
          LabelTextField(
            label: '제품명',
            hintText: '어항 또는 여과기 제품명',
            controller: productNameController,
            onChanged: onProductNameChanged,
          ),
          const SizedBox(height: 24),

          // 조명
          _buildSectionLabel('조명'),
          const SizedBox(height: 8),
          _buildLightingSelector(),
          const SizedBox(height: 24),

          // 히터
          _buildHeaterToggle(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: AppTextStyles.bodySmall.copyWith(
        color: AppColors.textSubtle,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildFilterTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: FilterType.values.map((type) {
        final isSelected = filterType == type;
        return GestureDetector(
          onTap: () => onFilterTypeChanged(isSelected ? null : type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.chipPrimaryBg
                  : AppColors.backgroundSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.brand : AppColors.borderLight,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              type.label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isSelected ? AppColors.brand : AppColors.textSubtle,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLightingSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: LightingType.values.map((type) {
        final isSelected = lighting == type;
        return GestureDetector(
          onTap: () => onLightingChanged(isSelected ? null : type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.chipPrimaryBg
                  : AppColors.backgroundSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.brand : AppColors.borderLight,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              type.label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isSelected ? AppColors.brand : AppColors.textSubtle,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHeaterToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: hasHeater == true
                  ? AppColors.chipSecondaryBg
                  : AppColors.backgroundApp,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.thermostat,
              color: hasHeater == true
                  ? AppColors.secondary
                  : AppColors.textHint,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '히터 사용',
                  style: AppTextStyles.bodyMediumMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '어항에 히터를 사용 중인가요?',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSubtle,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: hasHeater ?? false,
            onChanged: onHeaterChanged,
            activeColor: AppColors.brand,
          ),
        ],
      ),
    );
  }
}
