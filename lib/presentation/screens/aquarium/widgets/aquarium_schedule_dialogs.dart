import 'package:flutter/material.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import '../../../../domain/models/schedule_data.dart';

/// 스케줄 옵션 바텀시트 표시
void showScheduleOptionsSheet(
  BuildContext context, {
  required ScheduleData schedule,
  required VoidCallback onDelete,
}) {
  showModalBottomSheet(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('알림 삭제', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              onDelete();
            },
          ),
        ],
      ),
    ),
  );
}

/// 스케줄 삭제 확인 다이얼로그 (Dismissible용)
Future<bool?> showScheduleDeleteConfirmDialog(
  BuildContext context, {
  required ScheduleData schedule,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('알림 삭제'),
      content: Text('"${schedule.title}" 알림을 삭제할까요?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('삭제'),
        ),
      ],
    ),
  );
}

/// 스케줄 삭제 확인 다이얼로그 (일반용)
void showScheduleConfirmDeleteDialog(
  BuildContext context, {
  required ScheduleData schedule,
  required VoidCallback onDelete,
}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('알림 삭제'),
      content: Text('"${schedule.title}" 알림을 삭제하시겠습니까?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onDelete();
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('삭제'),
        ),
      ],
    ),
  );
}
