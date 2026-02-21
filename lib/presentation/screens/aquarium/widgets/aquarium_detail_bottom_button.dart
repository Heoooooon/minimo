import 'package:flutter/material.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';
import 'package:cmore_design_system/theme/app_spacing.dart';

/// 어항 상세 하단 버튼 (Positioned - 사진 있는 경우)
class AquariumDetailBottomButton extends StatelessWidget {
  final TabController tabController;
  final VoidCallback onPressed;

  const AquariumDetailBottomButton({
    super.key,
    required this.tabController,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: _buildButtonContainer(context),
    );
  }

  Widget _buildButtonContainer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.xxl, AppSpacing.lg, AppSpacing.sm,
      ),
      color: AppColors.backgroundApp,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brand,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxxl,
                vertical: 3,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.smBorderRadius,
              ),
            ),
            child: AnimatedBuilder(
              animation: tabController,
              builder: (context, child) {
                String text;
                switch (tabController.index) {
                  case 0:
                    text = '생물 추가하기';
                    break;
                  case 1:
                    text = '알림 추가하기';
                    break;
                  case 2:
                    text = '사진 추가하기';
                    break;
                  default:
                    text = '추가하기';
                }
                return Text(text, style: AppTextStyles.bodyMediumBold);
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// 어항 상세 하단 버튼 (인라인 - 사진 없는 경우)
class AquariumDetailBottomButtonInline extends StatelessWidget {
  final TabController tabController;
  final VoidCallback onPressed;

  const AquariumDetailBottomButtonInline({
    super.key,
    required this.tabController,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.xxl, AppSpacing.lg, AppSpacing.sm,
      ),
      color: AppColors.backgroundApp,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brand,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxxl,
                vertical: 3,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.smBorderRadius,
              ),
            ),
            child: AnimatedBuilder(
              animation: tabController,
              builder: (context, child) {
                String text;
                switch (tabController.index) {
                  case 0:
                    text = '생물 추가하기';
                    break;
                  case 1:
                    text = '알림 추가하기';
                    break;
                  case 2:
                    text = '사진 추가하기';
                    break;
                  default:
                    text = '추가하기';
                }
                return Text(text, style: AppTextStyles.bodyMediumBold);
              },
            ),
          ),
        ),
      ),
    );
  }
}
