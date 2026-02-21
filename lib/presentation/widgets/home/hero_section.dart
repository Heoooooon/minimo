import 'package:flutter/material.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';
import 'package:cmore_design_system/widgets/app_button.dart';

/// 홈 화면 히어로 섹션
///
/// 수조 배경 이미지 위에 인사말, 상태 칩, CTA 버튼 표시
class HeroSection extends StatelessWidget {
  const HeroSection({
    super.key,
    required this.userName,
    required this.hasAquarium,
    this.todayTaskCount = 0,
    this.waterCycleDay = 0,
    this.onNotificationTap,
    this.onGuideTap,
    this.onRegisterTap,
  });

  /// 사용자 이름
  final String userName;

  /// 어항 등록 여부
  final bool hasAquarium;

  /// 오늘 챙김 건수
  final int todayTaskCount;

  /// 물잡이 일차
  final int waterCycleDay;

  /// 알림 버튼 콜백
  final VoidCallback? onNotificationTap;

  /// 가이드 버튼 콜백
  final VoidCallback? onGuideTap;

  /// 어항 등록 버튼 콜백
  final VoidCallback? onRegisterTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        // 수조 배경 그라데이션 (실제 이미지로 대체 가능)
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A3A5C), Color(0xFF2D5A7B), Color(0xFF3D7A9B)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 액션 바
              _buildTopBar(),
              const SizedBox(height: 20),

              // 인사말
              _buildGreeting(),
              const SizedBox(height: 12),

              // 상태 칩 (어항 등록 시) 또는 CTA 버튼 (미등록 시)
              if (hasAquarium) _buildStatusChips() else _buildRegisterButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 가이드 링크
        GestureDetector(
          onTap: onGuideTap,
          child: Text(
            '가이드',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textInverse.withValues(alpha: 0.8),
            ),
          ),
        ),
        // 알림 아이콘
        GestureDetector(
          onTap: onNotificationTap,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: AppColors.textInverse,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '안녕하세요',
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.textInverse,
          ),
        ),
        Text(
          '$userName님 👋',
          style: AppTextStyles.displaySmall.copyWith(
            color: AppColors.textInverse,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildStatusChip(
          icon: Icons.check_circle_outline,
          text: '오늘 챙김 $todayTaskCount건',
        ),
        if (waterCycleDay > 0)
          _buildStatusChip(
            icon: Icons.water_drop_outlined,
            text: '물잡이 $waterCycleDay일차',
          ),
      ],
    );
  }

  Widget _buildStatusChip({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textInverse),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTextStyles.captionMedium.copyWith(
              color: AppColors.textInverse,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton() {
    return AppButton(
      text: '어항 등록하기',
      onPressed: onRegisterTap,
      size: AppButtonSize.large,
      shape: AppButtonShape.round,
      variant: AppButtonVariant.contained,
      leadingIcon: Icons.add,
    );
  }
}
