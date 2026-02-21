import 'package:flutter/material.dart';
import '../../../domain/models/record_data.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';
import 'package:cmore_design_system/widgets/app_button.dart';

/// 활동 추가 바텀 시트
///
/// 기록할 활동을 선택하는 바텀 시트
/// 여러 활동을 체크박스로 선택 후 추가하기 버튼으로 확정
class ActivityAddBottomSheet extends StatefulWidget {
  final DateTime selectedDate;
  final Function(List<RecordTag> selectedTags) onActivitySelected;

  const ActivityAddBottomSheet({
    super.key,
    required this.selectedDate,
    required this.onActivitySelected,
  });

  /// 바텀 시트 표시
  static Future<List<RecordTag>?> show(
    BuildContext context, {
    required DateTime selectedDate,
  }) {
    return showModalBottomSheet<List<RecordTag>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ActivityAddBottomSheet(
        selectedDate: selectedDate,
        onActivitySelected: (tags) {
          Navigator.of(context).pop(tags);
        },
      ),
    );
  }

  @override
  State<ActivityAddBottomSheet> createState() => _ActivityAddBottomSheetState();
}

class _ActivityAddBottomSheetState extends State<ActivityAddBottomSheet> {
  final Set<RecordTag> _selectedTags = {};

  void _toggleTag(RecordTag tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  void _handleAdd() {
    if (_selectedTags.isNotEmpty) {
      widget.onActivitySelected(_selectedTags.toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundApp,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 상단 영역 (드래그 인디케이터 + 타이틀 + 목록)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                children: [
                  // 드래그 인디케이터
                  _buildDragIndicator(),
                  const SizedBox(height: 20),

                  // 타이틀
                  Text(
                    '활동 추가',
                    style: AppTextStyles.headlineSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // 활동 목록
                  _buildActivityList(),
                ],
              ),
            ),

            // 하단 버튼
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildDragIndicator() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }

  Widget _buildActivityList() {
    final activities = RecordTag.activityTags;

    return Column(
      children: activities.asMap().entries.map((entry) {
        final index = entry.key;
        final tag = entry.value;
        final isLast = index == activities.length - 1;

        return Column(
          children: [
            _buildActivityItem(tag),
            if (!isLast) _buildDivider(),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildActivityItem(RecordTag tag) {
    final isSelected = _selectedTags.contains(tag);

    return Semantics(
      checked: isSelected,
      label: tag.label,
      child: InkWell(
        onTap: () => _toggleTag(tag),
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 6, top: 12, bottom: 12),
          child: Row(
            children: [
              // 활동 이름
              Expanded(
                child: Text(
                  tag.label,
                  style: AppTextStyles.bodyMediumBold.copyWith(
                    color: AppColors.textSubtle,
                  ),
                ),
              ),

              // 체크박스
              SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: _buildCheckbox(isSelected),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox(bool isSelected) {
    if (isSelected) {
      return Container(
        width: 19,
        height: 19,
        decoration: BoxDecoration(
          color: AppColors.brand,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(
          Icons.check,
          color: Colors.white,
          size: 14,
        ),
      );
    } else {
      return Container(
        width: 19,
        height: 19,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border, width: 1),
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: AppColors.borderLight,
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            AppColors.backgroundApp,
            AppColors.backgroundApp.withValues(alpha: 0),
          ],
          stops: const [0.36, 1.0],
        ),
      ),
      child: AppButton(
        text: '추가하기',
        onPressed: _selectedTags.isNotEmpty ? _handleAdd : null,
        size: AppButtonSize.large,
        shape: AppButtonShape.square,
        variant: AppButtonVariant.contained,
        isEnabled: _selectedTags.isNotEmpty,
      ),
    );
  }
}
