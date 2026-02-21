import 'package:flutter/material.dart';
import '../../../domain/models/record_data.dart';
import 'package:cmore_design_system/theme/app_spacing.dart';
import 'sector_form_components.dart';

/// 섹터 디테일 시트 결과 데이터
class SectorDetailResult {
  final RecordTag tag;
  final String content;

  const SectorDetailResult({required this.tag, required this.content});
}

/// 섹터별 디테일 입력 시트
///
/// RecordTag에 맞는 세부 입력 폼을 표시하고,
/// 저장 시 입력된 내용을 content 문자열로 반환.
class SectorDetailSheet extends StatefulWidget {
  final RecordTag tag;

  const SectorDetailSheet({super.key, required this.tag});

  static Future<SectorDetailResult?> show(
    BuildContext context, {
    required RecordTag tag,
  }) {
    return showModalBottomSheet<SectorDetailResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SectorDetailSheet(tag: tag),
    );
  }

  @override
  State<SectorDetailSheet> createState() => _SectorDetailSheetState();
}

class _SectorDetailSheetState extends State<SectorDetailSheet> {
  @override
  Widget build(BuildContext context) {
    return switch (widget.tag) {
      RecordTag.plantCare => _PlantCareForm(onSave: _handleSave),
      RecordTag.waterChange => _WaterChangeForm(onSave: _handleSave),
      RecordTag.cleaning => _CleaningForm(onSave: _handleSave),
      RecordTag.maintenance => _MaintenanceForm(onSave: _handleSave),
      RecordTag.feeding => _FeedingForm(onSave: _handleSave),
      RecordTag.waterTest => _WaterTestForm(onSave: _handleSave),
      RecordTag.temperatureCheck => _TemperatureCheckForm(onSave: _handleSave),
      _ => SectorDetailSheetLayout(
          title: widget.tag.label,
          onSave: () => _handleSave(''),
          children: const [],
        ),
    };
  }

  void _handleSave(String content) {
    Navigator.of(context).pop(
      SectorDetailResult(tag: widget.tag, content: content),
    );
  }
}

// ========================================
// 수초 관리
// ========================================
class _PlantCareForm extends StatefulWidget {
  final void Function(String content) onSave;
  const _PlantCareForm({required this.onSave});

  @override
  State<_PlantCareForm> createState() => _PlantCareFormState();
}

class _PlantCareFormState extends State<_PlantCareForm> {
  double _condition = 2; // 0=문제, 1=의심, 2=보통, 3=좋음
  int? _trimming; // 0=완료, 1=미완료
  int? _fertilizer; // 0=투여, 1=미투여
  final _fertilizerAmountCtrl = TextEditingController();
  int? _light; // 0=강, 1=중, 2=약

  @override
  void dispose() {
    _fertilizerAmountCtrl.dispose();
    super.dispose();
  }

  String _buildContent() {
    final parts = <String>[];
    final condLabels = ['문제', '의심', '보통', '좋음'];
    parts.add('수온: ${condLabels[_condition.round()]}');
    if (_trimming != null) {
      parts.add('트리밍: ${_trimming == 0 ? "완료" : "미완료"}');
    }
    if (_fertilizer != null) {
      parts.add('비료: ${_fertilizer == 0 ? "투여" : "미투여"}');
      if (_fertilizer == 0 && _fertilizerAmountCtrl.text.isNotEmpty) {
        parts.add('비료량: ${_fertilizerAmountCtrl.text}mL');
      }
    }
    if (_light != null) {
      final lightLabels = ['강', '중', '약'];
      parts.add('광량: ${lightLabels[_light!]}');
    }
    return parts.join(' / ');
  }

  @override
  Widget build(BuildContext context) {
    return SectorDetailSheetLayout(
      title: '수초 관리',
      onSave: () => widget.onSave(_buildContent()),
      children: [
        const SectionLabel('현재 수온'),
        LabeledSlider(
          value: _condition,
          labels: const ['문제', '의심', '보통', '좋음'],
          onChanged: (v) => setState(() => _condition = v),
        ),
        const SizedBox(height: AppSpacing.xl),

        const SectionLabel('트리밍 여부'),
        ToggleButtonGroup(
          options: const ['완료', '미완료'],
          selectedIndex: _trimming,
          onSelected: (i) => setState(() => _trimming = i),
        ),
        const SizedBox(height: AppSpacing.xl),

        const SectionLabel('비료 투여 여부'),
        ToggleButtonGroup(
          options: const ['투여', '미투여'],
          selectedIndex: _fertilizer,
          onSelected: (i) => setState(() => _fertilizer = i),
        ),
        if (_fertilizer == 0) ...[
          const SizedBox(height: AppSpacing.md),
          UnitTextField(
            controller: _fertilizerAmountCtrl,
            unit: 'mL',
          ),
        ],
        const SizedBox(height: AppSpacing.xl),

        const SectionLabel('광량'),
        ToggleButtonGroup(
          options: const ['강', '중', '약'],
          selectedIndex: _light,
          onSelected: (i) => setState(() => _light = i),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

// ========================================
// 물갈이
// ========================================
class _WaterChangeForm extends StatefulWidget {
  final void Function(String content) onSave;
  const _WaterChangeForm({required this.onSave});

  @override
  State<_WaterChangeForm> createState() => _WaterChangeFormState();
}

class _WaterChangeFormState extends State<_WaterChangeForm> {
  int? _doChange; // 0=예, 1=아니오
  int? _amount; // 0=전체, 1=부분
  final _amountCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  String _buildContent() {
    final parts = <String>[];
    if (_doChange != null) {
      parts.add('환수: ${_doChange == 0 ? "예" : "아니오"}');
    }
    if (_doChange == 0) {
      if (_amount != null) {
        parts.add('환수량: ${_amount == 0 ? "전체" : "부분"}');
      }
      if (_amountCtrl.text.isNotEmpty) {
        parts.add('${_amountCtrl.text}L');
      }
    }
    return parts.join(' / ');
  }

  @override
  Widget build(BuildContext context) {
    return SectorDetailSheetLayout(
      title: '물갈이',
      onSave: () => widget.onSave(_buildContent()),
      children: [
        const SectionLabel('환수 여부'),
        ToggleButtonGroup(
          options: const ['예', '아니오'],
          selectedIndex: _doChange,
          onSelected: (i) => setState(() => _doChange = i),
        ),
        const SizedBox(height: AppSpacing.xl),

        if (_doChange == 0) ...[
          const SectionLabel('환수량'),
          ToggleButtonGroup(
            options: const ['전체', '부분'],
            selectedIndex: _amount,
            onSelected: (i) => setState(() => _amount = i),
          ),
          const SizedBox(height: AppSpacing.md),
          UnitTextField(controller: _amountCtrl, unit: 'L'),
          const SizedBox(height: AppSpacing.xl),
        ],
      ],
    );
  }
}

// ========================================
// 어항 청소
// ========================================
class _CleaningForm extends StatefulWidget {
  final void Function(String content) onSave;
  const _CleaningForm({required this.onSave});

  @override
  State<_CleaningForm> createState() => _CleaningFormState();
}

class _CleaningFormState extends State<_CleaningForm> {
  int? _glass; // 0=예, 1=아니오
  int? _floor; // 0=예, 1=아니오
  int? _decoration; // 0=예, 1=아니오

  String _buildContent() {
    final parts = <String>[];
    if (_glass != null) parts.add('유리: ${_glass == 0 ? "예" : "아니오"}');
    if (_floor != null) parts.add('바닥: ${_floor == 0 ? "예" : "아니오"}');
    if (_decoration != null) {
      parts.add('장식: ${_decoration == 0 ? "예" : "아니오"}');
    }
    return parts.join(' / ');
  }

  @override
  Widget build(BuildContext context) {
    return SectorDetailSheetLayout(
      title: '어항 청소',
      onSave: () => widget.onSave(_buildContent()),
      children: [
        const SectionLabel('유리 청소'),
        ToggleButtonGroup(
          options: const ['예', '아니오'],
          selectedIndex: _glass,
          onSelected: (i) => setState(() => _glass = i),
        ),
        const SizedBox(height: AppSpacing.xl),

        const SectionLabel('바닥 청소'),
        ToggleButtonGroup(
          options: const ['예', '아니오'],
          selectedIndex: _floor,
          onSelected: (i) => setState(() => _floor = i),
        ),
        const SizedBox(height: AppSpacing.xl),

        const SectionLabel('장식 청소'),
        ToggleButtonGroup(
          options: const ['예', '아니오'],
          selectedIndex: _decoration,
          onSelected: (i) => setState(() => _decoration = i),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

// ========================================
// 장비 점검
// ========================================
class _MaintenanceForm extends StatefulWidget {
  final void Function(String content) onSave;
  const _MaintenanceForm({required this.onSave});

  @override
  State<_MaintenanceForm> createState() => _MaintenanceFormState();
}

class _MaintenanceFormState extends State<_MaintenanceForm> {
  int? _filter; // 0=정상, 1=점검 필요
  final _heaterTempCtrl = TextEditingController();
  int? _heater; // 0=정상, 1=미작동, 2=점검 필요
  int? _light; // 0=정상, 1=점검 필요
  int? _airPump; // 0=정상, 1=점검 필요

  @override
  void dispose() {
    _heaterTempCtrl.dispose();
    super.dispose();
  }

  String _buildContent() {
    final parts = <String>[];
    if (_filter != null) {
      parts.add('여과기: ${_filter == 0 ? "정상" : "점검 필요"}');
    }
    if (_heater != null) {
      final heaterLabels = ['정상', '미작동', '점검 필요'];
      parts.add('히터: ${heaterLabels[_heater!]}');
      if (_heaterTempCtrl.text.isNotEmpty) {
        parts.add('히터 온도: ${_heaterTempCtrl.text}');
      }
    }
    if (_light != null) {
      parts.add('조명: ${_light == 0 ? "정상" : "점검 필요"}');
    }
    if (_airPump != null) {
      parts.add('에어펌프: ${_airPump == 0 ? "정상" : "점검 필요"}');
    }
    return parts.join(' / ');
  }

  @override
  Widget build(BuildContext context) {
    return SectorDetailSheetLayout(
      title: '장비 점검',
      onSave: () => widget.onSave(_buildContent()),
      children: [
        const SectionLabel('여과기'),
        ToggleButtonGroup(
          options: const ['정상', '점검 필요'],
          selectedIndex: _filter,
          onSelected: (i) => setState(() => _filter = i),
        ),
        const SizedBox(height: AppSpacing.xl),

        const SectionLabel('히터'),
        UnitTextField(controller: _heaterTempCtrl, unit: 'Unit'),
        const SizedBox(height: AppSpacing.sm),
        ToggleButtonGroup(
          options: const ['정상', '미작동', '점검 필요'],
          selectedIndex: _heater,
          onSelected: (i) => setState(() => _heater = i),
        ),
        const SizedBox(height: AppSpacing.xl),

        const SectionLabel('조명'),
        ToggleButtonGroup(
          options: const ['정상', '점검 필요'],
          selectedIndex: _light,
          onSelected: (i) => setState(() => _light = i),
        ),
        const SizedBox(height: AppSpacing.xl),

        const SectionLabel('에어펌프'),
        ToggleButtonGroup(
          options: const ['정상', '점검 필요'],
          selectedIndex: _airPump,
          onSelected: (i) => setState(() => _airPump = i),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

// ========================================
// 먹이주기
// ========================================
class _FeedingForm extends StatefulWidget {
  final void Function(String content) onSave;
  const _FeedingForm({required this.onSave});

  @override
  State<_FeedingForm> createState() => _FeedingFormState();
}

class _FeedingFormState extends State<_FeedingForm> {
  int _hour = 8;
  int _minute = 20;
  bool _isAm = true;
  int? _reaction; // 0=나쁨, 1=보통, 2=좋음
  int? _foodType; // 0=건식, 1=생먹이, 2=냉동 먹이, 3=특수 먹이
  final _amountCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  String _buildContent() {
    final parts = <String>[];
    final period = _isAm ? 'AM' : 'PM';
    parts.add('시간: ${_hour.toString().padLeft(2, '0')}:'
        '${_minute.toString().padLeft(2, '0')} $period');
    if (_reaction != null) {
      final reactionLabels = ['나쁨', '보통', '좋음'];
      parts.add('반응: ${reactionLabels[_reaction!]}');
    }
    if (_foodType != null) {
      final foodLabels = ['건식', '생먹이', '냉동 먹이', '특수 먹이'];
      parts.add('종류: ${foodLabels[_foodType!]}');
    }
    if (_amountCtrl.text.isNotEmpty) {
      parts.add('급여량: ${_amountCtrl.text}');
    }
    return parts.join(' / ');
  }

  @override
  Widget build(BuildContext context) {
    return SectorDetailSheetLayout(
      title: '먹이주기',
      onSave: () => widget.onSave(_buildContent()),
      children: [
        const SectionLabel('급여 시간'),
        TimePicker(
          hour: _hour,
          minute: _minute,
          isAm: _isAm,
          onHourChanged: (v) => setState(() => _hour = v),
          onMinuteChanged: (v) => setState(() => _minute = v),
          onAmPmChanged: (v) => setState(() => _isAm = v),
        ),
        const SizedBox(height: AppSpacing.xl),

        const SectionLabel('급여 반응'),
        ToggleButtonGroup(
          options: const ['나쁨', '보통', '좋음'],
          selectedIndex: _reaction,
          onSelected: (i) => setState(() => _reaction = i),
        ),
        const SizedBox(height: AppSpacing.xl),

        const SectionLabel('먹이 종류'),
        ToggleButtonGroup(
          options: const ['건식', '생먹이', '냉동 먹이', '특수 먹이'],
          selectedIndex: _foodType,
          onSelected: (i) => setState(() => _foodType = i),
        ),
        const SizedBox(height: AppSpacing.xl),

        const SectionLabel('급여량'),
        UnitTextField(
          controller: _amountCtrl,
          unit: '',
          hintText: 'nn',
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

// ========================================
// 수질 체크
// ========================================
class _WaterTestForm extends StatefulWidget {
  final void Function(String content) onSave;
  const _WaterTestForm({required this.onSave});

  @override
  State<_WaterTestForm> createState() => _WaterTestFormState();
}

class _WaterTestFormState extends State<_WaterTestForm> {
  final _phCtrl = TextEditingController();
  final _nitriteCtrl = TextEditingController();
  final _nitrateCtrl = TextEditingController();

  @override
  void dispose() {
    _phCtrl.dispose();
    _nitriteCtrl.dispose();
    _nitrateCtrl.dispose();
    super.dispose();
  }

  String _buildContent() {
    final parts = <String>[];
    if (_phCtrl.text.isNotEmpty) parts.add('pH: ${_phCtrl.text}');
    if (_nitriteCtrl.text.isNotEmpty) {
      parts.add('NO2-: ${_nitriteCtrl.text}');
    }
    if (_nitrateCtrl.text.isNotEmpty) {
      parts.add('NO3-: ${_nitrateCtrl.text}');
    }
    return parts.join(' / ');
  }

  @override
  Widget build(BuildContext context) {
    return SectorDetailSheetLayout(
      title: '수질체크',
      onSave: () => widget.onSave(_buildContent()),
      children: [
        const SectionLabel('pH'),
        UnitTextField(controller: _phCtrl, unit: '', hintText: 'nn'),
        const SizedBox(height: AppSpacing.xl),

        const SectionLabel('NO₂⁻ (아질산염)'),
        UnitTextField(controller: _nitriteCtrl, unit: 'Unit'),
        const SizedBox(height: AppSpacing.xl),

        const SectionLabel('NO₃⁻ (질산염)'),
        UnitTextField(controller: _nitrateCtrl, unit: 'Unit'),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

// ========================================
// 온도 체크
// ========================================
class _TemperatureCheckForm extends StatefulWidget {
  final void Function(String content) onSave;
  const _TemperatureCheckForm({required this.onSave});

  @override
  State<_TemperatureCheckForm> createState() => _TemperatureCheckFormState();
}

class _TemperatureCheckFormState extends State<_TemperatureCheckForm> {
  final _tempCtrl = TextEditingController();
  int? _status; // 0=정상, 1=주의, 2=위험

  @override
  void dispose() {
    _tempCtrl.dispose();
    super.dispose();
  }

  String _buildContent() {
    final parts = <String>[];
    if (_tempCtrl.text.isNotEmpty) {
      parts.add('온도: ${_tempCtrl.text}°C');
    }
    if (_status != null) {
      final statusLabels = ['정상', '주의', '위험'];
      parts.add('상태: ${statusLabels[_status!]}');
    }
    return parts.join(' / ');
  }

  @override
  Widget build(BuildContext context) {
    return SectorDetailSheetLayout(
      title: '온도 체크',
      onSave: () => widget.onSave(_buildContent()),
      children: [
        const SectionLabel('측정 온도'),
        UnitTextField(controller: _tempCtrl, unit: '°C'),
        const SizedBox(height: AppSpacing.xl),

        const SectionLabel('상태'),
        ToggleButtonGroup(
          options: const ['정상', '주의', '위험'],
          selectedIndex: _status,
          onSelected: (i) => setState(() => _status = i),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}
