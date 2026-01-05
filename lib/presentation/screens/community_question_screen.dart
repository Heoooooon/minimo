import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_chip.dart';

/// 첨부된 기록 모델
class AttachedRecord {
  final String id;
  final String title;
  final String date;
  final List<String> tags;

  const AttachedRecord({
    required this.id,
    required this.title,
    required this.date,
    required this.tags,
  });
}

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
  final List<AttachedRecord> _attachedRecords = [];
  bool _isLoading = false;

  // 샘플 내 기록 목록 (실제로는 API에서 가져옴)
  final List<AttachedRecord> _myRecords = const [
    AttachedRecord(
      id: '1',
      title: '물갈이 완료',
      date: '2024.01.15',
      tags: ['물갈이', '수질검사'],
    ),
    AttachedRecord(
      id: '2',
      title: '물고기 추가 - 네온 테트라 5마리',
      date: '2024.01.12',
      tags: ['물고기 추가'],
    ),
    AttachedRecord(
      id: '3',
      title: '필터 청소',
      date: '2024.01.10',
      tags: ['청소', '장비 관리'],
    ),
  ];

  final List<String> _categories = ['수질', '질병', '먹이', '장비', '어종', '수초', '기타'];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _titleController.text.isNotEmpty &&
        _contentController.text.isNotEmpty &&
        _selectedCategoryIndices.isNotEmpty;
  }

  Future<void> _handleSubmit() async {
    if (!_isFormValid) return;

    setState(() {
      _isLoading = true;
    });

    // 시뮬레이션: 질문 등록 API 호출
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

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

  void _showRecordPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildRecordPickerSheet(),
    );
  }

  void _attachRecord(AttachedRecord record) {
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
              style: AppTextStyles.bodyMediumMedium.copyWith(
                color: _isFormValid ? AppColors.brand : AppColors.disabledText,
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
                    _buildRecordAttachmentSection(),
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

  Widget _buildRecordAttachmentSection() {
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
              onPressed: _showRecordPicker,
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
                            record.title,
                            style: AppTextStyles.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            record.date,
                            style: AppTextStyles.captionRegular.copyWith(
                              color: AppColors.textSubtle,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => _removeRecord(record.id),
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

  Widget _buildRecordPickerSheet() {
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
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                itemCount: _myRecords.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final record = _myRecords[index];
                  final isAttached = _attachedRecords.any(
                    (r) => r.id == record.id,
                  );

                  return InkWell(
                    onTap: isAttached ? null : () => _attachRecord(record),
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
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  record.title,
                                  style: AppTextStyles.bodyMediumMedium,
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
                          Text(
                            record.date,
                            style: AppTextStyles.captionRegular.copyWith(
                              color: AppColors.textSubtle,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: record.tags.map((tag) {
                              return AppChip(
                                label: tag,
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
        text: '질문 등록하기',
        onPressed: _isFormValid ? _handleSubmit : null,
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
