import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/models/record_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../viewmodels/record_viewmodel.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_chip.dart';

/// 기록하기 화면
///
/// 주요 기능:
/// - Chips를 사용하여 태그 선택 기능
/// - Switch를 사용하여 '공개 여부' 설정
/// - Medium Round Button으로 저장 액션
class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  final TextEditingController _contentController = TextEditingController();
  final Set<RecordTag> _selectedTags = {};
  bool _isPublic = true;
  DateTime _selectedDate = DateTime.now();

  late RecordViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = RecordViewModel();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _selectedTags.isNotEmpty && _contentController.text.isNotEmpty;
  }

  Future<void> _handleSave() async {
    if (!_isFormValid) return;

    final success = await _viewModel.saveRecord(
      date: _selectedDate,
      tags: _selectedTags.toList(),
      content: _contentController.text,
      isPublic: _isPublic,
      // aquariumId: TODO: 어항 선택 기능 추가 시 연동
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '기록이 저장되었습니다.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textInverse,
            ),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

      Navigator.of(context).pop();
    } else if (_viewModel.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_viewModel.errorMessage!),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
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
        _selectedDate = picked;
      });
    }
  }

  void _toggleTag(RecordTag tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<RecordViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('기록하기'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 날짜 선택
                          _buildDateSelector(),
                          const SizedBox(height: 24),

                          // 태그 선택
                          _buildSectionTitle('태그 선택'),
                          const SizedBox(height: 4),
                          Text(
                            '어떤 활동을 했나요?',
                            style: AppTextStyles.captionRegular.copyWith(
                              color: AppColors.textSubtle,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildTagSelector(),
                          const SizedBox(height: 24),

                          // 내용 입력
                          _buildSectionTitle('기록 내용'),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _contentController,
                            onChanged: (_) => setState(() {}),
                            maxLines: 5,
                            decoration: const InputDecoration(
                              hintText: '오늘의 관리 기록을 남겨보세요',
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // 공개 여부 설정
                          _buildVisibilityToggle(),
                        ],
                      ),
                    ),
                  ),

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

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTextStyles.titleMedium);
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.chipPrimaryBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.calendar_today_rounded,
                color: AppColors.brand,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '기록 날짜',
                    style: AppTextStyles.captionRegular.copyWith(
                      color: AppColors.textSubtle,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일',
                    style: AppTextStyles.bodyMediumMedium,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSubtle),
          ],
        ),
      ),
    );
  }

  Widget _buildTagSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: RecordTag.values.map((tag) {
        final isSelected = _selectedTags.contains(tag);
        // RecordTag.chipType이 없으므로 직접 매핑하거나 모델에 추가해야 함.
        // 여기서는 임시로 매핑 로직 추가 또는 RecordTag 수정 필요.
        // RecordTag enum을 model로 옮기면서 chipType 속성을 제거했었음 (domain layer dependency issue 방지).
        // UI layer에서 매핑하는 것이 좋음.
        
        AppChipType chipType;
        switch(tag) {
          case RecordTag.waterChange:
          case RecordTag.waterTest:
            chipType = AppChipType.primary;
            break;
          case RecordTag.cleaning:
          case RecordTag.fishAdded:
             chipType = AppChipType.secondary;
             break;
          case RecordTag.feeding:
            chipType = AppChipType.success;
            break;
          case RecordTag.medication:
            chipType = AppChipType.error;
            break;
          case RecordTag.maintenance:
            chipType = AppChipType.neutral;
            break;
        }

        return AppChip(
          label: tag.label,
          type: chipType,
          isSelected: isSelected,
          onTap: () => _toggleTag(tag),
        );
      }).toList(),
    );
  }

  Widget _buildVisibilityToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('공개 여부', style: AppTextStyles.bodyMediumMedium),
                const SizedBox(height: 4),
                Text(
                  _isPublic ? '다른 사용자들이 이 기록을 볼 수 있어요' : '나만 볼 수 있는 비공개 기록이에요',
                  style: AppTextStyles.captionRegular.copyWith(
                    color: AppColors.textSubtle,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isPublic,
            onChanged: (value) => setState(() => _isPublic = value),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(RecordViewModel viewModel) {
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
      child: Row(
        children: [
          Expanded(
            child: AppButton(
              text: '임시저장',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '임시저장 되었습니다.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMain,
                      ),
                    ),
                    backgroundColor: AppColors.backgroundSurface,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: AppColors.borderLight),
                    ),
                  ),
                );
              },
              size: AppButtonSize.medium,
              shape: AppButtonShape.round,
              variant: AppButtonVariant.outlined,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: AppButton(
              text: '저장하기',
              onPressed: _isFormValid ? _handleSave : null,
              size: AppButtonSize.medium,
              shape: AppButtonShape.round,
              variant: AppButtonVariant.contained,
              isEnabled: _isFormValid,
              isLoading: viewModel.isLoading,
            ),
          ),
        ],
      ),
    );
  }
}
