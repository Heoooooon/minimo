import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// 홈 화면 상단 Sticky Top Bar
///
/// 스크롤 위치에 따라 배경색과 아이콘 색상이 변경됨
class HomeStickyTopBar extends StatelessWidget {
  const HomeStickyTopBar({
    super.key,
    required this.isScrolledPastHero,
    required this.backgroundOpacity,
    this.onNotificationTap,
    this.onGuideTap,
    this.hasNotification = true,
  });

  /// Hero 섹션을 지나쳤는지 여부
  final bool isScrolledPastHero;

  /// 배경 불투명도 (0.0 ~ 1.0)
  final double backgroundOpacity;

  /// 알림 버튼 콜백
  final VoidCallback? onNotificationTap;

  /// 가이드 버튼 콜백
  final VoidCallback? onGuideTap;

  /// 알림 뱃지 표시 여부
  final bool hasNotification;

  @override
  Widget build(BuildContext context) {
    // 아이콘 색상 (흰 배경에서는 어두운 색, 어두운 배경에서는 흰색)
    final iconColor = isScrolledPastHero
        ? Color.lerp(Colors.white, AppColors.textMain, backgroundOpacity)!
        : Colors.white;
    final textColor = isScrolledPastHero
        ? Color.lerp(Colors.white, AppColors.textMain, backgroundOpacity)!
        : Colors.white;

    return Container(
      decoration: const BoxDecoration(color: Colors.transparent),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Notification Icon with badge (40x40 컨테이너, 24x24 아이콘)
              _buildNotificationButton(iconColor),

              // Guide Button
              _buildGuideButton(textColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationButton(Color iconColor) {
    return GestureDetector(
      onTap: onNotificationTap,
      child: Container(
        width: 40,
        height: 40,
        padding: const EdgeInsets.all(8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.notifications_outlined, color: iconColor, size: 24),
            // Orange badge (4x4, positioned at right:4, top:-3 from icon)
            if (hasNotification)
              Positioned(
                right: -4,
                top: -3,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFE8A24),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideButton(Color textColor) {
    return GestureDetector(
      onTap: onGuideTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        child: Center(
          child: Text(
            '가이드',
            style: AppTextStyles.bodySmall.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
              fontSize: 14,
              height: 20 / 14,
              letterSpacing: -0.25,
            ),
          ),
        ),
      ),
    );
  }
}
