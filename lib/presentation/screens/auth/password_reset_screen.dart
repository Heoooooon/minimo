import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/services/auth_service.dart';
import '../../../core/di/app_dependencies.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../widgets/common/app_button.dart';

/// 비밀번호 재설정 화면
///
/// 이메일 입력 후 비밀번호 재설정 메일 전송
class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isSent = false;
  late final AuthService _authService;
  bool _isDependenciesReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isDependenciesReady) return;

    _authService = context.read<AppDependencies>().authService;
    _isDependenciesReady = true;
  }

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  bool get _isFormValid =>
      _emailController.text.isNotEmpty &&
      _emailRegex.hasMatch(_emailController.text.trim());

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_isFormValid) return;

    setState(() => _isLoading = true);

    try {
      await _authService.requestPasswordReset(_emailController.text.trim());

      if (!mounted) return;
      setState(() {
        _isSent = true;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('비밀번호 재설정 메일 전송에 실패했습니다.')));
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
        title: Text('비밀번호 찾기', style: AppTextStyles.bodyMediumMedium),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _isSent ? _buildSuccessView() : _buildFormView(),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),

        RichText(
          text: TextSpan(
            style: AppTextStyles.headlineMedium,
            children: const [
              TextSpan(text: '가입하신 이메일을\n'),
              TextSpan(text: '입력해주세요.'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '입력하신 이메일로 비밀번호 재설정 링크가 전송됩니다.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSubtle),
        ),

        const SizedBox(height: 32),

        Text(
          '이메일',
          style: AppTextStyles.captionMedium.copyWith(
            color: AppColors.textSubtle,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: AppTextStyles.bodyMedium,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: '이메일을 입력하세요',
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textHint,
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
          ),
        ),

        const Spacer(),

        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: AppButton(
            text: '재설정 메일 보내기',
            size: AppButtonSize.large,
            shape: AppButtonShape.round,
            expanded: true,
            isEnabled: _isFormValid,
            isLoading: _isLoading,
            onPressed: _handleReset,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 80),

        const Icon(
          Icons.mark_email_read_outlined,
          size: 64,
          color: AppColors.brand,
        ),
        const SizedBox(height: 24),

        Text(
          '메일이 전송되었습니다',
          style: AppTextStyles.headlineMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        Text(
          '${_emailController.text.trim()}(으)로\n비밀번호 재설정 링크를 보냈습니다.\n메일을 확인해주세요.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSubtle,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 40),

        AppButton(
          text: '로그인으로 돌아가기',
          size: AppButtonSize.large,
          shape: AppButtonShape.round,
          expanded: true,
          onPressed: () => Navigator.pop(context),
        ),

        const SizedBox(height: 12),

        TextButton(
          onPressed: () {
            setState(() => _isSent = false);
          },
          child: Text(
            '메일을 받지 못했나요? 다시 보내기',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.brand),
          ),
        ),
      ],
    );
  }
}
