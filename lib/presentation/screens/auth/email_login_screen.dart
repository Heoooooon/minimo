import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/services/auth_service.dart';
import '../../../core/di/app_dependencies.dart';
import '../../../data/services/pocketbase_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../widgets/common/app_button.dart';
import '../main_shell.dart';
import 'sign_up_screen.dart';
import 'password_reset_screen.dart';

/// 이메일 로그인 화면
class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _autoLogin = false;
  bool _isLoading = false;
  late final AuthService _authService;
  bool _isDependenciesReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isDependenciesReady) return;

    _authService = context.read<AppDependencies>().authService;
    _isDependenciesReady = true;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  bool get _isFormValid {
    return _emailController.text.isNotEmpty &&
        _emailRegex.hasMatch(_emailController.text.trim()) &&
        _passwordController.text.isNotEmpty;
  }

  Future<void> _handleLogin() async {
    if (!_isFormValid) return;

    setState(() => _isLoading = true);

    try {
      // 자동 로그인 설정 먼저 저장
      await PocketBaseService.instance.setAutoLogin(_autoLogin);

      await _authService.loginWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // 로그인 성공 후 토큰 저장 (자동 로그인 활성화된 경우)
      await PocketBaseService.instance.onLoginSuccess();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이메일 또는 비밀번호가 올바르지 않습니다')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
          // 그라데이션 오버레이
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
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.52)),
          ),
          // 콘텐츠
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 30),
                            // 타이틀 (그라데이션 텍스트)
                            _buildGradientTitle(),
                            const Spacer(),
                            // 이메일 입력
                            _buildLabel('이메일'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _emailController,
                              hintText: '이메일을 입력하세요',
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 12),
                            // 비밀번호 입력
                            _buildLabel('비밀번호'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _passwordController,
                              hintText: '비밀번호를 입력하세요',
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                                onPressed: () {
                                  setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            // 자동 로그인
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _autoLogin = !_autoLogin),
                              child: Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _autoLogin
                                            ? AppColors.brand
                                            : Colors.white.withValues(
                                                alpha: 0.5,
                                              ),
                                        width: 1.5,
                                      ),
                                      color: _autoLogin
                                          ? AppColors.brand
                                          : Colors.transparent,
                                    ),
                                    child: _autoLogin
                                        ? const Icon(
                                            Icons.check,
                                            size: 12,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '자동 로그인',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // 로그인 버튼
                            AppButton(
                              text: '로그인',
                              size: AppButtonSize.large,
                              expanded: true,
                              isEnabled: _isFormValid,
                              isLoading: _isLoading,
                              onPressed: _handleLogin,
                            ),
                            const SizedBox(height: 8),
                            // 하단 링크
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const SignUpScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      '회원가입',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const PasswordResetScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      '이메일/비밀번호 찾기',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 34),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
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
          colors: [Color(0xFFF9FAFC), Color(0x99000E24)],
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.bodySmall.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: Colors.white.withValues(alpha: 0.5),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.15),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.brand),
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
