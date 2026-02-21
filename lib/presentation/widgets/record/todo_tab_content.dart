import 'package:flutter/material.dart';
import '../../../core/utils/app_logger.dart';
import '../../../domain/models/record_data.dart';
import '../../../data/repositories/record_repository.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_spacing.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';
import '../../viewmodels/record_viewmodel.dart';
import 'package:cmore_design_system/widgets/confirm_dialog.dart';
import 'activity_add_bottom_sheet.dart';

/// 체크리스트 아이템 (태그 + 체크 상태 + 저장된 기록 ID)
class ChecklistItem {
  final RecordTag tag;
  bool isChecked;
  String? recordId;

  ChecklistItem({required this.tag, this.isChecked = false, this.recordId});
}

/// 태그별 아이콘/색상 매핑
class _TagStyle {
  final IconData icon;
  final Color color;
  const _TagStyle(this.icon, this.color);
}

const Map<RecordTag, _TagStyle> _tagStyles = {
  RecordTag.waterChange: _TagStyle(Icons.water_drop, AppColors.brand),
  RecordTag.feeding: _TagStyle(Icons.restaurant, AppColors.secondary),
  RecordTag.cleaning: _TagStyle(Icons.cleaning_services, AppColors.success),
  RecordTag.waterTest: _TagStyle(Icons.science, AppColors.brand),
  RecordTag.temperatureCheck: _TagStyle(Icons.thermostat, AppColors.secondary),
  RecordTag.plantCare: _TagStyle(Icons.eco, AppColors.success),
  RecordTag.maintenance: _TagStyle(Icons.build, AppColors.textSubtle),
  RecordTag.fishAdded: _TagStyle(Icons.pets, AppColors.brand),
  RecordTag.medication: _TagStyle(Icons.medical_services, AppColors.error),
};

/// 할 일 탭 콘텐츠
///
/// RecordType.todo 타입 레코드만 조회/생성하는 체크리스트 뷰
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
    final selectedTags = await ActivityAddBottomSheet.show(
      context,
      selectedDate: widget.selectedDate,
    );

    if (selectedTags != null && selectedTags.isNotEmpty && mounted) {
      for (final tag in selectedTags) {
        if (_checklist.any((item) => item.tag == tag)) continue;

        final savedRecord = await widget.recordViewModel.saveRecord(
          date: widget.selectedDate,
          tags: [tag],
          content: tag.label,
          isPublic: false,
          aquariumId: widget.aquariumId,
          creatureId: widget.creatureId,
          recordType: RecordType.todo,
          isCompleted: false,
        );

        if (savedRecord != null && mounted) {
          setState(() {
            _checklist.add(ChecklistItem(
              tag: tag,
              isChecked: false,
              recordId: savedRecord.id,
            ));
          });
        }
      }
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

      if (newState) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${item.tag.label} 완료!',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textInverse,
              ),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.smBorderRadius,
            ),
          ),
        );
      }
      widget.onDataChanged();
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _checklist.removeAt(oldIndex);
      _checklist.insert(newIndex, item);
    });
  }

  Future<void> _removeItem(int index) async {
    if (index >= _checklist.length) return;

    final confirmed = await ConfirmDialog.show(
      context,
      title: '삭제',
      message: '이 항목을 삭제하시겠습니까?',
      confirmLabel: '삭제',
      cancelLabel: '취소',
      isDestructive: true,
    );
    if (confirmed != true) return;

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
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _checklist.length,
            onReorder: _onReorder,
            proxyDecorator: (child, index, animation) {
              return Material(
                elevation: 2,
                color: AppColors.backgroundSurface,
                borderRadius: AppRadius.smBorderRadius,
                child: child,
              );
            },
            itemBuilder: (context, index) {
              final item = _checklist[index];
              return Column(
                key: ValueKey(item.recordId ?? index),
                children: [
                  _buildChecklistItem(index, item),
                  if (index < _checklist.length - 1)
                    const Divider(
                      height: 1,
                      indent: 52,
                      color: AppColors.borderLight,
                    ),
                ],
              );
            },
          ),

        // 할 일 추가 버튼
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          child: InkWell(
            onTap: _showAddActivitySheet,
            borderRadius: AppRadius.mdBorderRadius,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
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

  Widget _buildChecklistItem(int index, ChecklistItem item) {
    final tagStyle = _tagStyles[item.tag];

    return InkWell(
      onTap: () => _toggleItem(index),
      child: Container(
        color: item.isChecked ? AppColors.backgroundApp : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
        child: Row(
          children: [
            // 드래그 핸들
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: Icon(
                  Icons.drag_handle,
                  size: 20,
                  color: AppColors.textHint,
                ),
              ),
            ),
            _buildCheckbox(item.isChecked),
            const SizedBox(width: AppSpacing.sm),
            if (tagStyle != null)
              Opacity(
                opacity: item.isChecked ? 0.4 : 1.0,
                child: Icon(
                  tagStyle.icon,
                  size: 18,
                  color: tagStyle.color,
                ),
              ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                item.tag.label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: item.isChecked
                      ? AppColors.textHint
                      : AppColors.textMain,
                  decoration: item.isChecked
                      ? TextDecoration.lineThrough
                      : null,
                  decorationColor: item.isChecked
                      ? AppColors.textHint
                      : null,
                ),
              ),
            ),
            IconButton(
              onPressed: () => _removeItem(index),
              icon: Icon(
                Icons.remove_circle_outline,
                size: 20,
                color: AppColors.textHint,
              ),
              constraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
              padding: EdgeInsets.zero,
            ),
          ],
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
