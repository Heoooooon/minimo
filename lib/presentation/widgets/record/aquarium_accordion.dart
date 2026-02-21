import 'package:flutter/material.dart';
import '../../../domain/models/aquarium_data.dart';
import '../../../domain/models/creature_data.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_spacing.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';
import '../../viewmodels/record_viewmodel.dart';
import 'creature_tab_bar.dart';
import 'record_type_page_view.dart';

/// 어항 아코디언 아이템
///
/// 어항 헤더(이름 + 확장 아이콘)를 표시하고,
/// 펼침 시 CreatureTabBar + RecordTypePageView를 표시.
class AquariumAccordion extends StatelessWidget {
  final AquariumData aquarium;
  final bool isExpanded;
  final List<CreatureData> creatures;
  final String? selectedCreatureId;
  final DateTime selectedDate;
  final RecordViewModel recordViewModel;
  final VoidCallback onToggle;
  final void Function(String? creatureId) onCreatureSelected;
  final VoidCallback onDataChanged;

  /// 해당 어항의 총 할 일 수
  final int totalTodos;

  /// 해당 어항의 완료된 할 일 수
  final int completedTodos;

  const AquariumAccordion({
    super.key,
    required this.aquarium,
    required this.isExpanded,
    required this.creatures,
    required this.selectedCreatureId,
    required this.selectedDate,
    required this.recordViewModel,
    required this.onToggle,
    required this.onCreatureSelected,
    required this.onDataChanged,
    this.totalTodos = 0,
    this.completedTodos = 0,
  });

  @override
  Widget build(BuildContext context) {
    final aquariumId = aquarium.id ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundSurface,
        borderRadius: AppRadius.lgBorderRadius,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          // 어항 헤더
          InkWell(
            onTap: onToggle,
            borderRadius: AppRadius.lgBorderRadius,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.chipPrimaryBg,
                      borderRadius: AppRadius.smBorderRadius,
                    ),
                    child: const Icon(
                      Icons.water_drop,
                      color: AppColors.brand,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      aquarium.name ?? '이름 없음',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (totalTodos > 0) ...[
                    _buildCompletionBadge(),
                    const SizedBox(width: AppSpacing.sm),
                  ],
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

          // 펼쳐진 내용
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildExpandedContent(aquariumId),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionBadge() {
    final isAllCompleted = completedTodos >= totalTodos;
    final bgColor = isAllCompleted ? AppColors.success : AppColors.orange500;
    final label = isAllCompleted
        ? '완료'
        : '미완료 ${totalTodos - completedTodos}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.12),
        borderRadius: AppRadius.xsBorderRadius,
      ),
      child: Text(
        label,
        style: AppTextStyles.captionRegular.copyWith(
          color: bgColor,
          fontWeight: FontWeight.w600,
          fontSize: 11,
          height: 16 / 11,
        ),
      ),
    );
  }

  Widget _buildExpandedContent(String aquariumId) {
    return Column(
      children: [
        const Divider(height: 1, color: AppColors.borderLight),

        // 생물 탭 바
        if (creatures.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
            child: CreatureTabBar(
              creatures: creatures,
              selectedCreatureId: selectedCreatureId,
              onCreatureSelected: onCreatureSelected,
            ),
          ),

        // 할 일 / 기록 / 일기 스와이프 뷰
        RecordTypePageView(
          key: ValueKey(
            'pageview_${aquariumId}_${selectedCreatureId}_${selectedDate.toIso8601String()}',
          ),
          aquariumId: aquariumId,
          aquariumName: aquarium.name,
          creatureId: selectedCreatureId,
          selectedDate: selectedDate,
          recordViewModel: recordViewModel,
          onDataChanged: onDataChanged,
        ),
      ],
    );
  }
}
