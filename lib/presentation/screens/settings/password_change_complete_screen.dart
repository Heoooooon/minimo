import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/di/app_dependencies.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../widgets/common/app_button.dart';

/// 비밀번호 변경 완료 화면
///
/// 변경 성공 안내 및 홈으로 돌아가기
class PasswordChangeCompleteScreen extends StatelessWidget {
  const PasswordChangeCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userName =
        context.read<AppDependencies>().authService.currentUser?.getStringValue(
          'name',
        ) ??
        '사용자';

    return Scaffold(
      backgroundColor: AppColors.backgroundSurface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const Spacer(),

              // ── 체크 아이콘 ──
              const Icon(
                Icons.check_circle_outline,
                size: 64,
                color: AppColors.brand,
              ),

              const SizedBox(height: 24),

              // ── 완료 메시지 ──
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: AppTextStyles.headlineMedium,
                  children: [
                    TextSpan(
                      text: userName,
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.brand,
                      ),
                    ),
                    const TextSpan(text: '님,\n'),
                    const TextSpan(text: '비밀번호 변경이 완료되었어요!'),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Text(
                '새로운 비밀번호로\n안전하게 이용하실 수 있어요.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSubtle,
                ),
              ),

              const Spacer(),

              // ── 홈으로 버튼 ──
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: AppButton(
                  text: '홈으로',
                  size: AppButtonSize.large,
                  shape: AppButtonShape.round,
                  expanded: true,
                  onPressed: () {
                    // 설정 화면 스택까지 모두 pop하고 메인으로
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
