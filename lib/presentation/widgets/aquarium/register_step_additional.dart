import 'package:flutter/material.dart';
import '../../../domain/models/aquarium_data.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';

/// 어항 등록 Step 3: 추가 정보
///
/// 사육 목적과 비고를 입력받는 화면
class RegisterStepAdditional extends StatelessWidget {
  const RegisterStepAdditional({
    super.key,
    required this.purpose,
    required this.notesController,
    required this.onPurposeChanged,
    required this.onNotesChanged,
  });

  final AquariumPurpose? purpose;
  final TextEditingController notesController;
  final ValueChanged<AquariumPurpose?> onPurposeChanged;
  final ValueChanged<String> onNotesChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타이틀
          Text(
            '추가 정보를\n입력해 주세요.',
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

          // 목적 선택
          _buildSectionLabel('목적'),
          const SizedBox(height: 8),
          _buildPurposeSelector(),
          const SizedBox(height: 32),

          // 비고
          _buildSectionLabel('비고'),
          const SizedBox(height: 8),
          _buildNotesField(),
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

  Widget _buildPurposeSelector() {
    return Column(
      children: AquariumPurpose.values.map((p) {
        final isSelected = purpose == p;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => onPurposeChanged(isSelected ? null : p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.chipPrimaryBg
                    : AppColors.backgroundSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.brand : AppColors.borderLight,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? AppColors.brand
                          : AppColors.backgroundSurface,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.brand
                            : AppColors.borderLight,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            size: 14,
                            color: AppColors.textInverse,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    p.label,
                    style: AppTextStyles.bodyMediumBold.copyWith(
                      color: isSelected ? AppColors.brand : AppColors.textMain,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: notesController,
          onChanged: onNotesChanged,
          maxLines: 5,
          maxLength: 300,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMain),
          decoration: InputDecoration(
            hintText: '어항에 대한 추가 정보를 입력해 주세요.',
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textHint,
            ),
            filled: true,
            fillColor: AppColors.backgroundSurface,
            contentPadding: const EdgeInsets.all(16),
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
              borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
            ),
            counterStyle: AppTextStyles.captionRegular.copyWith(
              color: AppColors.textSubtle,
            ),
          ),
        ),
      ],
    );
  }
}
