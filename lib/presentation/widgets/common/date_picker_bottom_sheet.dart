import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import 'app_button.dart';

/// 날짜 선택 바텀시트
///
/// table_calendar를 사용한 커스텀 날짜 선택 UI
class DatePickerBottomSheet extends StatefulWidget {
  const DatePickerBottomSheet({
    super.key,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.title = '날짜 선택',
  });

  /// 초기 선택 날짜
  final DateTime? initialDate;

  /// 선택 가능한 첫 날짜
  final DateTime? firstDate;

  /// 선택 가능한 마지막 날짜
  final DateTime? lastDate;

  /// 바텀시트 타이틀
  final String title;

  /// 바텀시트 표시
  static Future<DateTime?> show({
    required BuildContext context,
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    String title = '날짜 선택',
  }) {
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DatePickerBottomSheet(
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
        title: title,
      ),
    );
  }

  @override
  State<DatePickerBottomSheet> createState() => _DatePickerBottomSheetState();
}

class _DatePickerBottomSheetState extends State<DatePickerBottomSheet> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  late DateTime _firstDay;
  late DateTime _lastDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.initialDate;
    _focusedDay = widget.initialDate ?? DateTime.now();
    _firstDay = widget.firstDate ?? DateTime(2000);
    _lastDay = widget.lastDate ?? DateTime.now();
  }

  void _handleConfirm() {
    Navigator.of(context).pop(_selectedDay);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 핸들바
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: AppColors.textSubtle,
                  ),
                ],
              ),
            ),
            // 캘린더
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TableCalendar(
                locale: 'ko_KR',
                firstDay: _firstDay,
                lastDay: _lastDay,
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                calendarFormat: CalendarFormat.month,
                startingDayOfWeek: StartingDayOfWeek.sunday,
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextFormatter: (date, locale) =>
                      DateFormat.yMMMM(locale).format(date),
                  titleTextStyle: AppTextStyles.bodyMediumMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  leftChevronIcon: const Icon(
                    Icons.chevron_left,
                    color: AppColors.textMain,
                  ),
                  rightChevronIcon: const Icon(
                    Icons.chevron_right,
                    color: AppColors.textMain,
                  ),
                  headerPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSubtle,
                    fontWeight: FontWeight.w500,
                  ),
                  weekendStyle: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSubtle,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                calendarStyle: CalendarStyle(
                  // 기본 날짜 스타일
                  defaultTextStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMain,
                  ),
                  weekendTextStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMain,
                  ),
                  // 선택된 날짜
                  selectedDecoration: const BoxDecoration(
                    color: AppColors.brand,
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textInverse,
                    fontWeight: FontWeight.w600,
                  ),
                  // 오늘 날짜
                  todayDecoration: BoxDecoration(
                    color: AppColors.chipPrimaryBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.brand, width: 1),
                  ),
                  todayTextStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.brand,
                    fontWeight: FontWeight.w600,
                  ),
                  // 범위 외 날짜
                  outsideTextStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.disabledText,
                  ),
                  disabledTextStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.disabledText,
                  ),
                  // 셀 마진
                  cellMargin: const EdgeInsets.all(4),
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
              ),
            ),
            // 하단 버튼
            Padding(
              padding: const EdgeInsets.all(20),
              child: AppButton(
                text: '선택 완료',
                onPressed: _selectedDay != null ? _handleConfirm : null,
                size: AppButtonSize.large,
                shape: AppButtonShape.square,
                variant: AppButtonVariant.contained,
                isEnabled: _selectedDay != null,
                expanded: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
