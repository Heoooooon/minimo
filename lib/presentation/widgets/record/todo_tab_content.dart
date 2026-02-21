import 'package:flutter/material.dart';
import '../../../core/utils/app_logger.dart';
import '../../../domain/models/record_data.dart';
import '../../../data/repositories/record_repository.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_spacing.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';
import '../../viewmodels/record_viewmodel.dart';
import 'activity_add_bottom_sheet.dart';
import 'sector_detail_sheet.dart';

/// 체크리스트 아이템 (태그 + 체크 상태 + 메모 + 저장된 기록 ID)
class ChecklistItem {
  final RecordTag tag;
  bool isChecked;
  String? recordId;
  String content;

  ChecklistItem({
    required this.tag,
    this.isChecked = false,
    this.recordId,
    this.content = '',
  });
}

/// 태그별 컬러 매핑
const Map<RecordTag, Color> _tagColors = {
  RecordTag.waterChange: AppColors.brand,
  RecordTag.feeding: Color(0xFFFF9800),
  RecordTag.cleaning: AppColors.success,
  RecordTag.waterTest: Color(0xFF7C4DFF),
  RecordTag.temperatureCheck: Color(0xFFE91E63),
  RecordTag.plantCare: Color(0xFF4CAF50),
  RecordTag.maintenance: Color(0xFF607D8B),
  RecordTag.fishAdded: AppColors.brand,
  RecordTag.medication: AppColors.error,
};

/// 할 일 탭 콘텐츠
///
/// RecordType.todo 타입 레코드만 조회/생성하는 체크리스트 뷰.
/// 컬러dot + 태그명 + 메모 + 우측 체크박스 디자인.
class TodoTabContent extends StatefulWidget {
  final String aquariumId;
  final String? aquariumName;
  final String? creatureId;
  final DateTime selectedDate;
  final RecordViewModel recordViewModel;
  final VoidCallback onDataChanged;

  const TodoTabContent({
    super.key,
    required this.aquariumId,
    this.aquariumName,
    required this.creatureId,
    required this.selectedDate,
    required this.recordViewModel,
    required this.onDataChanged,
  });

  @override
  State<TodoTabContent> createState() => _TodoTabContentState();
}

class _TodoTabContentState extends State<TodoTabContent> {
  List<ChecklistItem> _checklist = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadChecklist();
  }

  @override
  void didUpdateWidget(TodoTabContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.creatureId != widget.creatureId ||
        oldWidget.selectedDate != widget.selectedDate ||
        oldWidget.aquariumId != widget.aquariumId) {
      _loadChecklist();
    }
  }

  Future<void> _loadChecklist() async {
    setState(() => _isLoading = true);
    try {
      final records = await widget.recordViewModel.getRecordsByCreature(
        widget.selectedDate,
        widget.aquariumId,
        creatureId: widget.creatureId,
        recordType: RecordType.todo,
      );

      if (mounted) {
        setState(() {
          final items = <ChecklistItem>[];
          for (final record in records) {
            if (record.tags.isEmpty) continue;
            items.add(ChecklistItem(
              tag: record.tags.first,
              isChecked: record.isCompleted,
              recordId: record.id,
              content: record.content,
            ));
          }
          _checklist = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.data('Error loading todo checklist: $e', isError: true);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showAddActivitySheet() async {
    // 1단계: 섹터 선택
    final selectedTag = await ActivityAddBottomSheet.show(context);
    if (selectedTag == null || !mounted) return;

    // 2단계: 디테일 입력
    final detail = await SectorDetailSheet.show(context, tag: selectedTag);
    if (detail == null || !mounted) return;

    // 이미 등록된 태그인지 확인
    if (_checklist.any((item) => item.tag == detail.tag)) return;

    // 3단계: 레코드 저장
    final savedRecord = await widget.recordViewModel.saveRecord(
      date: widget.selectedDate,
      tags: [detail.tag],
      content: detail.content.isNotEmpty ? detail.content : detail.tag.label,
      isPublic: false,
      aquariumId: widget.aquariumId,
      creatureId: widget.creatureId,
      recordType: RecordType.todo,
      isCompleted: false,
    );

    if (savedRecord != null && mounted) {
      setState(() {
        _checklist.add(ChecklistItem(
          tag: detail.tag,
          isChecked: false,
          recordId: savedRecord.id,
          content: detail.content,
        ));
      });
      widget.onDataChanged();
    }
  }

  Future<void> _toggleItem(int index) async {
    if (index >= _checklist.length) return;

    final item = _checklist[index];
    final newState = !item.isChecked;
    final recordId = item.recordId;

    if (recordId == null) {
      setState(() => item.isChecked = newState);
      return;
    }

    final success = await widget.recordViewModel.updateRecordCompletion(
      recordId,
      newState,
    );

    if (success && mounted) {
      setState(() => item.isChecked = newState);
      widget.onDataChanged();
    }
  }

  Future<void> _removeItem(int index) async {
    if (index >= _checklist.length) return;

    final item = _checklist[index];
    if (item.recordId != null) {
      try {
        await PocketBaseRecordRepository.instance.deleteRecord(item.recordId!);
      } catch (e) {
        AppLogger.data('Error deleting record: $e', isError: true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('삭제에 실패했습니다.')),
          );
        }
        return;
      }
    }

    if (mounted) {
      setState(() => _checklist.removeAt(index));
      widget.onDataChanged();
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
        if (_checklist.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                const Icon(
                  Icons.checklist_rounded,
                  size: 48,
                  color: AppColors.borderLight,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '할 일을 추가해주세요',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _checklist.length,
            separatorBuilder: (_, _) => const Divider(
              height: 1,
              indent: 40,
              color: AppColors.borderLight,
            ),
            itemBuilder: (context, index) {
              return _buildTodoItem(index, _checklist[index]);
            },
          ),

        // 할 일 추가 버튼
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: InkWell(
            onTap: _showAddActivitySheet,
            borderRadius: AppRadius.mdBorderRadius,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: 14,
              ),
              decoration: const BoxDecoration(
                color: AppColors.chipPrimaryBg,
                borderRadius: AppRadius.mdBorderRadius,
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
                    '할 일 추가',
                    style: AppTextStyles.bodyMediumBold.copyWith(
                      color: AppColors.brand,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTodoItem(int index, ChecklistItem item) {
    final dotColor = _tagColors[item.tag] ?? AppColors.brand;
    final hasContent = item.content.isNotEmpty && item.content != item.tag.label;

    return Dismissible(
      key: ValueKey(item.recordId ?? 'item_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 22),
      ),
      onDismissed: (_) => _removeItem(index),
      child: InkWell(
        onTap: () => _toggleItem(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 12,
          ),
          child: Row(
            children: [
              // 컬러 dot
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: item.isChecked
                      ? dotColor.withValues(alpha: 0.3)
                      : dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),

              // 태그명 + 메모
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.tag.label,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: item.isChecked
                            ? AppColors.textHint
                            : AppColors.textMain,
                        fontWeight: FontWeight.w500,
                        decoration:
                            item.isChecked ? TextDecoration.lineThrough : null,
                        decorationColor:
                            item.isChecked ? AppColors.textHint : null,
                      ),
                    ),
                    if (hasContent) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.content,
                        style: AppTextStyles.captionRegular.copyWith(
                          color: AppColors.textSubtle,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // 우측 체크박스
              _buildCheckbox(item.isChecked),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox(bool isChecked) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: isChecked ? AppColors.success : Colors.transparent,
        border: isChecked
            ? null
            : Border.all(color: AppColors.border, width: 1.5),
        shape: BoxShape.circle,
      ),
      child: isChecked
          ? const Icon(Icons.check, color: Colors.white, size: 16)
          : null,
    );
  }
}
