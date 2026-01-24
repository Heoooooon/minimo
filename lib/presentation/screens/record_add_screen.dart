import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/models/record_data.dart';
import '../../domain/models/aquarium_data.dart';
import '../../domain/models/schedule_data.dart';
import '../../data/services/aquarium_service.dart';
import '../../data/services/schedule_service.dart';
import '../../data/services/notification_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../viewmodels/record_viewmodel.dart';
import '../widgets/common/app_button.dart';
import '../widgets/common/app_chip.dart';
import '../widgets/schedule/repeat_cycle_selector.dart';

/// 기록 추가 화면
///
/// 주요 기능:
/// - Chips를 사용하여 태그 선택 기능
/// - Switch를 사용하여 '공개 여부' 설정
/// - Medium Round Button으로 저장 액션
class RecordAddScreen extends StatefulWidget {
  final DateTime? initialDate;

  const RecordAddScreen({super.key, this.initialDate});

  @override
  State<RecordAddScreen> createState() => _RecordAddScreenState();
}

class _RecordAddScreenState extends State<RecordAddScreen> {
  final TextEditingController _contentController = TextEditingController();
  final Set<RecordTag> _selectedTags = {};
  bool _isPublic = true;
  DateTime _selectedDate = DateTime.now();

  // 어항 선택 관련
  List<AquariumData> _aquariums = [];
  AquariumData? _selectedAquarium;
  bool _isLoadingAquariums = true;

  // 스케줄 연동 관련
  bool _registerSchedule = false;
  RepeatCycle _selectedRepeatCycle = RepeatCycle.daily;
  TimeOfDay _scheduleTime = TimeOfDay.now();

  late RecordViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = RecordViewModel();
    if (widget.initialDate != null) {
      _selectedDate = widget.initialDate!;
    }
    _loadAquariums();
  }

  Future<void> _loadAquariums() async {
    try {
      final aquariums = await AquariumService.instance.getAllAquariums();
      if (mounted) {
        setState(() {
          _aquariums = aquariums;
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

  @override
  void dispose() {
    _contentController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _selectedAquarium != null &&
        _selectedTags.isNotEmpty &&
        _contentController.text.isNotEmpty;
  }

  Future<void> _handleSave() async {
    if (!_isFormValid) return;

    final success = await _viewModel.saveRecord(
      date: _selectedDate,
      tags: _selectedTags.toList(),
      content: _contentController.text,
      isPublic: _isPublic,
      aquariumId: _selectedAquarium?.id,
    );

    if (success && mounted) {
      // 스케줄 연동 처리
      if (_registerSchedule && _selectedTags.isNotEmpty) {
        await _createScheduleFromRecord();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _registerSchedule ? '기록과 다음 일정이 저장되었습니다.' : '기록이 저장되었습니다.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textInverse,
            ),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

      Navigator.of(context).pop(true);
    } else if (_viewModel.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_viewModel.errorMessage!),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// 기록에서 스케줄 생성
  Future<void> _createScheduleFromRecord() async {
    try {
      // 첫 번째 태그를 알림 종류로 매핑
      final firstTag = _selectedTags.first;
      final alarmType = _mapTagToAlarmType(firstTag);

      // 다음 일정 날짜 계산
      final nextDate = _calculateNextScheduleDate();

      // 시간 문자열 생성 (HH:mm 형식)
      final timeString =
          '${_scheduleTime.hour.toString().padLeft(2, '0')}:${_scheduleTime.minute.toString().padLeft(2, '0')}';

      final scheduleData = ScheduleData(
        id: '',
        aquariumId: _selectedAquarium?.id,
        date: DateTime(
          nextDate.year,
          nextDate.month,
          nextDate.day,
          _scheduleTime.hour,
          _scheduleTime.minute,
        ),
        time: timeString,
        title: firstTag.label,
        aquariumName: _selectedAquarium?.name ?? '',
        isCompleted: false,
        alarmType: alarmType,
        repeatCycle: _selectedRepeatCycle,
        isNotificationEnabled: true,
      );

      final created = await ScheduleService.instance.createSchedule(
        scheduleData,
      );

      // 푸시 알림 예약
      try {
        await NotificationService.instance.scheduleNotification(
          id: NotificationService.instance.scheduleIdToNotificationId(
            created.id,
          ),
          title: firstTag.label,
          body: '${_selectedAquarium?.name ?? '어항'} - ${alarmType.label}',
          scheduledTime: scheduleData.date,
          repeatCycle: _selectedRepeatCycle,
          payload: created.id,
        );
      } catch (e) {
        AppLogger.data('Notification scheduling failed: $e', isError: true);
      }
    } catch (e) {
      AppLogger.data(
        'Failed to create schedule from record: $e',
        isError: true,
      );
    }
  }

  /// RecordTag를 AlarmType으로 매핑
  AlarmType _mapTagToAlarmType(RecordTag tag) {
    switch (tag) {
      case RecordTag.waterChange:
        return AlarmType.waterChange;
      case RecordTag.feeding:
        return AlarmType.feeding;
      case RecordTag.cleaning:
        return AlarmType.cleaning;
      case RecordTag.waterTest:
        return AlarmType.waterTest;
      case RecordTag.medication:
        return AlarmType.medication;
      default:
        return AlarmType.other;
    }
  }

  /// 반복 주기에 따른 다음 일정 날짜 계산
  DateTime _calculateNextScheduleDate() {
    final now = DateTime.now();
    switch (_selectedRepeatCycle) {
      case RepeatCycle.daily:
        return now.add(const Duration(days: 1));
      case RepeatCycle.everyOtherDay:
        return now.add(const Duration(days: 2));
      case RepeatCycle.weekly:
        return now.add(const Duration(days: 7));
      case RepeatCycle.biweekly:
        return now.add(const Duration(days: 14));
      case RepeatCycle.monthly:
        return DateTime(now.year, now.month + 1, now.day);
      case RepeatCycle.none:
        return now.add(const Duration(days: 1));
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.brand,
              onPrimary: AppColors.textInverse,
              surface: AppColors.backgroundSurface,
              onSurface: AppColors.textMain,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _toggleTag(RecordTag tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<RecordViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('기록하기'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 날짜 선택
                          _buildDateSelector(),
                          const SizedBox(height: 16),

                          // 어항 선택
                          _buildAquariumSelector(),
                          const SizedBox(height: 24),

                          // 태그 선택
                          _buildSectionTitle('태그 선택'),
                          const SizedBox(height: 4),
                          Text(
                            '어떤 활동을 했나요?',
                            style: AppTextStyles.captionRegular.copyWith(
                              color: AppColors.textSubtle,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildTagSelector(),
                          const SizedBox(height: 24),

                          // 내용 입력
                          _buildSectionTitle('기록 내용'),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _contentController,
                            onChanged: (_) => setState(() {}),
                            maxLines: 5,
                            decoration: const InputDecoration(
                              hintText: '오늘의 관리 기록을 남겨보세요',
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // 공개 여부 설정
                          _buildVisibilityToggle(),
                          const SizedBox(height: 16),

                          // 다음 일정 등록 옵션
                          _buildScheduleToggle(),
                        ],
                      ),
                    ),
                  ),

                  // 하단 버튼
                  _buildBottomButton(viewModel),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTextStyles.titleMedium);
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.chipPrimaryBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.calendar_today_rounded,
                color: AppColors.brand,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '기록 날짜',
                    style: AppTextStyles.captionRegular.copyWith(
                      color: AppColors.textSubtle,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일',
                    style: AppTextStyles.bodyMediumMedium,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSubtle),
          ],
        ),
      ),
    );
  }

  Widget _buildTagSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: RecordTag.values.map((tag) {
        final isSelected = _selectedTags.contains(tag);
        // RecordTag.chipType이 없으므로 직접 매핑하거나 모델에 추가해야 함.
        // 여기서는 임시로 매핑 로직 추가 또는 RecordTag 수정 필요.
        // RecordTag enum을 model로 옮기면서 chipType 속성을 제거했었음 (domain layer dependency issue 방지).
        // UI layer에서 매핑하는 것이 좋음.

        AppChipType chipType;
        switch (tag) {
          case RecordTag.waterChange:
          case RecordTag.waterTest:
          case RecordTag.temperatureCheck:
            chipType = AppChipType.primary;
            break;
          case RecordTag.cleaning:
          case RecordTag.fishAdded:
          case RecordTag.plantCare:
            chipType = AppChipType.secondary;
            break;
          case RecordTag.feeding:
            chipType = AppChipType.success;
            break;
          case RecordTag.medication:
            chipType = AppChipType.error;
            break;
          case RecordTag.maintenance:
            chipType = AppChipType.neutral;
            break;
        }

        return AppChip(
          label: tag.label,
          type: chipType,
          isSelected: isSelected,
          onTap: () => _toggleTag(tag),
        );
      }).toList(),
    );
  }

  Widget _buildVisibilityToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('공개 여부', style: AppTextStyles.bodyMediumMedium),
                const SizedBox(height: 4),
                Text(
                  _isPublic ? '다른 사용자들이 이 기록을 볼 수 있어요' : '나만 볼 수 있는 비공개 기록이에요',
                  style: AppTextStyles.captionRegular.copyWith(
                    color: AppColors.textSubtle,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isPublic,
            onChanged: (value) => setState(() => _isPublic = value),
          ),
        ],
      ),
    );
  }

  Widget _buildAquariumSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '어항 선택',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSubtle,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '*',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: _isLoadingAquariums
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('어항 목록 로딩 중...'),
                    ],
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<AquariumData?>(
                    value: _selectedAquarium,
                    isExpanded: true,
                    hint: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('어항을 선택하세요'),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    borderRadius: BorderRadius.circular(12),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.textSubtle,
                    ),
                    items: [
                      ..._aquariums.map((aquarium) {
                        return DropdownMenuItem<AquariumData?>(
                          value: aquarium,
                          child: Row(
                            children: [
                              Icon(
                                Icons.water_drop,
                                size: 20,
                                color: AppColors.brand,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  aquarium.name ?? '이름 없음',
                                  style: AppTextStyles.bodyMedium,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedAquarium = value;
                      });
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildScheduleToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '다음 일정도 등록하기',
                          style: AppTextStyles.bodyMediumMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '이 활동에 대한 정기 알림을 설정해요',
                          style: AppTextStyles.captionRegular.copyWith(
                            color: AppColors.textSubtle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _registerSchedule,
                    onChanged: (value) =>
                        setState(() => _registerSchedule = value),
                    activeTrackColor: AppColors.switchActiveTrack,
                    thumbColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppColors.brand;
                      }
                      return AppColors.textHint;
                    }),
                  ),
                ],
              ),
              // 스케줄 옵션 (토글 활성화 시 표시)
              if (_registerSchedule) ...[
                const Divider(height: 24),
                // 알림 시간 선택
                GestureDetector(
                  onTap: _selectScheduleTime,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: AppColors.textSubtle,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '알림 시간',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSubtle,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatTime(_scheduleTime),
                        style: AppTextStyles.bodyMediumMedium.copyWith(
                          color: AppColors.brand,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.textSubtle,
                        size: 20,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // 반복 주기 선택
                RepeatCycleSelector(
                  selectedCycle: _selectedRepeatCycle,
                  onChanged: (cycle) {
                    setState(() => _selectedRepeatCycle = cycle);
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _selectScheduleTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _scheduleTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.brand,
              onPrimary: AppColors.textInverse,
              surface: AppColors.backgroundSurface,
              onSurface: AppColors.textMain,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _scheduleTime = picked;
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour < 12 ? '오전' : '오후';
    final displayHour = hour <= 12 ? hour : hour - 12;
    return '$period $displayHour:$minute';
  }

  Widget _buildBottomButton(RecordViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: AppButton(
              text: '임시저장',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '임시저장 되었습니다.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMain,
                      ),
                    ),
                    backgroundColor: AppColors.backgroundSurface,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: AppColors.borderLight),
                    ),
                  ),
                );
              },
              size: AppButtonSize.medium,
              shape: AppButtonShape.round,
              variant: AppButtonVariant.outlined,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: AppButton(
              text: '저장하기',
              onPressed: _isFormValid ? _handleSave : null,
              size: AppButtonSize.medium,
              shape: AppButtonShape.round,
              variant: AppButtonVariant.contained,
              isEnabled: _isFormValid,
              isLoading: viewModel.isLoading,
            ),
          ),
        ],
      ),
    );
  }
}
