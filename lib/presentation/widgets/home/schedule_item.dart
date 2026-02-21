import 'package:flutter/material.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';

/// 일정 데이터 모델
class ScheduleData {
  final String id;
  final String time;
  final String title;
  final String aquariumName;
  final bool isCompleted;

  const ScheduleData({
    required this.id,
    required this.time,
    required this.title,
    required this.aquariumName,
    this.isCompleted = false,
  });

  ScheduleData copyWith({bool? isCompleted}) {
    return ScheduleData(
      id: id,
      time: time,
      title: title,
      aquariumName: aquariumName,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// 일정 아이템 위젯
///
/// 오늘 일정 섹션에서 사용되는 체크리스트 아이템
class ScheduleItem extends StatelessWidget {
  const ScheduleItem({
    super.key,
    required this.data,
    this.onCheckChanged,
    this.onTap,
  });

  final ScheduleData data;
  final ValueChanged<bool>? onCheckChanged;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.backgroundSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            // 시간
            SizedBox(
              width: 50,
              child: Text(
                data.time,
                style: AppTextStyles.captionMedium.copyWith(
                  color: AppColors.textSubtle,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // 할일 내용
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: AppTextStyles.bodyMediumBold.copyWith(
                      decoration: data.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: data.isCompleted
                          ? AppColors.textSubtle
                          : AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.water_drop_outlined,
                        size: 12,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        data.aquariumName,
                        style: AppTextStyles.captionRegular.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 체크박스
            Transform.scale(
              scale: 1.1,
              child: Checkbox(
                value: data.isCompleted,
                onChanged: (value) => onCheckChanged?.call(value ?? false),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 일정 리스트 위젯
class ScheduleList extends StatelessWidget {
  const ScheduleList({
    super.key,
    required this.schedules,
    this.onCheckChanged,
    this.onItemTap,
  });

  final List<ScheduleData> schedules;
  final void Function(ScheduleData, bool)? onCheckChanged;
  final void Function(ScheduleData)? onItemTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: schedules.map((schedule) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ScheduleItem(
              data: schedule,
              onCheckChanged: (value) => onCheckChanged?.call(schedule, value),
              onTap: () => onItemTap?.call(schedule),
            ),
          );
        }).toList(),
      ),
    );
  }
}
