import 'package:flutter/material.dart';
import '../../../domain/models/creature_data.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';

/// 어항 내 생물 탭 바
///
/// 수평 스크롤로 [전체] [생물A] [생물B] 등을 표시
/// 선택된 탭으로 자동 스크롤
class CreatureTabBar extends StatefulWidget {
  final List<CreatureData> creatures;
  final String? selectedCreatureId; // null이면 "전체"
  final ValueChanged<String?> onCreatureSelected;

  const CreatureTabBar({
    super.key,
    required this.creatures,
    required this.selectedCreatureId,
    required this.onCreatureSelected,
  });

  @override
  State<CreatureTabBar> createState() => _CreatureTabBarState();
}

class _CreatureTabBarState extends State<CreatureTabBar> {
  final ScrollController _scrollController = ScrollController();
  static const double _estimatedItemWidth = 80.0;

  @override
  void didUpdateWidget(CreatureTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCreatureId != widget.selectedCreatureId) {
      _scrollToSelected();
    }
  }

  void _scrollToSelected() {
    if (!_scrollController.hasClients) return;

    int selectedIndex = 0;
    if (widget.selectedCreatureId != null) {
      final idx = widget.creatures.indexWhere(
        (c) => c.id == widget.selectedCreatureId,
      );
      if (idx >= 0) selectedIndex = idx + 1; // +1 for "전체" tab
    }

    final targetOffset = (selectedIndex * _estimatedItemWidth).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        children: [
          _buildTab(
            label: '전체',
            isSelected: widget.selectedCreatureId == null,
            onTap: () => widget.onCreatureSelected(null),
          ),
          ...widget.creatures.map((creature) {
            final isSelected = widget.selectedCreatureId == creature.id;
            return _buildTab(
              label: creature.displayName,
              isSelected: isSelected,
              onTap: () => widget.onCreatureSelected(creature.id),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.brand : AppColors.backgroundApp,
                borderRadius: BorderRadius.circular(18),
                border: isSelected
                    ? null
                    : Border.all(color: AppColors.borderLight),
              ),
              child: Text(
                label,
                style: AppTextStyles.captionMedium.copyWith(
                  color: isSelected ? AppColors.textInverse : AppColors.textSubtle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
