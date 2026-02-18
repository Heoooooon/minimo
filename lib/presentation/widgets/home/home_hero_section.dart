import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_spacing.dart';

/// 홈 화면 Hero 섹션 (배경 + 인사말 + 상태태그/등록버튼)
///
/// Figma 디자인 기반 - 어항 이미지 배경 위에 인사말과 상태 표시
class HomeHeroSection extends StatelessWidget {
  const HomeHeroSection({
    super.key,
    required this.userName,
    required this.hasAquariums,
    required this.statusTags,
    this.onRegisterTap,
  });

  /// 사용자 이름
  final String userName;

  /// 어항 보유 여부
  final bool hasAquariums;

  /// 상태 태그 리스트 (예: ["오늘 해야 3건", "물잡이 7일차"])
  final List<String> statusTags;

  /// 어항 등록 버튼 콜백
  final VoidCallback? onRegisterTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 352 - 86, // Original hero height minus overlap
      decoration: const BoxDecoration(color: AppColors.brand),
      child: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.brand, AppColors.brand],
                ),
              ),
            ),
          ),
          // Aquarium image overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.7,
              child: Container(
                color: Colors.white,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/main_background.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.brand.withValues(alpha: 0.8),
                                  const Color(
                                    0xFF00183C,
                                  ).withValues(alpha: 0.8),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.transparent,
                              const Color(0xFF00183C).withValues(alpha: 0.8),
                            ],
                            stops: const [0.3447, 1.0],
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Content (상단 바 공간 확보를 위해 상단 패딩 추가)
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 18),
                  _buildGreeting(),
                  const SizedBox(height: 16),
                  if (hasAquariums)
                    _buildStatusTags()
                  else
                    _buildRegisterAquariumButton(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Greeting Text - 어항 유무에 따라 다른 인사말
  Widget _buildGreeting() {
    final textStyle = AppTextStyles.headlineLarge.copyWith(
      color: AppColors.textInverse,
      fontWeight: FontWeight.w600,
      fontSize: 24,
      height: 36 / 24,
      letterSpacing: -0.25,
    );

    if (hasAquariums) {
      // 어항이 있는 경우
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$userName 님, 오늘도 덕분에', style: textStyle),
          Text('잘 지내고 있어요! 🐠', style: textStyle),
        ],
      );
    } else {
      // 어항이 없는 경우
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$userName 님, 반가워요!', style: textStyle),
          Text('첫 어항을 등록해보세요 🐠', style: textStyle),
        ],
      );
    }
  }

  /// Status Tags (glass effect)
  Widget _buildStatusTags() {
    // 태그가 없으면 기본 태그 표시
    final displayTags = statusTags.isEmpty ? ['어항 관리 중'] : statusTags;

    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: displayTags.map((tag) => _buildStatusTag(tag)).toList(),
    );
  }

  Widget _buildStatusTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.textInverse.withValues(alpha: 0.5),
        borderRadius: AppRadius.xsBorderRadius,
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textInverse,
          fontWeight: FontWeight.w500,
          fontSize: 14,
          height: 20 / 14,
          letterSpacing: -0.25,
        ),
      ),
    );
  }

  /// 어항 등록하기 버튼 (어항이 없을 때만 표시)
  Widget _buildRegisterAquariumButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: ElevatedButton(
        onPressed: onRegisterTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: AppColors.textInverse,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.xsBorderRadius),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: 2),
        ),
        child: Text(
          '어항 등록하기',
          style: AppTextStyles.titleSmall.copyWith(
            color: AppColors.textInverse,
          ),
        ),
      ),
    );
  }
}
