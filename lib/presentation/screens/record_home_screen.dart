import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/record_repository.dart';
import '../../domain/models/record_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../viewmodels/record_home_viewmodel.dart';
import '../widgets/common/app_button.dart';
import '../widgets/record/activity_add_bottom_sheet.dart';

/// 기록 탭의 캘린더 뷰 타입
enum CalendarViewType { weekly, monthly }

/// 기록 홈 화면
///
/// 주요 기능:
/// - 월간/주간 캘린더 뷰 전환
/// - 날짜 선택시 해당 날짜의 기록 표시
/// - 기록이 있는 날에 파란 점 표시
/// - 기록하기 버튼으로 기록 추가 화면 이동
class RecordHomeScreen extends StatefulWidget {
  const RecordHomeScreen({super.key});

  @override
  State<RecordHomeScreen> createState() => _RecordHomeScreenState();
}

class _RecordHomeScreenState extends State<RecordHomeScreen> {
  CalendarViewType _viewType = CalendarViewType.weekly;
  DateTime _currentMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();

  late RecordHomeViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = RecordHomeViewModel();
    _loadData();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _viewModel.loadRecordDatesInMonth(_currentMonth);
    await _viewModel.loadRecordsByDate(_selectedDate);
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _viewModel.loadRecordsByDate(date);
  }

  void _onMonthChanged(int delta) {
    setState(() {
      _currentMonth = DateTime(
        _currentMonth.year,
        _currentMonth.month + delta,
        1,
      );
    });
    _viewModel.loadRecordDatesInMonth(_currentMonth);
  }

  void _toggleViewType() {
    setState(() {
      _viewType = _viewType == CalendarViewType.weekly
          ? CalendarViewType.monthly
          : CalendarViewType.weekly;
    });
  }

  Future<void> _showActivityBottomSheet() async {
    final selectedTags = await ActivityAddBottomSheet.show(
      context,
      selectedDate: _selectedDate,
    );

    if (selectedTags != null && selectedTags.isNotEmpty && mounted) {
      await _saveRecord(selectedTags);
    }
  }

  Future<void> _saveRecord(List<RecordTag> tags) async {
    try {
      final record = RecordData(
        date: _selectedDate,
        tags: tags,
        content: tags.map((t) => t.label).join(', '),
        isPublic: true,
      );

      await PocketBaseRecordRepository.instance.createRecord(record);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '기록이 추가되었습니다.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textInverse,
              ),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        // 데이터 새로고침
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('기록 저장 중 오류가 발생했습니다: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _getWeekdayName(int weekday) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return weekdays[(weekday - 1) % 7];
  }

  String _getFormattedDate(DateTime date) {
    final weekday = _getWeekdayName(date.weekday);
    return '${date.day}일 $weekday요일';
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<RecordHomeViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            backgroundColor: AppColors.backgroundApp,
            body: Column(
              children: [
                // 상단 캘린더 영역
                _buildCalendarCard(viewModel),

                // 하단 기록 목록 영역
                Expanded(
                  child: _buildRecordContent(viewModel),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCalendarCard(RecordHomeViewModel viewModel) {
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
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Column(
            children: [
              // 월 선택 헤더
              _buildMonthHeader(),
              const SizedBox(height: 24),

              // 요일 헤더
              _buildWeekdayHeader(),
              const SizedBox(height: 8),

              // 날짜 그리드
              _viewType == CalendarViewType.monthly
                  ? _buildMonthlyCalendar(viewModel)
                  : _buildWeeklyCalendar(viewModel),

              const SizedBox(height: 8),

              // 뷰 타입 인디케이터
              _buildViewIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (_viewType == CalendarViewType.monthly) ...[
            // 이전 월 버튼
            GestureDetector(
              onTap: () => _onMonthChanged(-1),
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
          ],
          // 월 표시
          Text(
            '${_currentMonth.month}월',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_viewType == CalendarViewType.monthly) ...[
            // 다음 월 버튼
            GestureDetector(
              onTap: () => _onMonthChanged(1),
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
          ],
        ],
      ),
    );
  }

  Widget _buildWeekdayHeader() {
    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
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

  Widget _buildMonthlyCalendar(RecordHomeViewModel viewModel) {
    final weeks = _getMonthWeeks(_currentMonth);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: weeks.map((week) => _buildWeekRow(week, viewModel)).toList(),
      ),
    );
  }

  Widget _buildWeeklyCalendar(RecordHomeViewModel viewModel) {
    final weekDates = _getCurrentWeekDates();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: _buildWeekRow(weekDates, viewModel),
    );
  }

  Widget _buildWeekRow(List<DateTime?> dates, RecordHomeViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: dates.map((date) {
          if (date == null) {
            return const SizedBox(width: 40, height: 40);
          }
          return _buildDateCell(date, viewModel);
        }).toList(),
      ),
    );
  }

  Widget _buildDateCell(DateTime date, RecordHomeViewModel viewModel) {
    final isSelected = _isSameDay(date, _selectedDate);
    final isCurrentMonth = date.month == _currentMonth.month;
    final isSunday = date.weekday == DateTime.sunday;
    final hasRecord = viewModel.hasRecordOnDate(date);
    final isFuture = date.isAfter(DateTime.now());

    Color textColor;
    if (!isCurrentMonth || isFuture) {
      textColor = isSunday
          ? const Color(0xFFFF9F8D) // 연한 빨강
          : AppColors.disabledText;
    } else if (isSunday) {
      textColor = AppColors.error;
    } else {
      textColor = AppColors.textMain;
    }

    return GestureDetector(
      onTap: () => _onDateSelected(date),
      child: SizedBox(
        width: 40,
        height: 40,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // 날짜
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
            const SizedBox(height: 4),
            // 기록 있음 표시 (파란 점)
            if (hasRecord && isCurrentMonth && !isFuture)
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
    );
  }

  Widget _buildViewIndicator() {
    return GestureDetector(
      onTap: _toggleViewType,
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  Widget _buildRecordContent(RecordHomeViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          // 선택된 날짜 표시
          Text(
            _getFormattedDate(_selectedDate),
            style: AppTextStyles.bodyMediumMedium,
          ),
          const SizedBox(height: 24),
          // 기록 목록 또는 Empty 상태
          Expanded(
            child: viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : viewModel.selectedDateRecords.isEmpty
                    ? _buildEmptyState()
                    : _buildRecordList(viewModel.selectedDateRecords),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '기록이 아직 없어요.\n사육 기록을 추가해보세요!',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSubtle,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 224,
            child: AppButton(
              text: '기록하기',
              onPressed: _showActivityBottomSheet,
              size: AppButtonSize.large,
              shape: AppButtonShape.square,
              variant: AppButtonVariant.contained,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordList(List<RecordData> records) {
    return ListView.builder(
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return _buildRecordItem(record);
      },
    );
  }

  Widget _buildRecordItem(RecordData record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 태그들
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: record.tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.chipPrimaryBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tag.label,
                  style: AppTextStyles.captionMedium.copyWith(
                    color: AppColors.chipPrimaryText,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // 내용
          Text(
            record.content,
            style: AppTextStyles.bodySmall,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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

    // 첫 주의 이전 달 날짜 채우기
    final firstWeekday = firstDay.weekday % 7; // 일요일 = 0
    if (firstWeekday > 0) {
      for (int i = 0; i < firstWeekday; i++) {
        final prevDate = firstDay.subtract(Duration(days: firstWeekday - i));
        currentWeek[i] = prevDate;
      }
    }

    // 현재 달의 날짜 채우기
    for (int day = 1; day <= lastDay.day; day++) {
      final date = DateTime(month.year, month.month, day);
      final weekday = date.weekday % 7;

      currentWeek[weekday] = date;

      if (weekday == 6 || day == lastDay.day) {
        // 마지막 주의 다음 달 날짜 채우기
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

  List<DateTime?> _getCurrentWeekDates() {
    final now = _selectedDate;
    final weekday = now.weekday % 7; // 일요일 = 0

    final List<DateTime?> weekDates = [];
    for (int i = 0; i < 7; i++) {
      weekDates.add(now.subtract(Duration(days: weekday - i)));
    }

    return weekDates;
  }
}
