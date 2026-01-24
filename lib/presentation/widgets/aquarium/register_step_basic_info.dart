import 'package:flutter/material.dart';
import '../../../theme/app_text_styles.dart';
import 'label_text_field.dart';
import 'type_toggle_button.dart';

/// 어항 등록 Step 1: 기본 정보 입력
///
/// 어항 이름, 유형, 세팅 일자, 치수를 입력받는 화면
class RegisterStepBasicInfo extends StatelessWidget {
  const RegisterStepBasicInfo({
    super.key,
    required this.nameController,
    required this.dimensionController,
    required this.selectedType,
    required this.settingDate,
    required this.onNameChanged,
    required this.onTypeChanged,
    required this.onDateTap,
    required this.onDimensionChanged,
  });

  /// 이름 컨트롤러
  final TextEditingController nameController;

  /// 치수 컨트롤러
  final TextEditingController dimensionController;

  /// 선택된 어항 유형
  final AquariumType? selectedType;

  /// 선택된 세팅 일자
  final DateTime? settingDate;

  /// 이름 변경 콜백
  final ValueChanged<String> onNameChanged;

  /// 유형 변경 콜백
  final ValueChanged<AquariumType> onTypeChanged;

  /// 날짜 선택 탭 콜백
  final VoidCallback onDateTap;

  /// 치수 변경 콜백
  final ValueChanged<String> onDimensionChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타이틀
          Text(
            '어항 기본 정보를\n입력해 주세요.',
            style: AppTextStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),

          // 어항 이름
          LabelTextField(
            label: '어항 이름',
            hintText: '어항 이름',
            controller: nameController,
            onChanged: onNameChanged,
          ),
          const SizedBox(height: 24),

          // 어항 유형
          TypeToggleButton(
            label: '어항 유형',
            selectedType: selectedType,
            onChanged: onTypeChanged,
          ),
          const SizedBox(height: 24),

          // 어항 세팅 일자
          LabelDateField(
            label: '어항 세팅 일자',
            hintText: '어항 세팅 일자',
            value: settingDate,
            onTap: onDateTap,
          ),
          const SizedBox(height: 24),

          // 어항 치수
          LabelTextField(
            label: '어항 치수',
            hintText: '어항 치수',
            controller: dimensionController,
            onChanged: onDimensionChanged,
            keyboardType: TextInputType.text,
          ),
        ],
      ),
    );
  }
}
