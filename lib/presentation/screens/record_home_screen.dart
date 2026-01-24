import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/models/record_data.dart';
import '../../domain/models/aquarium_data.dart';
import '../../data/services/aquarium_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../viewmodels/record_home_viewmodel.dart';
import '../viewmodels/record_viewmodel.dart';
import '../widgets/record/activity_add_bottom_sheet.dart';

/// 기록 탭의 캘린더 뷰 타입
enum CalendarViewType { weekly, monthly }

/// 기록 홈 화면
///
/// 주요 기능:
/// - 월간/주간 캘린더 뷰 전환
/// - 날짜 선택시 어항별 체크리스트 표시 (아코디언)
/// - 할 일 선택 시 즉시 저장
class RecordHomeScreen extends StatefulWidget {
  const RecordHomeScreen({super.key});

  @override
  RecordHomeScreenState createState() => RecordHomeScreenState();
}

class RecordHomeScreenState extends State<RecordHomeScreen>
    with TickerProviderStateMixin {
  CalendarViewType _viewType = CalendarViewType.weekly;
  DateTime _currentMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();

  late RecordHomeViewModel _viewModel;
  late RecordViewModel _recordViewModel;

  // 어항 목록
  List<AquariumData> _aquariums = [];
  bool _isLoadingAquariums = true;

  // 어항별 펼침 상태
  final Map<String, bool> _expandedAquariums = {};

  // 어항별 저장된 기록 태그
  final Map<String, Set<RecordTag>> _savedTagsByAquarium = {};

  // 드래그 애니메이션 관련
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;
  double _dragStartY = 0;
  bool _isDragging = false;
  static const double _weeklyHeight = 46.0;
  static const double _monthlyHeight = 276.0;

  @override
  void initState() {
    super.initState();
    _viewModel = RecordHomeViewModel();
    _recordViewModel = RecordViewModel();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _heightAnimation = Tween<double>(begin: _weeklyHeight, end: _weeklyHeight)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _loadData();
    _loadAquariums();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _viewModel.dispose();
    _recordViewModel.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _viewModel.loadRecordDatesInMonth(_currentMonth);
    await _viewModel.loadRecordsByDate(_selectedDate);
  }

  Future<void> _loadAquariums() async {
    try {
      final aquariums = await AquariumService.instance.getAllAquariums();
      if (mounted) {
        setState(() {
          _aquariums = aquariums;
          for (final aquarium in aquariums) {
            final id = aquarium.id ?? '';
            _expandedAquariums[id] = false; // 처음엔 모두 접힌 상태
            _savedTagsByAquarium[id] = {};
          }
          _isLoadingAquariums = false;
        });
      }
    } catch (e) {
      AppLogger.data('Error loading aquariums: $e', isError: true);
      if (mounted) {
        setState(() {
          _isLoadingAquariums = false;
        });
      }
    }
  }

  void refreshData() {
    _viewModel.refresh(_currentMonth, _selectedDate);
    _loadAquariums();
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      // 날짜 변경 시 저장된 태그 초기화
      for (final key in _savedTagsByAquarium.keys) {
        _savedTagsByAquarium[key] = {};
      }
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
    final targetHeight = _viewType == CalendarViewType.weekly
        ? _monthlyHeight
        : _weeklyHeight;

    _heightAnimation =
        Tween<double>(begin: _heightAnimation.value, end: targetHeight).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward(from: 0).then((_) {
      setState(() {
        _viewType = _viewType == CalendarViewType.weekly
            ? CalendarViewType.monthly
            : CalendarViewType.weekly;
      });
    });
  }

  void _onDragStart(DragStartDetails details) {
    _dragStartY = details.globalPosition.dy;
    _isDragging = true;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    final delta = details.globalPosition.dy - _dragStartY;
    final currentHeight = _viewType == CalendarViewType.weekly
        ? _weeklyHeight
        : _monthlyHeight;

    double newHeight = currentHeight + delta * 0.5;
    newHeight = newHeight.clamp(_weeklyHeight, _monthlyHeight);

    _heightAnimation = AlwaysStoppedAnimation(newHeight);
    setState(() {});
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;

    final currentHeight = _heightAnimation.value;
    final threshold = (_weeklyHeight + _monthlyHeight) / 2;

    final targetViewType = currentHeight > threshold
        ? CalendarViewType.monthly
        : CalendarViewType.weekly;

    final targetHeight = targetViewType == CalendarViewType.monthly
        ? _monthlyHeight
        : _weeklyHeight;

    _heightAnimation = Tween<double>(begin: currentHeight, end: targetHeight)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward(from: 0).then((_) {
      setState(() {
        _viewType = targetViewType;
      });
    });
  }

  /// 어항 섹션 펼침/접힘 토글
  void _toggleAquariumExpanded(String aquariumId) {
    setState(() {
      _expandedAquariums[aquariumId] =
          !(_expandedAquariums[aquariumId] ?? false);
    });
  }

  /// 할 일 추가 (바텀시트) - 선택 시 즉시 저장
  Future<void> _showAddActivitySheet(
    String aquariumId,
    String? aquariumName,
  ) async {
    final selectedTags = await ActivityAddBottomSheet.show(
      context,
      selectedDate: _selectedDate,
    );

    if (selectedTags != null && selectedTags.isNotEmpty && mounted) {
      // 즉시 저장
      await _saveRecordImmediately(aquariumId, aquariumName, selectedTags);
    }
  }

  /// 즉시 저장
  Future<void> _saveRecordImmediately(
    String aquariumId,
    String? aquariumName,
    List<RecordTag> tags,
  ) async {
    // content는 필수 필드이므로 태그 라벨들을 사용
    final content = tags.map((t) => t.label).join(', ');

    final success = await _recordViewModel.saveRecord(
      date: _selectedDate,
      tags: tags,
      content: content,
      isPublic: false,
      aquariumId: aquariumId,
    );

    if (mounted) {
      if (success) {
        setState(() {
          final currentTags = _savedTagsByAquarium[aquariumId] ?? {};
          currentTags.addAll(tags);
          _savedTagsByAquarium[aquariumId] = currentTags;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${aquariumName ?? '어항'}에 기록이 저장되었습니다.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textInverse,
              ),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        // 캘린더 점 업데이트
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _recordViewModel.errorMessage ?? '저장 중 오류가 발생했습니다.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textInverse,
              ),
            ),
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

                // 하단 어항별 아코디언 영역
                Expanded(child: _buildRecordContent(viewModel)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCalendarCard(RecordHomeViewModel viewModel) {
    return AnimatedBuilder(
      animation: _heightAnimation,
      builder: (context, child) {
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
                  _buildMonthHeader(),
                  const SizedBox(height: 24),
                  _buildWeekdayHeader(),
                  const SizedBox(height: 8),
                  ClipRect(
                    child: SizedBox(
                      height: _heightAnimation.value,
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: _buildMonthlyCalendar(viewModel),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDragHandle(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthHeader() {
    final showNavButtons =
        _heightAnimation.value > (_weeklyHeight + _monthlyHeight) / 2;
    final navButtonOpacity =
        ((_heightAnimation.value - _weeklyHeight) /
                (_monthlyHeight - _weeklyHeight))
            .clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          AnimatedOpacity(
            opacity: navButtonOpacity,
            duration: const Duration(milliseconds: 100),
            child: GestureDetector(
              onTap: showNavButtons ? () => _onMonthChanged(-1) : null,
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
            '${_currentMonth.month}월',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          AnimatedOpacity(
            opacity: navButtonOpacity,
            duration: const Duration(milliseconds: 100),
            child: GestureDetector(
              onTap: showNavButtons ? () => _onMonthChanged(1) : null,
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
            onTap: _navigateToScheduleAdd,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.chipPrimaryBg,
                borderRadius: BorderRadius.circular(8),
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

  Future<void> _navigateToScheduleAdd() async {
    final result = await Navigator.pushNamed(context, '/schedule/add');
    if (result == true && mounted) {
      _loadData();
    }
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

    int selectedWeekIndex = 0;
    for (int i = 0; i < weeks.length; i++) {
      if (weeks[i].any(
        (date) =>
            date != null &&
            date.year == _selectedDate.year &&
            date.month == _selectedDate.month &&
            date.day == _selectedDate.day,
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

    final isMonthlyExpanded =
        _heightAnimation.value > (_weeklyHeight + _monthlyHeight) / 2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: (isMonthlyExpanded ? weeks : orderedWeeks)
            .map((week) => _buildWeekRow(week, viewModel))
            .toList(),
      ),
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
      textColor = isSunday ? const Color(0xFFFF9F8D) : AppColors.disabledText;
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

  Widget _buildDragHandle() {
    return GestureDetector(
      onTap: _toggleViewType,
      onVerticalDragStart: _onDragStart,
      onVerticalDragUpdate: _onDragUpdate,
      onVerticalDragEnd: _onDragEnd,
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

  Widget _buildRecordContent(RecordHomeViewModel viewModel) {
    return Column(
      children: [
        // 날짜 헤더
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Row(
            children: [
              Text(
                _getFormattedDate(_selectedDate),
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // 어항별 아코디언
        Expanded(
          child: _isLoadingAquariums
              ? const Center(child: CircularProgressIndicator())
              : _aquariums.isEmpty
              ? _buildEmptyAquariumState()
              : _buildAquariumAccordionView(),
        ),
      ],
    );
  }

  Widget _buildEmptyAquariumState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.water_drop_outlined, size: 48, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text(
            '등록된 어항이 없어요',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSubtle,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/aquarium/register');
            },
            child: Text(
              '어항 등록하기',
              style: AppTextStyles.bodyMediumMedium.copyWith(
                color: AppColors.brand,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAquariumAccordionView() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _aquariums.length,
      itemBuilder: (context, index) {
        return _buildAquariumAccordionItem(_aquariums[index]);
      },
    );
  }

  Widget _buildAquariumAccordionItem(AquariumData aquarium) {
    final aquariumId = aquarium.id ?? '';
    final isExpanded = _expandedAquariums[aquariumId] ?? false;
    final savedTags = _savedTagsByAquarium[aquariumId] ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          // 어항 헤더 (탭하면 펼침/접힘)
          InkWell(
            onTap: () => _toggleAquariumExpanded(aquariumId),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.chipPrimaryBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.water_drop,
                      color: AppColors.brand,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      aquarium.name ?? '이름 없음',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // 저장된 태그 수 표시
                  if (savedTags.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brand.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${savedTags.length}개 완료',
                        style: AppTextStyles.captionMedium.copyWith(
                          color: AppColors.brand,
                        ),
                      ),
                    ),
                  // 펼침/접힘 아이콘
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.textSubtle,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 펼쳐진 내용 (애니메이션)
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildExpandedContent(
              aquariumId,
              aquarium.name,
              savedTags,
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(
    String aquariumId,
    String? aquariumName,
    Set<RecordTag> savedTags,
  ) {
    return Column(
      children: [
        const Divider(height: 1, color: AppColors.borderLight),

        // 저장된 태그 목록
        if (savedTags.isNotEmpty)
          ...savedTags.map((tag) => _buildSavedTagItem(tag)),

        // 할 일 추가 버튼
        InkWell(
          onTap: () => _showAddActivitySheet(aquariumId, aquariumName),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: savedTags.isNotEmpty
                ? const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.borderLight),
                    ),
                  )
                : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  size: 18,
                  color: AppColors.brand,
                ),
                const SizedBox(width: 8),
                Text(
                  '할 일 추가',
                  style: AppTextStyles.bodyMediumMedium.copyWith(
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

  Widget _buildSavedTagItem(RecordTag tag) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // 완료 체크 아이콘
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tag.label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSubtle,
                decoration: TextDecoration.lineThrough,
              ),
            ),
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
