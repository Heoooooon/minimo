import 'package:flutter/material.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';

/// 시간 선택기 위젯 (AM/PM 형식)
///
/// Figma 디자인 기반: 시(08) : 분(20) + AM/PM 토글
class TimePickerWidget extends StatelessWidget {
  const TimePickerWidget({
    super.key,
    required this.selectedHour,
    required this.selectedMinute,
    required this.isAM,
    required this.onHourChanged,
    required this.onMinuteChanged,
    required this.onPeriodChanged,
  });

  /// 선택된 시간 (1-12)
  final int selectedHour;

  /// 선택된 분 (0-59)
  final int selectedMinute;

  /// AM/PM 여부
  final bool isAM;

  /// 시간 변경 콜백
  final ValueChanged<int> onHourChanged;

  /// 분 변경 콜백
  final ValueChanged<int> onMinuteChanged;

  /// AM/PM 변경 콜백
  final ValueChanged<bool> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 시간 선택
          _buildNumberPicker(
            value: selectedHour,
            minValue: 1,
            maxValue: 12,
            onChanged: onHourChanged,
          ),
          // 콜론
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              ':',
              style: AppTextStyles.displayLarge.copyWith(
                color: AppColors.textMain,
              ),
            ),
          ),
          // 분 선택
          _buildNumberPicker(
            value: selectedMinute,
            minValue: 0,
            maxValue: 59,
            onChanged: onMinuteChanged,
            zeroPad: true,
          ),
          const SizedBox(width: 24),
          // AM/PM 토글
          _buildPeriodToggle(),
        ],
      ),
    );
  }

  Widget _buildNumberPicker({
    required int value,
    required int minValue,
    required int maxValue,
    required ValueChanged<int> onChanged,
    bool zeroPad = false,
  }) {
    final displayValue = zeroPad ? value.toString().padLeft(2, '0') : value.toString().padLeft(2, '0');

    return GestureDetector(
      onTap: () => _showNumberPicker(value, minValue, maxValue, onChanged, zeroPad),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.backgroundApp,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Center(
          child: Text(
            displayValue,
            style: AppTextStyles.displayLarge.copyWith(
              color: AppColors.textMain,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  void _showNumberPicker(
    int currentValue,
    int minValue,
    int maxValue,
    ValueChanged<int> onChanged,
    bool zeroPad,
  ) {
    // 실제 앱에서는 모달로 선택기 표시
    // 여기서는 단순히 증가시키는 로직 (탭하면 증가)
    int newValue = currentValue + 1;
    if (newValue > maxValue) {
      newValue = minValue;
    }
    onChanged(newValue);
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
          _buildPeriodButton('AM', isAM, () => onPeriodChanged(true)),
          _buildPeriodButton('PM', !isAM, () => onPeriodChanged(false)),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
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
}

/// 스크롤 기반 시간 선택기 (바텀시트용)
class ScrollableTimePicker extends StatefulWidget {
  const ScrollableTimePicker({
    super.key,
    required this.initialHour,
    required this.initialMinute,
    required this.initialIsAM,
    required this.onTimeSelected,
  });

  final int initialHour;
  final int initialMinute;
  final bool initialIsAM;
  final void Function(int hour, int minute, bool isAM) onTimeSelected;

  @override
  State<ScrollableTimePicker> createState() => _ScrollableTimePickerState();
}

class _ScrollableTimePickerState extends State<ScrollableTimePicker> {
  late int _selectedHour;
  late int _selectedMinute;
  late bool _isAM;

  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  @override
  void initState() {
    super.initState();
    _selectedHour = widget.initialHour;
    _selectedMinute = widget.initialMinute;
    _isAM = widget.initialIsAM;

    _hourController = FixedExtentScrollController(initialItem: _selectedHour - 1);
    _minuteController = FixedExtentScrollController(initialItem: _selectedMinute);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.backgroundSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 핸들
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          // 타이틀
          Text(
            '시간 선택',
            style: AppTextStyles.headlineSmall,
          ),
          const SizedBox(height: 20),
          // 선택기
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 시간
                SizedBox(
                  width: 60,
                  child: ListWheelScrollView.useDelegate(
                    controller: _hourController,
                    itemExtent: 50,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (index) {
                      setState(() => _selectedHour = index + 1);
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      builder: (context, index) {
                        final hour = index + 1;
                        final isSelected = hour == _selectedHour;
                        return Center(
                          child: Text(
                            hour.toString().padLeft(2, '0'),
                            style: AppTextStyles.headlineMedium.copyWith(
                              color: isSelected ? AppColors.brand : AppColors.textHint,
                            ),
                          ),
                        );
                      },
                      childCount: 12,
                    ),
                  ),
                ),
                // 콜론
                Text(
                  ':',
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: AppColors.textMain,
                  ),
                ),
                // 분
                SizedBox(
                  width: 60,
                  child: ListWheelScrollView.useDelegate(
                    controller: _minuteController,
                    itemExtent: 50,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (index) {
                      setState(() => _selectedMinute = index);
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      builder: (context, index) {
                        final isSelected = index == _selectedMinute;
                        return Center(
                          child: Text(
                            index.toString().padLeft(2, '0'),
                            style: AppTextStyles.headlineMedium.copyWith(
                              color: isSelected ? AppColors.brand : AppColors.textHint,
                            ),
                          ),
                        );
                      },
                      childCount: 60,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                // AM/PM
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPeriodOption('AM', _isAM, () => setState(() => _isAM = true)),
                    const SizedBox(height: 8),
                    _buildPeriodOption('PM', !_isAM, () => setState(() => _isAM = false)),
                  ],
                ),
              ],
            ),
          ),
          // 확인 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onTimeSelected(_selectedHour, _selectedMinute, _isAM);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brand,
                foregroundColor: AppColors.textInverse,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                '확인',
                style: AppTextStyles.bodyMediumBold.copyWith(
                  color: AppColors.textInverse,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodOption(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brand : AppColors.backgroundApp,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.brand : AppColors.borderLight,
          ),
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
}
