import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/services/auth_service.dart';
import '../../../core/di/app_dependencies.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../widgets/common/app_button.dart';
import 'password_change_complete_screen.dart';

/// 비밀번호 변경 화면
///
/// 새 비밀번호 입력 및 확인 후 변경 처리
class PasswordChangeScreen extends StatefulWidget {
  const PasswordChangeScreen({super.key, required this.currentPassword});

  /// 이전 단계에서 검증된 현재 비밀번호
  final String currentPassword;

  @override
  State<PasswordChangeScreen> createState() => _PasswordChangeScreenState();
}

class _PasswordChangeScreenState extends State<PasswordChangeScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorText;

  late final AuthService _authService;
  bool _isDependenciesReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isDependenciesReady) return;

    _authService = context.read<AppDependencies>().authService;
    _isDependenciesReady = true;
  }

  String get _userName {
    return _authService.currentUser?.getStringValue('name') ?? '사용자';
  }

  bool get _isFormValid {
    return _newPasswordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty;
  }

  /// 비밀번호 유효성 검사 (8~16자 영문 대소문자, 숫자, 특수문자)
  String? _validatePassword(String password) {
    if (password.length < 8 || password.length > 16) {
      return '비밀번호는 8~16자로 입력해주세요.';
    }
    // 영문, 숫자, 특수문자 조합 확인
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(password);
    final hasDigit = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
    if (!hasLetter || !hasDigit || !hasSpecial) {
      return '영문, 숫자, 특수문자를 모두 포함해주세요.';
    }
    return null;
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    if (!_isFormValid) return;

    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // 유효성 검사
    final validationError = _validatePassword(newPassword);
    if (validationError != null) {
      setState(() => _errorText = validationError);
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() => _errorText = '비밀번호가 일치하지 않습니다.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      await _authService.changePassword(
        oldPassword: widget.currentPassword,
        newPassword: newPassword,
        newPasswordConfirm: confirmPassword,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PasswordChangeCompleteScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = '비밀번호 변경에 실패했습니다.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSurface,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text('비밀번호 변경', style: AppTextStyles.bodyMediumMedium),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // ── 헤드라인 ──
              RichText(
                text: TextSpan(
                  style: AppTextStyles.headlineMedium,
                  children: [
                    TextSpan(
                      text: _userName,
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.brand,
                      ),
                    ),
                    const TextSpan(text: '님,\n'),
                    const TextSpan(text: '안전한 계정을 위해\n'),
                    const TextSpan(text: '새 비밀번호를 입력해주세요.'),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── 새 비밀번호 ──
              Text(
                '새 비밀번호',
                style: AppTextStyles.captionMedium.copyWith(
                  color: AppColors.textSubtle,
                ),
              ),
              const SizedBox(height: 8),
              _buildPasswordField(
                controller: _newPasswordController,
                hintText: '새 비밀번호',
                obscure: _obscureNewPassword,
                onToggleObscure: () {
                  setState(() => _obscureNewPassword = !_obscureNewPassword);
                },
              ),
              const SizedBox(height: 8),
              Text(
                '8~16자 영문 대 소문자, 숫자, 특수문자',
                style: AppTextStyles.captionRegular.copyWith(
                  color: AppColors.textSubtle,
                ),
              ),

              const SizedBox(height: 20),

              // ── 새 비밀번호 재입력 ──
              Text(
                '새 비밀번호 재입력',
                style: AppTextStyles.captionMedium.copyWith(
                  color: AppColors.textSubtle,
                ),
              ),
              const SizedBox(height: 8),
              _buildPasswordField(
                controller: _confirmPasswordController,
                hintText: '새 비밀번호 재입력',
                obscure: _obscureConfirmPassword,
                onToggleObscure: () {
                  setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  );
                },
              ),

              // ── 에러 메시지 ──
              if (_errorText != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorText!,
                  style: AppTextStyles.captionRegular.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],

              const Spacer(),

              // ── 다음 버튼 ──
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: AppButton(
                  text: '다음',
                  size: AppButtonSize.large,
                  shape: AppButtonShape.round,
                  expanded: true,
                  isEnabled: _isFormValid,
                  isLoading: _isLoading,
                  onPressed: _handleChangePassword,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool obscure,
    required VoidCallback onToggleObscure,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: AppTextStyles.bodyMedium,
      onChanged: (_) => setState(() => _errorText = null),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.brand),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: AppColors.textHint,
          ),
          onPressed: onToggleObscure,
        ),
      ),
    );
  }
}
