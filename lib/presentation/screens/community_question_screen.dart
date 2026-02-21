import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/di/app_dependencies.dart';
import '../../domain/models/record_data.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';
import '../viewmodels/community_question_viewmodel.dart';
import 'package:cmore_design_system/widgets/app_button.dart';
import 'package:cmore_design_system/widgets/app_chip.dart';

/// 커뮤니티 질문 화면
///
/// 주요 기능:
/// - Small Button으로 "내 기록 첨부" 기능 구현
/// - 질문 작성 폼
/// - 태그 선택
class CommunityQuestionScreen extends StatefulWidget {
  const CommunityQuestionScreen({super.key});

  @override
  State<CommunityQuestionScreen> createState() =>
      _CommunityQuestionScreenState();
}

class _CommunityQuestionScreenState extends State<CommunityQuestionScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final Set<int> _selectedCategoryIndices = {};
  final List<RecordData> _attachedRecords = [];

  late CommunityQuestionViewModel _viewModel;

  final List<String> _categories = ['수질', '질병', '먹이', '장비', '어종', '수초', '기타'];

  @override
  void initState() {
    super.initState();
    _viewModel = context
        .read<AppDependencies>()
        .createCommunityQuestionViewModel();
    // 내 기록 불러오기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.loadMyRecords();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _titleController.text.isNotEmpty &&
        _contentController.text.isNotEmpty &&
        _selectedCategoryIndices.isNotEmpty;
  }

  Future<void> _handleSubmit() async {
    if (!_isFormValid) return;

    final selectedCategory = _categories[_selectedCategoryIndices.first];

    final success = await _viewModel.submitQuestion(
      title: _titleController.text,
      content: _contentController.text,
      category: selectedCategory,
      attachedRecords: _attachedRecords,
    );

    if (success && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('질문 등록 완료', style: AppTextStyles.headlineMedium),
          content: Text(
            '질문이 성공적으로 등록되었습니다.\n다른 사용자들의 답변을 기다려보세요!',
            style: AppTextStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dialog 닫기
                Navigator.of(context).pop(); // 화면 닫기
              },
              child: const Text('확인'),
            ),
          ],
        ),
      );
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

  void _showRecordPicker(CommunityQuestionViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildRecordPickerSheet(viewModel),
    );
  }

  void _attachRecord(RecordData record) {
    if (!_attachedRecords.any((r) => r.id == record.id)) {
      setState(() {
        _attachedRecords.add(record);
      });
    }
    Navigator.of(context).pop();
  }

  void _removeRecord(String id) {
    setState(() {
      _attachedRecords.removeWhere((r) => r.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<CommunityQuestionViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('질문하기'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                TextButton(
                  onPressed: _isFormValid ? _handleSubmit : null,
                  child: Text(
                    '등록',
                    style: AppTextStyles.bodyMediumBold.copyWith(
                      color: _isFormValid
                          ? AppColors.brand
                          : AppColors.disabledText,
                    ),
                  ),
                ),
              ],
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
                          // 제목 입력
                          _buildSectionTitle('제목'),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _titleController,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              hintText: '질문 제목을 입력해주세요',
                            ),
                          ),
                          const SizedBox(height: 24),

                          // 카테고리 선택
                          _buildSectionTitle('카테고리'),
                          const SizedBox(height: 12),
                          AppChipGroup(
                            labels: _categories,
                            selectedIndices: _selectedCategoryIndices,
                            onSelectionChanged: (indices) {
                              setState(() {
                                _selectedCategoryIndices
                                  ..clear()
                                  ..addAll(indices);
                              });
                            },
                            type: AppChipType.primary,
                            isMultiSelect: false,
                          ),
                          const SizedBox(height: 24),

                          // 내용 입력
                          _buildSectionTitle('내용'),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _contentController,
                            onChanged: (_) => setState(() {}),
                            maxLines: 8,
                            decoration: const InputDecoration(
                              hintText:
                                  '어항 환경, 물고기 상태 등 상세하게 설명해주시면\n더 정확한 답변을 받을 수 있어요',
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // 내 기록 첨부
                          _buildRecordAttachmentSection(viewModel),
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

  Widget _buildRecordAttachmentSection(CommunityQuestionViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('내 기록 첨부'),
                const SizedBox(height: 4),
                Text(
                  '관련 기록을 첨부하면 더 정확한 답변을 받을 수 있어요',
                  style: AppTextStyles.captionRegular.copyWith(
                    color: AppColors.textSubtle,
                  ),
                ),
              ],
            ),
            // Small Button - "내 기록 첨부"
            AppButton(
              text: '내 기록 첨부',
              onPressed: () => _showRecordPicker(viewModel),
              size: AppButtonSize.small,
              shape: AppButtonShape.square,
              variant: AppButtonVariant.outlined,
              leadingIcon: Icons.attach_file,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 첨부된 기록 목록
        if (_attachedRecords.isNotEmpty)
          Column(
            children: _attachedRecords.map((record) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      color: AppColors.brand,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDate(record.date),
                            style: AppTextStyles.captionRegular.copyWith(
                              color: AppColors.textSubtle,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            record.content,
                            style: AppTextStyles.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: record.tags.map((tag) {
                              return AppChip(
                                label: tag.label,
                                type: AppChipType.primary,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => _removeRecord(record.id ?? ''),
                      color: AppColors.textSubtle,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              );
            }).toList(),
          )
        else
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.backgroundApp,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.borderLight,
                style: BorderStyle.solid,
              ),
            ),
            child: Center(
              child: Text(
                '첨부된 기록이 없습니다',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSubtle,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRecordPickerSheet(CommunityQuestionViewModel viewModel) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // 핸들
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // 헤더
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('내 기록 선택', style: AppTextStyles.headlineSmall),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // 기록 목록
            Expanded(
              child: viewModel.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.brand),
                    )
                  : viewModel.myRecords.isEmpty
                  ? Center(
                      child: Text(
                        '저장된 기록이 없습니다.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSubtle,
                        ),
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      itemCount: viewModel.myRecords.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final record = viewModel.myRecords[index];
                        final isAttached = _attachedRecords.any(
                          (r) => r.id == record.id,
                        );

                        return InkWell(
                          onTap: isAttached
                              ? null
                              : () => _attachRecord(record),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isAttached
                                  ? AppColors.chipPrimaryBg
                                  : AppColors.backgroundSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isAttached
                                    ? AppColors.brand
                                    : AppColors.border,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatDate(record.date),
                                  style: AppTextStyles.captionRegular.copyWith(
                                    color: AppColors.textSubtle,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        record.content,
                                        style: AppTextStyles.bodyMediumBold,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isAttached)
                                      const Icon(
                                        Icons.check_circle,
                                        color: AppColors.brand,
                                        size: 20,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: record.tags.map((tag) {
                                    return AppChip(
                                      label: tag.label,
                                      type: AppChipType.primary,
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomButton(CommunityQuestionViewModel viewModel) {
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
        text: '질문 등록하기',
        onPressed: _isFormValid ? _handleSubmit : null,
        size: AppButtonSize.large,
        shape: AppButtonShape.square,
        variant: AppButtonVariant.contained,
        isEnabled: _isFormValid,
        isLoading: viewModel.isLoading,
        expanded: true,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}
