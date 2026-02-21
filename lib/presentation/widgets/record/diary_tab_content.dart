import 'package:flutter/material.dart';
import '../../../core/utils/app_logger.dart';
import '../../../domain/models/record_data.dart';
import '../../../data/repositories/record_repository.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_spacing.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';
import '../../viewmodels/record_viewmodel.dart';
import 'package:cmore_design_system/widgets/confirm_dialog.dart';

/// 일기 탭 콘텐츠
///
/// RecordType.diary 타입 레코드 조회/표시
class DiaryTabContent extends StatefulWidget {
  final String aquariumId;
  final String? creatureId;
  final DateTime selectedDate;
  final RecordViewModel recordViewModel;
  final VoidCallback onDataChanged;

  const DiaryTabContent({
    super.key,
    required this.aquariumId,
    required this.creatureId,
    required this.selectedDate,
    required this.recordViewModel,
    required this.onDataChanged,
  });

  @override
  State<DiaryTabContent> createState() => _DiaryTabContentState();
}

class _DiaryTabContentState extends State<DiaryTabContent> {
  List<RecordData> _diaries = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDiaries();
  }

  @override
  void didUpdateWidget(DiaryTabContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.creatureId != widget.creatureId ||
        oldWidget.selectedDate != widget.selectedDate ||
        oldWidget.aquariumId != widget.aquariumId) {
      _loadDiaries();
    }
  }

  Future<void> _loadDiaries() async {
    setState(() => _isLoading = true);
    try {
      final records = await widget.recordViewModel.getRecordsByCreature(
        widget.selectedDate,
        widget.aquariumId,
        creatureId: widget.creatureId,
        recordType: RecordType.diary,
      );

      if (mounted) {
        setState(() {
          _diaries = records;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.data('Error loading diaries: $e', isError: true);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showAddDiarySheet() async {
    final content = await _showDiaryInputSheet(context);

    if (content != null && content.isNotEmpty && mounted) {
      await widget.recordViewModel.saveRecord(
        date: widget.selectedDate,
        tags: [],
        content: content,
        isPublic: false,
        aquariumId: widget.aquariumId,
        creatureId: widget.creatureId,
        recordType: RecordType.diary,
        isCompleted: true,
      );
      widget.onDataChanged();
      _loadDiaries();
    }
  }

  Future<void> _editDiary(RecordData record) async {
    if (record.id == null) return;

    final content = await _showDiaryInputSheet(
      context,
      initialContent: record.content,
    );

    if (content != null && content.isNotEmpty && mounted) {
      final updated = record.copyWith(content: content);
      final result = await widget.recordViewModel.updateRecord(updated);
      if (result != null) {
        widget.onDataChanged();
        _loadDiaries();
      }
    }
  }

  Future<String?> _showDiaryInputSheet(
    BuildContext context, {
    String? initialContent,
  }) {
    final controller = TextEditingController(text: initialContent);
    final isEditing = initialContent != null && initialContent.isNotEmpty;

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.backgroundApp,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  // 드래그 인디케이터
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    isEditing ? '일기 수정' : '일기 작성',
                    style: AppTextStyles.headlineSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: TextField(
                      controller: controller,
                      maxLines: 5,
                      maxLength: 500,
                      autofocus: true,
                      buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                        final Color color;
                        if (currentLength >= 500) {
                          color = AppColors.error;
                        } else if (currentLength > 450) {
                          color = AppColors.warning;
                        } else {
                          color = AppColors.textHint;
                        }
                        return Text(
                          '$currentLength / $maxLength',
                          style: AppTextStyles.captionRegular.copyWith(color: color),
                        );
                      },
                      decoration: InputDecoration(
                        hintText: '오늘의 일기를 작성해주세요',
                        hintStyle: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textHint,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.mdBorderRadius,
                          borderSide: const BorderSide(
                            color: AppColors.borderLight,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppRadius.mdBorderRadius,
                          borderSide: const BorderSide(
                            color: AppColors.borderLight,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppRadius.mdBorderRadius,
                          borderSide: const BorderSide(
                            color: AppColors.brand,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(AppSpacing.lg),
                      ),
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          final text = controller.text.trim();
                          if (text.isNotEmpty) {
                            Navigator.of(context).pop(text);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brand,
                          foregroundColor: AppColors.textInverse,
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.mdBorderRadius,
                          ),
                        ),
                        child: Text(
                          isEditing ? '수정하기' : '저장하기',
                          style: AppTextStyles.bodyMediumBold.copyWith(
                            color: AppColors.textInverse,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _removeDiary(RecordData record) async {
    if (record.id == null) return;

    final confirmed = await ConfirmDialog.show(
      context,
      title: '삭제',
      message: '이 일기를 삭제하시겠습니까?',
      confirmLabel: '삭제',
      cancelLabel: '취소',
      isDestructive: true,
    );
    if (confirmed != true) return;

    try {
      await PocketBaseRecordRepository.instance.deleteRecord(record.id!);
      if (mounted) {
        setState(() {
          _diaries.removeWhere((r) => r.id == record.id);
        });
        widget.onDataChanged();
      }
    } catch (e) {
      AppLogger.data('Error deleting diary: $e', isError: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('삭제에 실패했습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return Column(
      children: [
        if (_diaries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Text(
              '일기를 작성해주세요',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
            ),
          )
        else
          ..._diaries.map((record) => _buildDiaryItem(record)),

        // 일기 추가 버튼
        InkWell(
          onTap: _showAddDiarySheet,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.borderLight)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  size: 18,
                  color: AppColors.brand,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '일기 추가',
                  style: AppTextStyles.bodyMediumBold.copyWith(
                    color: AppColors.brand,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDiaryItem(RecordData record) {
    final timeStr = _formatTime(record.date);

    return InkWell(
      onTap: () => _editDiary(record),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 시간
            Text(
              timeStr,
              style: AppTextStyles.captionRegular.copyWith(
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // 내용
            Expanded(
              child: Text(
                record.content,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMain,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // 삭제 버튼
            GestureDetector(
              onTap: () => _removeDiary(record),
              child: const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: AppColors.textHint,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
