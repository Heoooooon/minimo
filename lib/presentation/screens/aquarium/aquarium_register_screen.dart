import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../viewmodels/aquarium_register_viewmodel.dart';
import '../../widgets/aquarium/register_step_basic_info.dart';
import '../../widgets/aquarium/register_step_equipment.dart';
import '../../widgets/aquarium/register_step_additional.dart';
import '../../widgets/aquarium/register_step_photo.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/date_picker_bottom_sheet.dart';

/// 어항 등록 화면 (4단계)
///
/// Path: /aquarium/register
class AquariumRegisterScreen extends StatefulWidget {
  const AquariumRegisterScreen({super.key});

  @override
  State<AquariumRegisterScreen> createState() => _AquariumRegisterScreenState();
}

class _AquariumRegisterScreenState extends State<AquariumRegisterScreen> {
  // Step 1 Controllers
  late TextEditingController _nameController;
  late TextEditingController _dimensionController;

  // Step 2 Controllers
  late TextEditingController _substrateController;
  late TextEditingController _productNameController;

  // Step 3 Controllers
  late TextEditingController _notesController;

  // ViewModel
  late AquariumRegisterViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    // Step 1
    _nameController = TextEditingController();
    _dimensionController = TextEditingController();
    // Step 2
    _substrateController = TextEditingController();
    _productNameController = TextEditingController();
    // Step 3
    _notesController = TextEditingController();
    // ViewModel
    _viewModel = AquariumRegisterViewModel();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dimensionController.dispose();
    _substrateController.dispose();
    _productNameController.dispose();
    _notesController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  /// 날짜 선택 바텀시트 표시
  Future<void> _selectDate() async {
    final picked = await DatePickerBottomSheet.show(
      context: context,
      initialDate: _viewModel.data.settingDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      title: '어항 세팅 일자',
    );

    if (picked != null) {
      _viewModel.setSettingDate(picked);
    }
  }

  /// 다음 단계 또는 제출
  void _handleNext() {
    if (_viewModel.isLastStep) {
      _handleSubmit();
    } else {
      _viewModel.nextStep();
    }
  }

  /// 어항 등록 제출
  Future<void> _handleSubmit() async {
    final success = await _viewModel.submitRegistration();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '어항이 등록되었습니다!',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textInverse,
            ),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  /// 뒤로가기 처리
  void _handleBack() {
    if (_viewModel.isFirstStep) {
      Navigator.pop(context);
    } else {
      _viewModel.previousStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<AquariumRegisterViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            backgroundColor: AppColors.backgroundSurface,
            appBar: _buildAppBar(viewModel),
            body: SafeArea(
              child: Column(
                children: [
                  // 스텝 컨텐츠
                  Expanded(child: _buildStepContent(viewModel)),
                  // 하단 버튼
                  _buildBottomButton(viewModel),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AquariumRegisterViewModel viewModel) {
    return AppBar(
      backgroundColor: AppColors.backgroundSurface,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        onPressed: _handleBack,
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
              '${viewModel.currentStep}/${AquariumRegisterViewModel.totalSteps}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSubtle,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent(AquariumRegisterViewModel viewModel) {
    switch (viewModel.currentStep) {
      case 1:
        return RegisterStepBasicInfo(
          nameController: _nameController,
          dimensionController: _dimensionController,
          selectedType: viewModel.data.type,
          settingDate: viewModel.data.settingDate,
          onNameChanged: viewModel.setName,
          onTypeChanged: viewModel.setType,
          onDateTap: _selectDate,
          onDimensionChanged: viewModel.setDimensions,
        );
      case 2:
        return RegisterStepEquipment(
          filterType: viewModel.data.filterType,
          substrateController: _substrateController,
          productNameController: _productNameController,
          lighting: viewModel.data.lighting,
          hasHeater: viewModel.data.hasHeater,
          onFilterTypeChanged: viewModel.setFilterType,
          onSubstrateChanged: viewModel.setSubstrate,
          onProductNameChanged: viewModel.setProductName,
          onLightingChanged: viewModel.setLighting,
          onHeaterChanged: viewModel.setHasHeater,
        );
      case 3:
        return RegisterStepAdditional(
          purpose: viewModel.data.purpose,
          notesController: _notesController,
          onPurposeChanged: viewModel.setPurpose,
          onNotesChanged: viewModel.setNotes,
        );
      case 4:
        return RegisterStepPhoto(
          photoPath: viewModel.data.photoPath,
          photoBytes: viewModel.photoBytes,
          isLoading: viewModel.isLoading,
          onPickFromGallery: viewModel.pickPhotoFromGallery,
          onTakePhoto: viewModel.takePhoto,
          onRemovePhoto: viewModel.removePhoto,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomButton(AquariumRegisterViewModel viewModel) {
    final buttonText = viewModel.isLastStep ? '등록 완료' : '다음으로';
    final isEnabled = viewModel.canProceed && !viewModel.isLoading;

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
        text: buttonText,
        onPressed: isEnabled ? _handleNext : null,
        size: AppButtonSize.large,
        shape: AppButtonShape.square,
        variant: AppButtonVariant.contained,
        isEnabled: isEnabled,
        expanded: true,
      ),
    );
  }
}
