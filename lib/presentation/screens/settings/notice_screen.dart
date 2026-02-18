import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// 공지사항 화면
class NoticeScreen extends StatelessWidget {
  const NoticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSurface,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text('공지사항', style: AppTextStyles.bodyMediumMedium),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.campaign_outlined,
              size: 64,
              color: AppColors.textHint.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '아직 공지사항이 없습니다',
              style: AppTextStyles.bodyMediumMedium.copyWith(
                color: AppColors.textSubtle,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '새로운 소식이 있으면 알려드릴게요',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
