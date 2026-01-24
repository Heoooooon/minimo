import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../domain/models/schedule_data.dart';
import '../common/skeleton_loader.dart';

/// 홈 화면 일정 섹션 (타임라인 형식)
///
/// 오늘 날짜와 할 일 목록을 타임라인 형태로 표시
class HomeScheduleSection extends StatelessWidget {
  const HomeScheduleSection({
    super.key,
    required this.scheduleItems,
    required this.hasAquariums,
    this.isLoading = false,
    this.onToggleComplete,
    this.onAddScheduleTap,
    this.onExpandTap,
  });

  /// 일정 데이터 리스트
  final List<ScheduleData> scheduleItems;

  /// 어항 보유 여부
  final bool hasAquariums;

  /// 로딩 상태
  final bool isLoading;

  /// 완료 토글 콜백
  final void Function(String id, bool value)? onToggleComplete;

  /// 스케줄 추가 버튼 콜백
  final VoidCallback? onAddScheduleTap;

  /// 펼치기 버튼 콜백
  final VoidCallback? onExpandTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.backgroundApp,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 4, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Header
            _buildDateHeader(),
            const SizedBox(height: 17),

            // Timeline Items
            if (isLoading)
              const ScheduleSkeleton()
            else if (scheduleItems.isEmpty || !hasAquariums)
              _buildEmptyTimeline()
            else
              _buildTimelineItems(),

            // Expand Button
            _buildExpandButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader() {
    final now = DateTime.now();
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[now.weekday - 1];

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${now.day}일 ($weekday)',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              height: 26 / 18,
              letterSpacing: -0.5,
              color: AppColors.textMain,
            ),
          ),
          // 스케줄 추가 버튼
          if (hasAquariums)
            GestureDetector(
              onTap: onAddScheduleTap,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.chipPrimaryBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add, color: AppColors.brand, size: 20),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyTimeline() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Text(
            '오늘 할 일이 비어있어요',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
          ),
          const SizedBox(height: 4),
          Text(
            '어항을 등록한 후 할 일을 추가해 보세요',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItems() {
    return Column(
      children: scheduleItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isLast = index == scheduleItems.length - 1;
        return _ScheduleTimelineItem(
          item: item,
          isLast: isLast,
          onToggle: (value) => onToggleComplete?.call(item.id, value),
        );
      }).toList(),
    );
  }

  Widget _buildExpandButton() {
    return Center(
      child: GestureDetector(
        onTap: onExpandTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFFDFDFF),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.textHint,
            size: 24,
          ),
        ),
      ),
    );
  }
}

/// 타임라인 아이템 위젯
class _ScheduleTimelineItem extends StatelessWidget {
  const _ScheduleTimelineItem({
    required this.item,
    required this.isLast,
    this.onToggle,
  });

  final ScheduleData item;
  final bool isLast;
  final void Function(bool)? onToggle;

  @override
  Widget build(BuildContext context) {
    final amPm = item.time.contains('오전') ? '오전' : '오전';
    final time = item.time.replaceAll('오전 ', '').replaceAll('오후 ', '');

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 17),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline Indicator (Circle + Line)
            SizedBox(
              width: 12,
              child: Column(
                children: [
                  const SizedBox(height: 4),
                  // Circle
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFB6E4FF),
                      border: Border.all(
                        color: const Color(0xFFD6EEFF),
                        width: 1,
                      ),
                    ),
                  ),
                  // Vertical Line
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 1,
                        margin: const EdgeInsets.only(top: 4),
                        color: const Color(0xFFD6EEFF),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Time
            SizedBox(
              width: 60,
              child: Row(
                children: [
                  Text(
                    amPm,
                    style: AppTextStyles.captionRegular.copyWith(
                      color: AppColors.textSubtle,
                      fontSize: 12,
                      height: 18 / 12,
                      letterSpacing: -0.25,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    time,
                    style: AppTextStyles.captionRegular.copyWith(
                      color: AppColors.textSubtle,
                      fontSize: 12,
                      height: 18 / 12,
                      letterSpacing: -0.25,
                    ),
                  ),
                ],
              ),
            ),

            // Task Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTextStyles.bodyMediumMedium.copyWith(
                      color: AppColors.textMain,
                      fontSize: 16,
                      height: 24 / 16,
                      letterSpacing: -0.5,
                      decoration: item.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.aquariumName,
                    style: AppTextStyles.captionRegular.copyWith(
                      color: AppColors.textHint,
                      fontSize: 12,
                      height: 18 / 12,
                      letterSpacing: -0.25,
                    ),
                  ),
                ],
              ),
            ),

            // Checkbox
            GestureDetector(
              onTap: () => onToggle?.call(!item.isCompleted),
              child: Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(8),
                child: Container(
                  width: 19,
                  height: 19,
                  decoration: BoxDecoration(
                    color: item.isCompleted ? AppColors.brand : Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: item.isCompleted
                          ? AppColors.brand
                          : AppColors.border,
                      width: 1,
                    ),
                  ),
                  child: item.isCompleted
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
