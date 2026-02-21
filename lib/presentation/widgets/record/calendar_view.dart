import 'package:flutter/material.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_spacing.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';

/// 기록 탭의 캘린더 뷰 타입
enum CalendarViewType { weekly, monthly }

/// 기록 홈 캘린더 뷰
///
/// 월간/주간 캘린더 그리드, 요일 헤더, 월 네비게이션, 드래그 핸들을 포함.
/// 드래그 높이 애니메이션은 부모에서 관리하고, 이 위젯은 그리드 렌더링만 담당.
class CalendarView extends StatelessWidget {
  final DateTime currentMonth;
  final DateTime selectedDate;
  final CalendarViewType viewType;
  final double calendarHeight;
  final bool Function(DateTime date) hasRecord;
  final void Function(DateTime date) onDateSelected;
  final void Function(int delta) onMonthChanged;
  final VoidCallback onToggleViewType;
  final GestureDragStartCallback onDragStart;
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;
  final VoidCallback onScheduleAdd;

  /// 월 네비게이션 버튼의 opacity (0.0 ~ 1.0)
  final double navButtonOpacity;

  /// 월 네비게이션 버튼 터치 가능 여부
  final bool showNavButtons;

  const CalendarView({
    super.key,
    required this.currentMonth,
    required this.selectedDate,
    required this.viewType,
    required this.calendarHeight,
    required this.hasRecord,
    required this.onDateSelected,
    required this.onMonthChanged,
    required this.onToggleViewType,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onScheduleAdd,
    required this.navButtonOpacity,
    required this.showNavButtons,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundSurface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
          child: Column(
            children: [
              _buildMonthHeader(),
              const SizedBox(height: AppSpacing.xxl),
              _buildWeekdayHeader(),
              const SizedBox(height: AppSpacing.sm),
              ClipRect(
                child: SizedBox(
                  height: calendarHeight,
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: _buildMonthlyCalendar(),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildDragHandle(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          AnimatedOpacity(
            opacity: navButtonOpacity,
            duration: const Duration(milliseconds: 100),
            child: GestureDetector(
              onTap: showNavButtons ? () => onMonthChanged(-1) : null,
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.chevron_left,
                  color: AppColors.textSubtle,
                  size: 24,
                ),
              ),
            ),
          ),
          Text(
            '${currentMonth.month}월',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          AnimatedOpacity(
            opacity: navButtonOpacity,
            duration: const Duration(milliseconds: 100),
            child: GestureDetector(
              onTap: showNavButtons ? () => onMonthChanged(1) : null,
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.chevron_right,
                  color: AppColors.textSubtle,
                  size: 24,
                ),
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onScheduleAdd,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.chipPrimaryBg,
                borderRadius: AppRadius.smBorderRadius,
              ),
              child: const Icon(
                Icons.notifications_outlined,
                color: AppColors.brand,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeader() {
    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: weekdays.asMap().entries.map((entry) {
          final index = entry.key;
          final day = entry.value;
          final isSunday = index == 0;

          return SizedBox(
            width: 40,
            height: 32,
            child: Center(
              child: Text(
                day,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isSunday ? AppColors.error : AppColors.textHint,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMonthlyCalendar() {
    final weeks = _getMonthWeeks(currentMonth);

    int selectedWeekIndex = 0;
    for (int i = 0; i < weeks.length; i++) {
      if (weeks[i].any(
        (date) =>
            date != null &&
            date.year == selectedDate.year &&
            date.month == selectedDate.month &&
            date.day == selectedDate.day,
      )) {
        selectedWeekIndex = i;
        break;
      }
    }

    final orderedWeeks = <List<DateTime?>>[];
    for (int i = 0; i < weeks.length; i++) {
      final index = (selectedWeekIndex + i) % weeks.length;
      orderedWeeks.add(weeks[index]);
    }

    final isMonthlyExpanded = showNavButtons;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
      child: Column(
        children: (isMonthlyExpanded ? weeks : orderedWeeks)
            .map((week) => _buildWeekRow(week))
            .toList(),
      ),
    );
  }

  Widget _buildWeekRow(List<DateTime?> dates) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: dates.map((date) {
          if (date == null) {
            return const SizedBox(width: 40, height: 40);
          }
          return _buildDateCell(date);
        }).toList(),
      ),
    );
  }

  Widget _buildDateCell(DateTime date) {
    final isSelected = _isSameDay(date, selectedDate);
    final isCurrentMonth = date.month == currentMonth.month;
    final isSunday = date.weekday == DateTime.sunday;
    final hasRecordOnDate = hasRecord(date);
    final isFuture = date.isAfter(DateTime.now());

    Color textColor;
    if (!isCurrentMonth || isFuture) {
      textColor = isSunday ? AppColors.sundayLight : AppColors.disabledText;
    } else if (isSunday) {
      textColor = AppColors.error;
    } else {
      textColor = AppColors.textMain;
    }

    final bool isTappable = !isFuture;

    return GestureDetector(
      onTap: isTappable ? () => onDateSelected(date) : null,
      child: Opacity(
        opacity: isFuture ? 0.4 : 1.0,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: isSelected ? 22 : 20,
                height: isSelected ? 22 : 20,
                decoration: isSelected
                    ? BoxDecoration(
                        color: AppColors.brand,
                        borderRadius: BorderRadius.circular(11),
                      )
                    : null,
                alignment: Alignment.center,
                child: Text(
                  '${date.day}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isSelected ? AppColors.textInverse : textColor,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              if (hasRecordOnDate && isCurrentMonth && !isFuture)
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.brand,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return GestureDetector(
      onTap: onToggleViewType,
      onVerticalDragStart: onDragStart,
      onVerticalDragUpdate: onDragUpdate,
      onVerticalDragEnd: onDragEnd,
      child: Container(
        width: double.infinity,
        height: 24,
        color: Colors.transparent,
        alignment: Alignment.center,
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }

  // 헬퍼 메서드들
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<List<DateTime?>> _getMonthWeeks(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);

    final List<List<DateTime?>> weeks = [];
    List<DateTime?> currentWeek = List.filled(7, null);

    final firstWeekday = firstDay.weekday % 7;
    if (firstWeekday > 0) {
      for (int i = 0; i < firstWeekday; i++) {
        final prevDate = firstDay.subtract(Duration(days: firstWeekday - i));
        currentWeek[i] = prevDate;
      }
    }

    for (int day = 1; day <= lastDay.day; day++) {
      final date = DateTime(month.year, month.month, day);
      final weekday = date.weekday % 7;

      currentWeek[weekday] = date;

      if (weekday == 6 || day == lastDay.day) {
        if (day == lastDay.day && weekday < 6) {
          for (int i = weekday + 1; i <= 6; i++) {
            final nextDate = lastDay.add(Duration(days: i - weekday));
            currentWeek[i] = nextDate;
          }
        }
        weeks.add(currentWeek);
        currentWeek = List.filled(7, null);
      }
    }

    return weeks;
  }
}
