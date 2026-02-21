import 'package:flutter/material.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';
import 'package:cmore_design_system/theme/app_spacing.dart';

/// 사진 추가 바텀시트
class AquariumPhotoAddSheet extends StatelessWidget {
  final VoidCallback onCameraSelected;
  final VoidCallback onGallerySelected;

  const AquariumPhotoAddSheet({
    super.key,
    required this.onCameraSelected,
    required this.onGallerySelected,
  });

  /// 바텀시트를 표시하는 유틸리티 메서드
  static void show(
    BuildContext context, {
    required VoidCallback onCameraSelected,
    required VoidCallback onGallerySelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) => AquariumPhotoAddSheet(
        onCameraSelected: () {
          Navigator.pop(context);
          onCameraSelected();
        },
        onGallerySelected: () {
          Navigator.pop(context);
          onGallerySelected();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 핸들 바
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // 타이틀
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Text(
                '사진 추가',
                style: AppTextStyles.headlineSmall,
              ),
            ),
            // 카메라 촬영 옵션
            ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.chipPrimaryBg,
                  borderRadius: AppRadius.mdBorderRadius,
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.brand,
                ),
              ),
              title: Text(
                '카메라로 촬영',
                style: AppTextStyles.titleMedium,
              ),
              subtitle: Text(
                '새 사진을 촬영합니다',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSubtle,
                ),
              ),
              onTap: onCameraSelected,
            ),
            // 갤러리 선택 옵션
            ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.chipPrimaryBg,
                  borderRadius: AppRadius.mdBorderRadius,
                ),
                child: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.brand,
                ),
              ),
              title: Text(
                '갤러리에서 선택',
                style: AppTextStyles.titleMedium,
              ),
              subtitle: Text(
                '저장된 사진을 선택합니다',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSubtle,
                ),
              ),
              onTap: onGallerySelected,
            ),
          ],
        ),
      ),
    );
  }
}
