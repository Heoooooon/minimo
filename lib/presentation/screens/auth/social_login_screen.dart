import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/di/app_dependencies.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/onboarding_service.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';
import '../main_shell.dart';
import '../onboarding/onboarding_survey_screen.dart';
import 'email_login_screen.dart';

/// 소셜 로그인 화면
class SocialLoginScreen extends StatefulWidget {
  const SocialLoginScreen({super.key});

  @override
  State<SocialLoginScreen> createState() => _SocialLoginScreenState();
}

class _SocialLoginScreenState extends State<SocialLoginScreen> {
  bool _isLoading = false;
  String? _loadingProvider;
  late final AuthService _authService;
  late final OnboardingService _onboardingService;
  bool _isDependenciesReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isDependenciesReady) return;

    final dependencies = context.read<AppDependencies>();
    _authService = dependencies.authService;
    _onboardingService = dependencies.onboardingService;
    _isDependenciesReady = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 배경 이미지
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_background.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF0A3D62), Color(0xFF001529)],
                    ),
                  ),
                );
              },
            ),
          ),
          // 그라데이션 오버레이 1: 좌→우 (투명 → 어두운 파랑)
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
                  stops: const [0.3448, 1.0],
                ),
              ),
            ),
          ),
          // 그라데이션 오버레이 2: 전체 어두운 오버레이
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.52)),
          ),
          // 콘텐츠
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 80),
                  // 타이틀 (그라데이션 텍스트)
                  _buildGradientTitle(),
                  const Spacer(),
                  // 소셜 로그인 버튼들
                  _SocialLoginButton(
                    text: '카카오로 시작하기',
                    backgroundColor: const Color(0xFFFAE300),
                    textColor: AppColors.textMain,
                    iconPath: 'assets/icons/kakao.png',
                    isLoading: _loadingProvider == 'kakao',
                    onPressed: _isLoading
                        ? null
                        : () => _handleSocialLogin('kakao'),
                  ),
                  const SizedBox(height: 16),
                  _SocialLoginButton(
                    text: '애플로 시작하기',
                    backgroundColor: Colors.black,
                    textColor: Colors.white,
                    iconPath: 'assets/icons/apple.png',
                    isLoading: _loadingProvider == 'apple',
                    onPressed: _isLoading
                        ? null
                        : () => _handleSocialLogin('apple'),
                  ),
                  const SizedBox(height: 16),
                  _SocialLoginButton(
                    text: '네이버로 시작하기',
                    backgroundColor: const Color(0xFF00BF18),
                    textColor: Colors.white,
                    iconPath: 'assets/icons/naver.png',
                    isLoading: _loadingProvider == 'naver',
                    onPressed: _isLoading
                        ? null
                        : () => _handleSocialLogin('naver'),
                  ),
                  const SizedBox(height: 16),
                  _SocialLoginButton(
                    text: '구글로 시작하기',
                    backgroundColor: Colors.white,
                    textColor: AppColors.textMain,
                    iconPath: 'assets/icons/google.png',
                    isLoading: _loadingProvider == 'google',
                    onPressed: _isLoading
                        ? null
                        : () => _handleSocialLogin('google'),
                  ),
                  const SizedBox(height: 16),
                  // 이메일 로그인 링크
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: TextButton(
                      onPressed: () => _navigateToEmailLogin(context),
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        '이메일로 로그인하기',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textInverse,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 34),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientTitle() {
    return ShaderMask(
      shaderCallback: (bounds) {
        return const LinearGradient(
          begin: Alignment(-0.5, -0.5),
          end: Alignment(0.8, 1.2),
          colors: [
            AppColors.gray50,
            Color(0x99000E24), // rgba(0, 14, 36, 0.6)
          ],
          stops: [0.2368, 0.924],
        ).createShader(bounds);
      },
      blendMode: BlendMode.srcIn,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '우물,',
            style: AppTextStyles.displayLarge.copyWith(
              fontSize: 36,
              fontWeight: FontWeight.w600,
              height: 48 / 36,
              letterSpacing: -0.5,
              color: Colors.white,
            ),
          ),
          Text(
            '우리가 함께하는',
            style: AppTextStyles.displayLarge.copyWith(
              fontSize: 36,
              fontWeight: FontWeight.w600,
              height: 48 / 36,
              letterSpacing: -0.5,
              color: Colors.white,
            ),
          ),
          Text(
            '물생활',
            style: AppTextStyles.displayLarge.copyWith(
              fontSize: 36,
              fontWeight: FontWeight.w600,
              height: 48 / 36,
              letterSpacing: -0.5,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSocialLogin(String provider) async {
    setState(() {
      _isLoading = true;
      _loadingProvider = provider;
    });

    try {
      await _authService.loginWithOAuth2(provider);

      if (!mounted) return;

      final isOnboardingCompleted = _onboardingService.isOnboardingCompleted;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => isOnboardingCompleted
              ? const MainShell()
              : const OnboardingSurveyScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      AppLogger.auth('$provider 소셜 로그인 실패: $e', isError: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$provider 로그인에 실패했습니다. 다시 시도해주세요.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingProvider = null;
        });
      }
    }
  }

  void _navigateToEmailLogin(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const EmailLoginScreen()));
  }
}

/// 소셜 로그인 버튼
class _SocialLoginButton extends StatelessWidget {
  const _SocialLoginButton({
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    required this.iconPath,
    this.isLoading = false,
    required this.onPressed,
  });

  final String text;
  final Color backgroundColor;
  final Color textColor;
  final String iconPath;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null && !isLoading ? 0.5 : 1.0,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 60,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading)
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: textColor,
                      ),
                    )
                  else
                    Image.asset(
                      iconPath,
                      width: 24,
                      height: 24,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox(width: 24, height: 24);
                      },
                    ),
                  const SizedBox(width: 8),
                  Text(
                    isLoading ? '로그인 중...' : text,
                    style: AppTextStyles.bodyMediumBold.copyWith(
                      color: textColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
