import 'package:flutter/material.dart';
import '../../../../domain/models/schedule_data.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';
import 'package:cmore_design_system/theme/app_spacing.dart';
import 'package:cmore_design_system/widgets/skeleton_loader.dart';

/// 어항 상세 - 알림 탭
class AquariumSchedulesTab extends StatelessWidget {
  const AquariumSchedulesTab({
    super.key,
    required this.schedules,
    required this.isLoading,
    required this.onToggleNotification,
    required this.onDeleteSchedule,
    required this.onShowOptions,
    required this.onShowDeleteConfirm,
  });

  final List<ScheduleData> schedules;
  final bool isLoading;
  final void Function(ScheduleData schedule, bool enabled) onToggleNotification;
  final void Function(ScheduleData schedule) onDeleteSchedule;
  final void Function(ScheduleData schedule) onShowOptions;
  final Future<bool?> Function(ScheduleData schedule) onShowDeleteConfirm;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const ScheduleListSkeleton();
    }

    if (schedules.isEmpty) {
      return _buildEmptyState();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: ListView.builder(
        key: const ValueKey('schedule_content'),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 100,
        ),
        itemCount: schedules.length,
        itemBuilder: (context, index) {
          return _buildScheduleCard(schedules[index]);
        },
      ),
    );
  }

  Widget _buildScheduleCard(ScheduleData schedule) {
    final timeParts = schedule.time.split(':');
    final hour = int.tryParse(timeParts.isNotEmpty ? timeParts[0] : '0') ?? 0;
    final minute = int.tryParse(timeParts.length > 1 ? timeParts[1] : '0') ?? 0;
    final isAM = hour < 12;
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final timeString = '$displayHour:${minute.toString().padLeft(2, '0')}';
    final periodString = isAM ? '오전' : '오후';

    return Dismissible(
      key: Key(schedule.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await onShowDeleteConfirm(schedule);
      },
      onDismissed: (direction) {
        onDeleteSchedule(schedule);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        color: AppColors.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: GestureDetector(
        onLongPress: () => onShowOptions(schedule),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: AppColors.backgroundSurface,
            borderRadius: AppRadius.mdBorderRadius,
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    periodString,
                    style: AppTextStyles.captionRegular.copyWith(
                      color: AppColors.textSubtle,
                    ),
                  ),
                  Text(
                    timeString,
                    style: AppTextStyles.displayMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule.title,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.brand,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (schedule.repeatCycle != RepeatCycle.none)
                      Text(
                        schedule.repeatCycle.label,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSubtle,
                        ),
                      ),
                  ],
                ),
              ),
              Switch(
                value: schedule.isNotificationEnabled,
                onChanged: (value) => onToggleNotification(schedule, value),
                activeTrackColor: AppColors.switchActiveTrack,
                inactiveTrackColor: AppColors.switchInactiveTrack,
                thumbColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.brand;
                  }
                  return AppColors.textHint;
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '아직 등록된 알림이 없어요',
            style: AppTextStyles.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            '일정 알림을 등록해 관리 시기를 놓치지 마세요.',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textSubtle,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
