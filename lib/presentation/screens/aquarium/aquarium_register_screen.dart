import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/aquarium/label_text_field.dart';
import '../../widgets/aquarium/type_toggle_button.dart';

/// 어항 등록 화면 - Step 1 (기본 정보 입력)
///
/// Path: /aquarium/register
class AquariumRegisterScreen extends StatefulWidget {
  const AquariumRegisterScreen({super.key});

  @override
  State<AquariumRegisterScreen> createState() => _AquariumRegisterScreenState();
}

class _AquariumRegisterScreenState extends State<AquariumRegisterScreen> {
  // Form Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dimensionController = TextEditingController();

  // Form State
  AquariumType? _selectedType;
  DateTime? _settingDate;

  @override
  void dispose() {
    _nameController.dispose();
    _dimensionController.dispose();
    super.dispose();
  }

  /// 폼 유효성 검사
  bool get _isFormValid {
    return _nameController.text.isNotEmpty &&
        _selectedType != null &&
        _settingDate != null &&
        _dimensionController.text.isNotEmpty;
  }

  /// 날짜 선택
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _settingDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.brand,
              onPrimary: AppColors.textInverse,
              surface: AppColors.backgroundSurface,
              onSurface: AppColors.textMain,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _settingDate = picked;
      });
    }
  }

  /// 다음 단계로
  void _handleNext() {
    if (!_isFormValid) return;

    // TODO: 다음 단계 화면으로 이동 (Step 2)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '다음 단계로 이동 (추후 구현)',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textInverse),
        ),
        backgroundColor: AppColors.brand,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSurface,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            // 스크롤 가능한 폼 영역
            Expanded(
              child: SingleChildScrollView(
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
                      controller: _nameController,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 24),

                    // 어항 유형
                    TypeToggleButton(
                      label: '어항 유형',
                      selectedType: _selectedType,
                      onChanged: (type) {
                        setState(() {
                          _selectedType = type;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // 어항 세팅 일자
                    LabelDateField(
                      label: '어항 세팅 일자',
                      hintText: '어항 세팅 일자',
                      value: _settingDate,
                      onTap: _selectDate,
                    ),
                    const SizedBox(height: 24),

                    // 어항 치수
                    LabelTextField(
                      label: '어항 치수',
                      hintText: '어항 치수',
                      controller: _dimensionController,
                      onChanged: (_) => setState(() {}),
                      keyboardType: TextInputType.text,
                    ),
                  ],
                ),
              ),
            ),

            // 하단 버튼
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.backgroundSurface,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(
          Icons.arrow_back_ios,
          color: AppColors.textMain,
          size: 20,
        ),
      ),
      title: Text('새 어항 등록', style: AppTextStyles.bodyMediumMedium),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Text(
              '1/4',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSubtle,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 8,
          ),
        ],
      ),
      child: AppButton(
        text: '다음으로',
        onPressed: _isFormValid ? _handleNext : null,
        size: AppButtonSize.large,
        shape: AppButtonShape.square,
        variant: AppButtonVariant.contained,
        isEnabled: _isFormValid,
        expanded: true,
      ),
    );
  }
}
