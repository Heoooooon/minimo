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

/// 기록 탭 콘텐츠
///
/// RecordType.activity 타입 레코드 조회/표시
class ActivityTabContent extends StatefulWidget {
  final String aquariumId;
  final String? creatureId;
  final DateTime selectedDate;
  final RecordViewModel recordViewModel;
  final VoidCallback onDataChanged;

  const ActivityTabContent({
    super.key,
    required this.aquariumId,
    required this.creatureId,
    required this.selectedDate,
    required this.recordViewModel,
    required this.onDataChanged,
  });

  @override
  State<ActivityTabContent> createState() => _ActivityTabContentState();
}

class _ActivityTabContentState extends State<ActivityTabContent> {
  List<RecordData> _activities = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  @override
  void didUpdateWidget(ActivityTabContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.creatureId != widget.creatureId ||
        oldWidget.selectedDate != widget.selectedDate ||
        oldWidget.aquariumId != widget.aquariumId) {
      _loadActivities();
    }
  }

  Future<void> _loadActivities() async {
    setState(() => _isLoading = true);
    try {
      final records = await widget.recordViewModel.getRecordsByCreature(
        widget.selectedDate,
        widget.aquariumId,
        creatureId: widget.creatureId,
        recordType: RecordType.activity,
      );

      if (mounted) {
        setState(() {
          _activities = records;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.data('Error loading activities: $e', isError: true);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showAddActivitySheet() async {
    final selectedTag = await ActivityAddBottomSheet.show(context);
    if (selectedTag == null || !mounted) return;

    await widget.recordViewModel.saveRecord(
      date: widget.selectedDate,
      tags: [selectedTag],
      content: selectedTag.label,
      isPublic: false,
      aquariumId: widget.aquariumId,
      creatureId: widget.creatureId,
      recordType: RecordType.activity,
      isCompleted: true,
    );
    widget.onDataChanged();
    _loadActivities();
  }

  Future<void> _editActivity(RecordData record) async {
    if (record.id == null) return;

    final selectedTag = await ActivityAddBottomSheet.show(context);
    if (selectedTag == null || !mounted) return;

    final updated = record.copyWith(
      tags: [selectedTag],
      content: selectedTag.label,
    );
    final result = await widget.recordViewModel.updateRecord(updated);
    if (result != null) {
      widget.onDataChanged();
      _loadActivities();
    }
  }

  Future<void> _removeActivity(RecordData record) async {
    if (record.id == null) return;

    final confirmed = await ConfirmDialog.show(
      context,
      title: '삭제',
      message: '이 기록을 삭제하시겠습니까?',
      confirmLabel: '삭제',
      cancelLabel: '취소',
      isDestructive: true,
    );
    if (confirmed != true) return;

    try {
      await PocketBaseRecordRepository.instance.deleteRecord(record.id!);
      if (mounted) {
        setState(() {
          _activities.removeWhere((r) => r.id == record.id);
        });
        widget.onDataChanged();
      }
    } catch (e) {
      AppLogger.data('Error deleting activity: $e', isError: true);
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
        if (_activities.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Text(
              '기록을 추가해주세요',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
            ),
          )
        else
          ..._activities.map((record) => _buildActivityItem(record)),

        // 기록 추가 버튼
        InkWell(
          onTap: _showAddActivitySheet,
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
                  '기록 추가',
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

  Widget _buildActivityItem(RecordData record) {
    final timeStr = _formatTime(record.date);
    final tagLabel = record.tags.isNotEmpty ? record.tags.first.label : '기록';

    return InkWell(
      onTap: () => _editActivity(record),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 10),
        child: Row(
          children: [
            // 시간
            Text(
              timeStr,
              style: AppTextStyles.captionRegular.copyWith(
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // 태그 칩
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
              decoration: const BoxDecoration(
                color: AppColors.chipPrimaryBg,
                borderRadius: AppRadius.xsBorderRadius,
              ),
              child: Text(
                tagLabel,
                style: AppTextStyles.captionMedium.copyWith(
                  color: AppColors.chipPrimaryText,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // 내용
            Expanded(
              child: Text(
                record.content,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMain,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // 삭제 버튼
            GestureDetector(
              onTap: () => _removeActivity(record),
              child: const Icon(
                Icons.close,
                size: 16,
                color: AppColors.textHint,
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
