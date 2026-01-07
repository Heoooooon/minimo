import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// 어항 등록 Step 2: 생물 등록 (Placeholder)
///
/// 추후 구현 예정인 생물 등록 화면의 placeholder
class RegisterStepCreature extends StatelessWidget {
  const RegisterStepCreature({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타이틀
          Text(
            '함께 살고 있는\n생물을 등록해 주세요.',
            style: AppTextStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '나중에 등록할 수도 있어요.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSubtle,
            ),
          ),
          const SizedBox(height: 40),

          // Placeholder 컨텐츠
          _buildPlaceholderCard(
            icon: Icons.add_circle_outline,
            title: '생물 추가하기',
            subtitle: '어항에 살고 있는 물고기, 새우 등을 추가해 보세요',
          ),
          const SizedBox(height: 16),

          // 샘플 생물 카드들
          _buildSampleCreatureCard('베타', '담수어', Icons.waves),
          const SizedBox(height: 12),
          _buildSampleCreatureCard('네온 테트라', '담수어', Icons.waves),
          const SizedBox(height: 12),
          _buildSampleCreatureCard('체리 새우', '갑각류', Icons.water_drop),
        ],
      ),
    );
  }

  Widget _buildPlaceholderCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.backgroundSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderLight,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.chipPrimaryBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.brand, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTextStyles.bodyMediumMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSubtle,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSampleCreatureCard(String name, String type, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.chipPrimaryBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.brand, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.bodyMediumMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  type,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSubtle,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.textHint),
        ],
      ),
    );
  }
}
