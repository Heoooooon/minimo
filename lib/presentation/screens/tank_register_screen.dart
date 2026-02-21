import 'package:flutter/material.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';
import 'package:cmore_design_system/widgets/app_button.dart';

/// 어항 크기 열거형
enum TankSize {
  small('소형', '30L 이하'),
  medium('중형', '30L ~ 100L'),
  large('대형', '100L 이상');

  const TankSize(this.label, this.description);
  final String label;
  final String description;
}

/// 어항 등록 화면
///
/// 주요 기능:
/// - Radio Button으로 어항 크기 선택
/// - Large Square Button ("등록 완료") 사용
class TankRegisterScreen extends StatefulWidget {
  const TankRegisterScreen({super.key});

  @override
  State<TankRegisterScreen> createState() => _TankRegisterScreenState();
}

class _TankRegisterScreenState extends State<TankRegisterScreen> {
  final TextEditingController _tankNameController = TextEditingController();
  TankSize? _selectedTankSize;
  bool _isLoading = false;

  @override
  void dispose() {
    _tankNameController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _tankNameController.text.isNotEmpty && _selectedTankSize != null;
  }

  Future<void> _handleRegister() async {
    if (!_isFormValid) return;

    setState(() {
      _isLoading = true;
    });

    // 시뮬레이션: 등록 API 호출
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      // 성공 다이얼로그 표시
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('등록 완료', style: AppTextStyles.headlineMedium),
          content: Text('어항이 성공적으로 등록되었습니다.', style: AppTextStyles.bodyMedium),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('어항 등록'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
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
                    // 어항 이름 입력
                    _buildSectionTitle('어항 이름'),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _tankNameController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: '어항 이름을 입력해주세요',
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 어항 크기 선택
                    _buildSectionTitle('어항 크기'),
                    const SizedBox(height: 12),
                    _buildTankSizeSelector(),
                    const SizedBox(height: 32),

                    // 추가 정보 (선택)
                    _buildSectionTitle('추가 정보 (선택)'),
                    const SizedBox(height: 12),
                    TextField(
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: '어항에 대한 메모를 남겨보세요',
                      ),
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

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTextStyles.titleMedium);
  }

  Widget _buildTankSizeSelector() {
    return RadioGroup<TankSize>(
      groupValue: _selectedTankSize ?? TankSize.values.first,
      onChanged: (value) => setState(() => _selectedTankSize = value),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          children: TankSize.values.map((size) {
            final isSelected = _selectedTankSize == size;
            final isLast = size == TankSize.values.last;

            return Column(
              children: [
                InkWell(
                  onTap: () => setState(() => _selectedTankSize = size),
                  borderRadius: BorderRadius.vertical(
                    top: size == TankSize.values.first
                        ? const Radius.circular(12)
                        : Radius.zero,
                    bottom: isLast ? const Radius.circular(12) : Radius.zero,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Radio<TankSize>(
                          value: size,
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              size.label,
                              style: AppTextStyles.bodyMediumBold.copyWith(
                                color: isSelected
                                    ? AppColors.brand
                                    : AppColors.textMain,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              size.description,
                              style: AppTextStyles.captionRegular.copyWith(
                                color: AppColors.textSubtle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          );
          }).toList(),
        ),
      ),
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
        text: '등록 완료',
        onPressed: _isFormValid ? _handleRegister : null,
        size: AppButtonSize.large,
        shape: AppButtonShape.square,
        variant: AppButtonVariant.contained,
        isEnabled: _isFormValid,
        isLoading: _isLoading,
        expanded: true,
      ),
    );
  }
}
