import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/di/app_dependencies.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/models/aquarium_data.dart';
import '../../domain/models/creature_data.dart';
import '../../domain/models/record_data.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_spacing.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';
import '../viewmodels/record_home_viewmodel.dart';
import '../viewmodels/record_viewmodel.dart';
import '../widgets/record/aquarium_accordion.dart';
import '../widgets/record/calendar_view.dart';

/// 기록 홈 화면
///
/// 주요 기능:
/// - 월간/주간 캘린더 뷰 전환
/// - 날짜 선택시 어항별 아코디언 표시
/// - 어항 펼침 → 생물 탭 + 할 일/기록/일기 스와이프 탭
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

  late AppDependencies _dependencies;
  late RecordHomeViewModel _viewModel;
  late RecordViewModel _recordViewModel;

  // 어항 목록
  List<AquariumData> _aquariums = [];
  bool _isLoadingAquariums = true;

  // 어항별 펼침 상태
  final Map<String, bool> _expandedAquariums = {};

  // 어항별 생물 캐시
  final Map<String, List<CreatureData>> _creaturesByAquarium = {};

  // 어항별 선택 생물 (null = "전체")
  final Map<String, String?> _selectedCreatureByAquarium = {};

  // 어항별 할 일 완료 상태: {aquariumId: {total: n, completed: n}}
  final Map<String, Map<String, int>> _todoStatusByAquarium = {};

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
    _dependencies = context.read<AppDependencies>();
    _viewModel = _dependencies.createRecordHomeViewModel();
    _recordViewModel = _dependencies.createRecordViewModel();

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
    await _loadTodoStatus();
  }

  Future<void> _loadTodoStatus() async {
    for (final aquarium in _aquariums) {
      final aquariumId = aquarium.id ?? '';
      if (aquariumId.isEmpty) continue;
      try {
        final todos = await _recordViewModel.getRecordsByCreature(
          _selectedDate,
          aquariumId,
          recordType: RecordType.todo,
        );
        if (mounted) {
          setState(() {
            _todoStatusByAquarium[aquariumId] = {
              'total': todos.length,
              'completed': todos.where((t) => t.isCompleted).length,
            };
          });
        }
      } catch (e) {
        AppLogger.data('Error loading todo status: $e', isError: true);
      }
    }
  }

  Future<void> _loadAquariums() async {
    try {
      final aquariums = await _dependencies.aquariumService.getAllAquariums();
      if (mounted) {
        setState(() {
          _aquariums = aquariums;
          for (final aquarium in aquariums) {
            final id = aquarium.id ?? '';
            _expandedAquariums[id] = false;
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

  Future<void> _loadCreaturesForAquarium(String aquariumId) async {
    if (_creaturesByAquarium.containsKey(aquariumId)) return;

    try {
      final creatures = await _dependencies.creatureService
          .getCreaturesByAquarium(aquariumId);
      if (mounted) {
        setState(() {
          _creaturesByAquarium[aquariumId] = creatures;
        });
      }
    } catch (e) {
      AppLogger.data('Error loading creatures: $e', isError: true);
      if (mounted) {
        setState(() {
          _creaturesByAquarium[aquariumId] = [];
        });
      }
    }
  }

  void refreshData() {
    _viewModel.refresh(_currentMonth, _selectedDate);
    _loadAquariums();
    _creaturesByAquarium.clear();
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
    final willExpand = !(_expandedAquariums[aquariumId] ?? false);

    setState(() {
      _expandedAquariums[aquariumId] = willExpand;
    });

    if (willExpand) {
      _loadCreaturesForAquarium(aquariumId);
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
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.backgroundApp,
                    Color(0xFFE8F0FE),
                    Color(0xFFD4E4FC),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
              child: Column(
                children: [
                  _buildCalendarSection(viewModel),
                  Expanded(child: _buildRecordContent()),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCalendarSection(RecordHomeViewModel viewModel) {
    final navButtonOpacity =
        ((_heightAnimation.value - _weeklyHeight) /
                (_monthlyHeight - _weeklyHeight))
            .clamp(0.0, 1.0);
    final showNavButtons =
        _heightAnimation.value > (_weeklyHeight + _monthlyHeight) / 2;

    return AnimatedBuilder(
      animation: _heightAnimation,
      builder: (context, child) {
        return CalendarView(
          currentMonth: _currentMonth,
          selectedDate: _selectedDate,
          viewType: _viewType,
          calendarHeight: _heightAnimation.value,
          hasRecord: viewModel.hasRecordOnDate,
          onDateSelected: _onDateSelected,
          onMonthChanged: _onMonthChanged,
          onToggleViewType: _toggleViewType,
          onDragStart: _onDragStart,
          onDragUpdate: _onDragUpdate,
          onDragEnd: _onDragEnd,
          navButtonOpacity: navButtonOpacity,
          showNavButtons: showNavButtons,
        );
      },
    );
  }

  Widget _buildRecordContent() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, AppSpacing.lg),
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
          const SizedBox(height: AppSpacing.lg),
          Text(
            '등록된 어항이 없어요',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSubtle,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/aquarium/register');
            },
            child: Text(
              '어항 등록하기',
              style: AppTextStyles.bodyMediumBold.copyWith(
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: _aquariums.length,
      itemBuilder: (context, index) {
        final aquarium = _aquariums[index];
        final aquariumId = aquarium.id ?? '';
        final todoStatus = _todoStatusByAquarium[aquariumId];
        return AquariumAccordion(
          aquarium: aquarium,
          isExpanded: _expandedAquariums[aquariumId] ?? false,
          creatures: _creaturesByAquarium[aquariumId] ?? [],
          selectedCreatureId: _selectedCreatureByAquarium[aquariumId],
          selectedDate: _selectedDate,
          recordViewModel: _recordViewModel,
          totalTodos: todoStatus?['total'] ?? 0,
          completedTodos: todoStatus?['completed'] ?? 0,
          onToggle: () => _toggleAquariumExpanded(aquariumId),
          onCreatureSelected: (creatureId) {
            setState(() {
              _selectedCreatureByAquarium[aquariumId] = creatureId;
            });
          },
          onDataChanged: _loadData,
        );
      },
    );
  }
}
