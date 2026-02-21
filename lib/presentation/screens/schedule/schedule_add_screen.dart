import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/utils/app_logger.dart';
import '../../../domain/models/aquarium_data.dart';
import '../../../domain/models/schedule_data.dart';
import '../../../data/services/schedule_service.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/services/aquarium_service.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';
import '../../widgets/schedule/time_picker_widget.dart';
import '../../widgets/schedule/repeat_cycle_selector.dart';

/// 알림 추가 화면
///
/// Figma 디자인 기반 (node-id=56-2747)
/// - 시간 선택: 시(08) : 분(20) + AM/PM 토글
/// - 알림 종류: 드롭다운 (물갈이, 먹이주기, 청소, 수질검사, 투약, 기타)
/// - 알림 이름: 텍스트 입력
/// - 알림 주기: 매일 | 격일 | 매주 | 격주 | 매월
/// - 저장하기 버튼 (폼 완성 시 활성화)
class ScheduleAddScreen extends StatefulWidget {
  const ScheduleAddScreen({super.key});

  @override
  State<ScheduleAddScreen> createState() => _ScheduleAddScreenState();
}

class _ScheduleAddScreenState extends State<ScheduleAddScreen> {
  AquariumData? _aquarium;
  bool _hasAquariumFromArgs = false; // arguments로 어항이 전달되었는지 여부

  // 어항 목록 (arguments가 없을 때 선택용)
  List<AquariumData> _aquariums = [];
  bool _isLoadingAquariums = true;

  // 폼 상태
  int _selectedHour = 8;
  int _selectedMinute = 0;
  bool _isAM = true;
  AlarmType _selectedAlarmType = AlarmType.waterChange;
  final TextEditingController _titleController = TextEditingController();
  RepeatCycle _selectedRepeatCycle = RepeatCycle.daily;
  bool _isNotificationEnabled = true;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // 기본 알림 이름 설정
    _titleController.text = _selectedAlarmType.label;
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is AquariumData && !_hasAquariumFromArgs) {
      _aquarium = args;
      _hasAquariumFromArgs = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  /// 폼 유효성 검사
  bool get _isFormValid {
    return _titleController.text.trim().isNotEmpty;
  }

  /// 24시간 형식으로 변환
  int get _hour24 {
    if (_isAM) {
      return _selectedHour == 12 ? 0 : _selectedHour;
    } else {
      return _selectedHour == 12 ? 12 : _selectedHour + 12;
    }
  }

  /// 시간 문자열 (HH:mm 형식)
  String get _timeString {
    return '${_hour24.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')}';
  }

  /// 알림 저장
  Future<void> _onSave() async {
    if (!_isFormValid || _isSaving) return;

    setState(() => _isSaving = true);

    // 디버깅: 선택된 시간 값 로깅
    AppLogger.data(
      'Time selection - Hour: $_selectedHour, Minute: $_selectedMinute, isAM: $_isAM',
    );
    AppLogger.data(
      'Converted to 24h: $_hour24:${_selectedMinute.toString().padLeft(2, '0')}',
    );

    try {
      // 오늘 날짜 + 선택한 시간으로 DateTime 생성
      final now = DateTime.now();
      final scheduledDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        _hour24,
        _selectedMinute,
      );

      // 디버깅: 스케줄 시간 로깅
      AppLogger.data('Scheduled DateTime: $scheduledDateTime');

      // 일정 데이터 생성
      final scheduleData = ScheduleData(
        id: '', // 서버에서 생성
        aquariumId: _aquarium?.id,
        date: scheduledDateTime,
        time: _timeString,
        title: _titleController.text.trim(),
        aquariumName: _aquarium?.name ?? '',
        isCompleted: false,
        alarmType: _selectedAlarmType,
        repeatCycle: _selectedRepeatCycle,
        isNotificationEnabled: _isNotificationEnabled,
      );

      // 서버에 저장
      final created = await ScheduleService.instance.createSchedule(
        scheduleData,
      );

      // 푸시 알림 예약 (활성화된 경우)
      if (_isNotificationEnabled) {
        // 권한 확인
        final hasPermission = await NotificationService.instance
            .hasPermission();
        if (!hasPermission) {
          final granted = await NotificationService.instance
              .requestPermission();
          if (!granted && mounted) {
            // 권한 거부됨 - 알림 없이 저장할지 확인
            final saveWithoutNotification =
                await _showSaveWithoutNotificationDialog();
            if (saveWithoutNotification != true) {
              setState(() => _isSaving = false);
              return; // 저장 취소
            }
            // 알림 없이 저장 계속 진행 (아래 try 블록 스킵)
          } else {
            // 권한 허용됨 - 알림 예약 진행
            try {
              await NotificationService.instance.scheduleNotification(
                id: NotificationService.instance.scheduleIdToNotificationId(
                  created.id,
                ),
                title: _titleController.text.trim(),
                body:
                    '${_aquarium?.name ?? '어항'} - ${_selectedAlarmType.label}',
                scheduledTime: scheduledDateTime,
                repeatCycle: _selectedRepeatCycle,
                payload: 'schedule:${created.id}:aquarium:${_aquarium?.id ?? ''}',
              );
            } catch (notificationError) {
              AppLogger.data(
                'Notification scheduling failed: $notificationError',
                isError: true,
              );
            }
          }
        } else {
          // 권한 있음 - 알림 예약 진행
          try {
            await NotificationService.instance.scheduleNotification(
              id: NotificationService.instance.scheduleIdToNotificationId(
                created.id,
              ),
              title: _titleController.text.trim(),
              body: '${_aquarium?.name ?? '어항'} - ${_selectedAlarmType.label}',
              scheduledTime: scheduledDateTime,
              repeatCycle: _selectedRepeatCycle,
              payload: created.id,
            );
          } catch (notificationError) {
            AppLogger.data(
              'Notification scheduling failed: $notificationError',
              isError: true,
            );
          }
        }
      }

      if (mounted) {
        // 성공 메시지
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('알림이 등록되었습니다'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      AppLogger.data('Failed to save schedule: $e', isError: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('알림 등록에 실패했습니다: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundSurface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.textMain,
            size: 24,
          ),
        ),
        title: Text('알림 추가', style: AppTextStyles.headlineSmall),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 어항 정보 또는 어항 선택
            if (_hasAquariumFromArgs && _aquarium != null) ...[
              _buildAquariumInfo(),
              const SizedBox(height: 24),
            ] else ...[
              _buildAquariumSelector(),
              const SizedBox(height: 24),
            ],

            // 시간 선택
            _buildSectionTitle('알림 시간'),
            const SizedBox(height: 12),
            _buildTimeSelector(),
            const SizedBox(height: 24),

            // 알림 종류
            AlarmTypeDropdown(
              selectedType: _selectedAlarmType,
              onChanged: (type) {
                setState(() {
                  _selectedAlarmType = type;
                  // 알림 이름을 종류에 맞게 기본값으로 설정
                  if (_titleController.text.isEmpty ||
                      AlarmType.values.any(
                        (t) => t.label == _titleController.text,
                      )) {
                    _titleController.text = type.label;
                  }
                });
              },
            ),
            const SizedBox(height: 24),

            // 알림 이름
            _buildTitleField(),
            const SizedBox(height: 24),

            // 반복 주기
            RepeatCycleSelector(
              selectedCycle: _selectedRepeatCycle,
              onChanged: (cycle) {
                setState(() => _selectedRepeatCycle = cycle);
              },
            ),
            const SizedBox(height: 24),

            // 푸시 알림 토글
            _buildNotificationToggle(),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  Widget _buildAquariumInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.chipPrimaryBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.water_drop, color: AppColors.brand, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _aquarium!.name ?? '어항',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.brand,
                  ),
                ),
                Text(
                  _aquarium!.type?.label ?? '어항',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSubtle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAquariumSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '어항 선택',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSubtle,
            fontWeight: FontWeight.w500,
          ),
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
                    value: _aquarium,
                    isExpanded: true,
                    hint: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('어항을 선택하세요 (선택사항)'),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    borderRadius: BorderRadius.circular(12),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.textSubtle,
                    ),
                    items: [
                      const DropdownMenuItem<AquariumData?>(
                        value: null,
                        child: Text('전체 (특정 어항 없음)'),
                      ),
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
                        _aquarium = value;
                      });
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.bodySmall.copyWith(
        color: AppColors.textSubtle,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildTimeSelector() {
    return GestureDetector(
      onTap: _showTimePicker,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.backgroundSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 시간 표시
            _buildTimeBox(_selectedHour.toString().padLeft(2, '0')),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                ':',
                style: AppTextStyles.displayLarge.copyWith(
                  color: AppColors.textMain,
                ),
              ),
            ),
            // 분 표시
            _buildTimeBox(_selectedMinute.toString().padLeft(2, '0')),
            const SizedBox(width: 20),
            // AM/PM 토글
            _buildPeriodToggle(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeBox(String value) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.backgroundApp,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Center(
        child: Text(
          value,
          style: AppTextStyles.displayLarge.copyWith(
            color: AppColors.textMain,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundApp,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPeriodButton('AM', _isAM),
          _buildPeriodButton('PM', !_isAM),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() => _isAM = label == 'AM');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brand : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyMediumBold.copyWith(
            color: isSelected ? AppColors.textInverse : AppColors.textHint,
          ),
        ),
      ),
    );
  }

  void _showTimePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ScrollableTimePicker(
        initialHour: _selectedHour,
        initialMinute: _selectedMinute,
        initialIsAM: _isAM,
        onTimeSelected: (hour, minute, isAM) {
          setState(() {
            _selectedHour = hour;
            _selectedMinute = minute;
            _isAM = isAM;
          });
        },
      ),
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '알림 이름',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSubtle,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: '알림 이름을 입력하세요',
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textHint,
            ),
            filled: true,
            fillColor: AppColors.backgroundSurface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.brand, width: 1.5),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildNotificationToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_outlined,
                color: AppColors.textMain,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text('푸시 알림 받기', style: AppTextStyles.bodyMediumBold),
            ],
          ),
          Switch(
            value: _isNotificationEnabled,
            onChanged: (value) async {
              if (value) {
                // 알림을 켜려고 할 때 권한 확인
                final hasPermission = await NotificationService.instance
                    .hasPermission();
                if (!hasPermission) {
                  // 권한 요청
                  final granted = await NotificationService.instance
                      .requestPermission();
                  if (!granted && mounted) {
                    // 권한 거부됨 - 설정으로 이동 안내 다이얼로그
                    _showPermissionDeniedDialog();
                    return; // 토글 변경 안 함
                  }
                }
              }
              setState(() => _isNotificationEnabled = value);
            },
            activeTrackColor: AppColors.switchActiveTrack,
            inactiveTrackColor: AppColors.switchInactiveTrack,
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.white;
              }
              return AppColors.textHint;
            }),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('알림 권한 필요', style: AppTextStyles.titleMedium),
        content: Text(
          '푸시 알림을 받으려면 설정에서 알림을 허용해주세요.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '나중에',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSubtle,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text(
              '설정으로 이동',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.brand),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showSaveWithoutNotificationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('알림 권한 필요', style: AppTextStyles.titleMedium),
        content: Text(
          '알림 권한이 없어 푸시 알림을 받을 수 없습니다.\n알림 없이 일정만 저장할까요?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              '취소',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSubtle,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
              openAppSettings();
            },
            child: Text(
              '설정으로 이동',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.brand),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              '알림 없이 저장',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.brand),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundSurface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isFormValid && !_isSaving ? _onSave : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brand,
              foregroundColor: AppColors.textInverse,
              disabledBackgroundColor: AppColors.disabled,
              disabledForegroundColor: AppColors.disabledText,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.textInverse,
                      ),
                    ),
                  )
                : Text(
                    '저장하기',
                    style: AppTextStyles.bodyMediumBold.copyWith(
                      color: _isFormValid
                          ? AppColors.textInverse
                          : AppColors.disabledText,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
