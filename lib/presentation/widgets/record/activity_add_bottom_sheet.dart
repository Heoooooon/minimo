import 'package:flutter/material.dart';
import '../../../domain/models/record_data.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_spacing.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';

/// 섹터별 아이콘/색상 정의
class _SectorStyle {
  final IconData icon;
  final Color color;
  const _SectorStyle(this.icon, this.color);
}

const Map<RecordTag, _SectorStyle> _sectorStyles = {
  RecordTag.waterChange: _SectorStyle(Icons.water_drop_outlined, AppColors.brand),
  RecordTag.feeding: _SectorStyle(Icons.restaurant_outlined, Color(0xFFFF9800)),
  RecordTag.cleaning: _SectorStyle(Icons.cleaning_services_outlined, AppColors.success),
  RecordTag.waterTest: _SectorStyle(Icons.science_outlined, Color(0xFF7C4DFF)),
  RecordTag.temperatureCheck: _SectorStyle(Icons.thermostat_outlined, Color(0xFFE91E63)),
  RecordTag.plantCare: _SectorStyle(Icons.eco_outlined, Color(0xFF4CAF50)),
  RecordTag.maintenance: _SectorStyle(Icons.build_outlined, Color(0xFF607D8B)),
};

/// 활동 추가 바텀 시트
///
/// 섹터 그리드를 표시하고, 카드를 탭하면 해당 RecordTag를 반환합니다.
/// 호출측에서 반환된 태그로 SectorDetailSheet를 열어 디테일 입력을 진행합니다.
class ActivityAddBottomSheet extends StatelessWidget {
  const ActivityAddBottomSheet({super.key});

  /// 바텀 시트 표시 → 선택된 RecordTag 반환
  static Future<RecordTag?> show(BuildContext context) {
    return showModalBottomSheet<RecordTag>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ActivityAddBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
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
            // 드래그 인디케이터
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 타이틀
            Text(
              '할 일 추가',
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '추가할 항목을 선택해주세요',
              style: AppTextStyles.captionRegular.copyWith(
                color: AppColors.textSubtle,
              ),
            ),
            const SizedBox(height: 20),

            // 섹터 그리드
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _buildSectorGrid(context),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectorGrid(BuildContext context) {
    final tags = RecordTag.activityTags;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: tags.map((tag) => _buildSectorCard(context, tag)).toList(),
    );
  }

  Widget _buildSectorCard(BuildContext context, RecordTag tag) {
    final style = _sectorStyles[tag];
    if (style == null) return const SizedBox.shrink();

    final cardWidth =
        (MediaQuery.of(context).size.width - 32 - 10 - 10) / 3;

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(tag),
      child: Container(
        width: cardWidth,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.backgroundSurface,
          borderRadius: AppRadius.mdBorderRadius,
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: style.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(style.icon, color: style.color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              tag.label,
              style: AppTextStyles.captionRegular.copyWith(
                color: AppColors.textMain,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
