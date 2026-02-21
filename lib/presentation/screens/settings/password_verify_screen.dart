import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/services/auth_service.dart';
import '../../../core/di/app_dependencies.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';
import 'package:cmore_design_system/widgets/app_button.dart';
import 'password_change_screen.dart';

/// 비밀번호 확인 화면
///
/// 비밀번호 변경 전 현재 비밀번호를 확인하는 단계
class PasswordVerifyScreen extends StatefulWidget {
  const PasswordVerifyScreen({super.key});

  @override
  State<PasswordVerifyScreen> createState() => _PasswordVerifyScreenState();
}

class _PasswordVerifyScreenState extends State<PasswordVerifyScreen> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
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

  bool get _isFormValid => _passwordController.text.isNotEmpty;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    if (!_isFormValid) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final isValid = await _authService.verifyCurrentPassword(
        _passwordController.text,
      );

      if (!mounted) return;

      if (isValid) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                PasswordChangeScreen(currentPassword: _passwordController.text),
          ),
        );
      } else {
        setState(() {
          _errorText = '비밀번호가 올바르지 않습니다.';
        });
      }
    } catch (e) {
      AppLogger.auth('비밀번호 확인 실패: $e', isError: true);
      if (!mounted) return;
      setState(() {
        _errorText = '비밀번호 확인에 실패했습니다.';
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
        title: Text('비밀번호 확인', style: AppTextStyles.bodyMediumBold),
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
                    const TextSpan(text: '소중한 정보 확인을 위해\n'),
                    const TextSpan(text: '현재 비밀번호를 입력해주세요.'),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── 비밀번호 입력 ──
              Text(
                '현재 비밀번호',
                style: AppTextStyles.captionMedium.copyWith(
                  color: AppColors.textSubtle,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: AppTextStyles.bodyMedium,
                onChanged: (_) => setState(() => _errorText = null),
                decoration: InputDecoration(
                  hintText: '현재 비밀번호를 입력하세요',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textHint,
                  ),
                  errorText: _errorText,
                  errorStyle: AppTextStyles.captionRegular.copyWith(
                    color: AppColors.error,
                  ),
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
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.error),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.error),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textHint,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
              ),

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
                  onPressed: _handleVerify,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
