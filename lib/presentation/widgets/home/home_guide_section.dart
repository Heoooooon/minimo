import 'package:flutter/material.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';

/// 가이드 단계 데이터
class GuideStep {
  final int step;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const GuideStep({
    required this.step,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

/// 홈 화면 초보자 가이드 섹션
class HomeGuideSection extends StatelessWidget {
  const HomeGuideSection({super.key, this.onStepTap});

  final void Function(GuideStep)? onStepTap;

  static const List<GuideStep> _steps = [
    GuideStep(
      step: 1,
      title: '어항 세팅',
      description: '어항 크기, 여과기, 히터 등\n기본 장비를 준비해요',
      icon: Icons.settings_suggest_outlined,
      color: Color(0xFF4A90D9),
    ),
    GuideStep(
      step: 2,
      title: '물잡이',
      description: '여과 박테리아가 자리잡을\n때까지 1~2주 기다려요',
      icon: Icons.water_drop_outlined,
      color: Color(0xFF00B356),
    ),
    GuideStep(
      step: 3,
      title: '생물 입양',
      description: '수질이 안정되면 물맞댐 후\n생물을 넣어주세요',
      icon: Icons.pets_outlined,
      color: Color(0xFFFF8C42),
    ),
    GuideStep(
      step: 4,
      title: '수질 관리',
      description: '주 1회 환수, 수온·pH 체크로\n건강한 환경을 유지해요',
      icon: Icons.science_outlined,
      color: Color(0xFF7B61FF),
    ),
    GuideStep(
      step: 5,
      title: '정기 관리',
      description: '먹이 급여, 필터 청소 등\n꾸준한 관리가 핵심이에요',
      icon: Icons.calendar_month_outlined,
      color: Color(0xFFE84855),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 156,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _steps.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final step = _steps[index];
          return _GuideCard(
            step: step,
            onTap: () => onStepTap?.call(step),
          );
        },
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({required this.step, this.onTap});

  final GuideStep step;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.backgroundSurface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step badge + icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: step.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'STEP ${step.step}',
                    style: AppTextStyles.captionMedium.copyWith(
                      color: step.color,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Icon(step.icon, size: 20, color: step.color),
              ],
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              step.title,
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.textMain,
                fontWeight: FontWeight.w700,
                fontSize: 15,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),

            // Description
            Text(
              step.description,
              style: AppTextStyles.captionRegular.copyWith(
                color: AppColors.textSubtle,
                fontSize: 11,
                height: 1.45,
                letterSpacing: -0.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
