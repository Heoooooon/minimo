import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/services/auth_service.dart';
import '../../../core/di/app_dependencies.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../widgets/common/app_button.dart';
import '../onboarding/onboarding_survey_screen.dart';

/// 회원가입 화면 (연속 플로우 애니메이션)
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with TickerProviderStateMixin {
  // 현재 진행 단계
  int _visibleStep = 0; // 0: 닉네임만, 1: +이메일, 2: +인증, 3: +비밀번호, 4: 완료

  // Step 1: 이름/닉네임
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode();

  // Step 2: 이메일
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();
  String _selectedDomain = '';
  final List<String> _domains = [
    'gmail.com',
    'naver.com',
    'daum.net',
    'kakao.com',
    'nate.com',
    '직접입력',
  ];

  // Step 3: 이메일 인증
  final _verificationCodeController = TextEditingController();
  final _verificationFocusNode = FocusNode();
  Timer? _timer;
  int _remainingSeconds = 180;
  bool _isVerified = false;
  bool _codeSent = false;

  // Step 4: 비밀번호
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  final _passwordConfirmController = TextEditingController();
  final _passwordConfirmFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;
  bool _agreeToTerms = false;
  bool _agreeToMarketing = false;

  bool _isLoading = false;
  bool _isCompleted = false;
  late final AuthService _authService;
  bool _isDependenciesReady = false;

  // 애니메이션 컨트롤러
  late AnimationController _emailAnimController;
  late AnimationController _verificationAnimController;
  late AnimationController _passwordAnimController;

  late Animation<double> _emailSlideAnim;
  late Animation<double> _emailFadeAnim;
  late Animation<double> _verificationSlideAnim;
  late Animation<double> _verificationFadeAnim;
  late Animation<double> _passwordSlideAnim;
  late Animation<double> _passwordFadeAnim;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isDependenciesReady) return;

    _authService = context.read<AppDependencies>().authService;
    _isDependenciesReady = true;
  }

  @override
  void initState() {
    super.initState();

    // 애니메이션 설정
    _emailAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _verificationAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _passwordAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _emailSlideAnim = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _emailAnimController, curve: Curves.easeOutCubic),
    );
    _emailFadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _emailAnimController, curve: Curves.easeOut),
    );

    _verificationSlideAnim = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: _verificationAnimController,
        curve: Curves.easeOutCubic,
      ),
    );
    _verificationFadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _verificationAnimController,
        curve: Curves.easeOut,
      ),
    );

    _passwordSlideAnim = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: _passwordAnimController,
        curve: Curves.easeOutCubic,
      ),
    );
    _passwordFadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _passwordAnimController, curve: Curves.easeOut),
    );

    // 닉네임 입력 감지
    _nameController.addListener(_onNameChanged);
    _emailController.addListener(_onEmailChanged);
    _passwordController.addListener(() => setState(() {}));
    _passwordConfirmController.addListener(() => setState(() {}));

    // 이름 필드 포커스 감지 (포커스 빠질 때 다음 단계로)
    _nameFocusNode.addListener(_onNameFocusChanged);

    // 첫 필드에 포커스
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameFocusNode.removeListener(_onNameFocusChanged);
    _nameController.dispose();
    _emailController.dispose();
    _verificationCodeController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _verificationFocusNode.dispose();
    _passwordFocusNode.dispose();
    _passwordConfirmFocusNode.dispose();
    _emailAnimController.dispose();
    _verificationAnimController.dispose();
    _passwordAnimController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _onNameChanged() {
    // 이름 변경 시 상태만 업데이트 (자동 전환 X)
    setState(() {});
  }

  /// 이름 입력 완료 후 이메일 섹션으로 전환
  void _proceedToEmail() {
    final text = _nameController.text.trim();
    if (text.length >= 2 && _visibleStep == 0) {
      setState(() => _visibleStep = 1);
      _emailAnimController.forward();
      Future.delayed(const Duration(milliseconds: 300), () {
        _emailFocusNode.requestFocus();
      });
    }
  }

  /// 이름 필드 포커스 변경 감지
  void _onNameFocusChanged() {
    if (!_nameFocusNode.hasFocus) {
      // 포커스가 빠질 때 이메일 섹션으로 전환
      _proceedToEmail();
    }
  }

  void _onEmailChanged() {
    setState(() {});
  }

  String get _fullEmail {
    if (_selectedDomain.isEmpty || _emailController.text.isEmpty) {
      return '';
    }
    return '${_emailController.text}@$_selectedDomain';
  }

  bool get _isEmailValid =>
      _emailController.text.trim().isNotEmpty && _selectedDomain.isNotEmpty;

  bool get _isPasswordValid {
    final password = _passwordController.text;
    final hasUpperCase = password.contains(RegExp(r'[A-Z]'));
    final hasLowerCase = password.contains(RegExp(r'[a-z]'));
    final hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    final isValidLength = password.length >= 8 && password.length <= 16;
    return hasUpperCase && hasLowerCase && hasSpecialChar && isValidLength;
  }

  bool get _canSignUp {
    return _isPasswordValid &&
        _passwordController.text == _passwordConfirmController.text &&
        _agreeToTerms;
  }

  void _startVerificationTimer() {
    _remainingSeconds = 180;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  String get _timerText {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _sendVerificationEmail() async {
    if (!_isEmailValid) return;

    setState(() => _isLoading = true);
    try {
      await _authService.sendVerificationCode(_fullEmail);
      _startVerificationTimer();
      setState(() {
        _codeSent = true;
        _visibleStep = 2;
      });
      _verificationAnimController.forward();
      Future.delayed(const Duration(milliseconds: 300), () {
        _verificationFocusNode.requestFocus();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('인증 코드 발송 실패: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyCode() async {
    if (_verificationCodeController.text.length != 4) return;

    setState(() => _isLoading = true);
    try {
      final success = await _authService.verifyCode(
        _fullEmail,
        _verificationCodeController.text,
      );
      if (success) {
        setState(() {
          _isVerified = true;
          _visibleStep = 3;
        });
        _timer?.cancel();
        _passwordAnimController.forward();
        Future.delayed(const Duration(milliseconds: 300), () {
          _passwordFocusNode.requestFocus();
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('인증에 실패했습니다. 코드를 확인해주세요.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('인증 실패: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignUp() async {
    if (!_canSignUp) return;

    setState(() => _isLoading = true);

    try {
      await _authService.signUpWithEmail(
        email: _fullEmail,
        password: _passwordController.text,
        passwordConfirm: _passwordConfirmController.text,
        name: _nameController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isCompleted = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('회원가입 실패: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCompleted) {
      return _buildCompletionScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      '반가워요!\n회원가입을 진행해 주세요.',
                      style: AppTextStyles.headlineMedium.copyWith(
                        height: 32 / 22,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Step 1: 닉네임 (항상 표시)
                    _buildNicknameSection(),

                    // Step 2: 이메일 (닉네임 입력 후 나타남)
                    _buildAnimatedSection(
                      animation: _emailAnimController,
                      slideAnim: _emailSlideAnim,
                      fadeAnim: _emailFadeAnim,
                      child: _buildEmailSection(),
                    ),

                    // Step 3: 인증코드 (이메일 발송 후 나타남)
                    _buildAnimatedSection(
                      animation: _verificationAnimController,
                      slideAnim: _verificationSlideAnim,
                      fadeAnim: _verificationFadeAnim,
                      child: _buildVerificationSection(),
                    ),

                    // Step 4: 비밀번호 (인증 완료 후 나타남)
                    _buildAnimatedSection(
                      animation: _passwordAnimController,
                      slideAnim: _passwordSlideAnim,
                      fadeAnim: _passwordFadeAnim,
                      child: _buildPasswordSection(),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            // 회원가입 버튼 (비밀번호 단계에서만)
            if (_visibleStep >= 3) _buildSignUpButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedSection({
    required AnimationController animation,
    required Animation<double> slideAnim,
    required Animation<double> fadeAnim,
    required Widget child,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        if (animation.value == 0) return const SizedBox.shrink();
        return Transform.translate(
          offset: Offset(0, slideAnim.value),
          child: Opacity(opacity: fadeAnim.value, child: child),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              '회원가입',
              style: AppTextStyles.headlineSmall,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildNicknameSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputLabel('이름/닉네임'),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _nameController,
          focusNode: _nameFocusNode,
          hintText: '이름/닉네임을 입력해주세요 (2자 이상)',
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _proceedToEmail(),
        ),
      ],
    );
  }

  Widget _buildEmailSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        _buildInputLabel('이메일'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _buildTextField(
                controller: _emailController,
                focusNode: _emailFocusNode,
                hintText: '이메일',
                keyboardType: TextInputType.emailAddress,
                enabled: !_codeSent,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '@',
                style: AppTextStyles.bodyMediumMedium.copyWith(
                  color: AppColors.textSubtle,
                ),
              ),
            ),
            Expanded(flex: 3, child: _buildDomainDropdown(enabled: !_codeSent)),
          ],
        ),
        if (!_codeSent) ...[
          const SizedBox(height: 12),
          AppButton(
            text: '이메일 인증하기',
            size: AppButtonSize.medium,
            expanded: true,
            isEnabled: _isEmailValid && !_isLoading,
            isLoading: _isLoading && !_codeSent,
            onPressed: _sendVerificationEmail,
          ),
        ],
      ],
    );
  }

  Widget _buildVerificationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildInputLabel('이메일 인증'),
            if (!_isVerified)
              Text(
                _timerText,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.brand,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (!_isVerified) ...[
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _verificationCodeController,
                  focusNode: _verificationFocusNode,
                  hintText: '인증번호 4자리',
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  onChanged: (value) {
                    setState(() {});
                    if (value.length == 4) {
                      _verifyCode();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: AppButton(
                  text: '재요청',
                  size: AppButtonSize.medium,
                  variant: AppButtonVariant.outlined,
                  onPressed: () async {
                    setState(() => _isLoading = true);
                    try {
                      await _authService.sendVerificationCode(_fullEmail);
                      _startVerificationTimer();
                      _verificationCodeController.clear();
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('재요청 실패: $e')));
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
                  },
                ),
              ),
            ],
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 20),
                const SizedBox(width: 8),
                Text(
                  '이메일이 인증되었습니다',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPasswordSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        _buildInputLabel('비밀번호'),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          hintText: '비밀번호',
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _passwordConfirmFocusNode.requestFocus(),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: AppColors.textHint,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 8),
        _buildPasswordRequirements(),
        const SizedBox(height: 24),
        _buildInputLabel('비밀번호 확인'),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _passwordConfirmController,
          focusNode: _passwordConfirmFocusNode,
          hintText: '비밀번호를 한번 더 입력해주세요',
          obscureText: _obscurePasswordConfirm,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePasswordConfirm ? Icons.visibility_off : Icons.visibility,
              color: AppColors.textHint,
            ),
            onPressed: () => setState(
              () => _obscurePasswordConfirm = !_obscurePasswordConfirm,
            ),
          ),
        ),
        if (_passwordConfirmController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(
                  _passwordController.text == _passwordConfirmController.text
                      ? Icons.check_circle
                      : Icons.error_outline,
                  size: 16,
                  color:
                      _passwordController.text ==
                          _passwordConfirmController.text
                      ? AppColors.success
                      : AppColors.error,
                ),
                const SizedBox(width: 6),
                Text(
                  _passwordController.text == _passwordConfirmController.text
                      ? '비밀번호가 일치합니다'
                      : '비밀번호가 일치하지 않습니다',
                  style: AppTextStyles.captionRegular.copyWith(
                    color:
                        _passwordController.text ==
                            _passwordConfirmController.text
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        _buildCheckbox(
          value: _agreeToTerms,
          label: '개인정보 약관에 동의합니다.',
          onChanged: (value) => setState(() => _agreeToTerms = value ?? false),
        ),
        const SizedBox(height: 8),
        _buildCheckbox(
          value: _agreeToMarketing,
          label: '마케팅 수신 정보에 동의합니다.',
          onChanged: (value) =>
              setState(() => _agreeToMarketing = value ?? false),
        ),
      ],
    );
  }

  Widget _buildSignUpButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundApp,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: AppButton(
        text: '회원가입',
        size: AppButtonSize.large,
        expanded: true,
        isEnabled: _canSignUp,
        isLoading: _isLoading,
        onPressed: _handleSignUp,
      ),
    );
  }

  Widget _buildCompletionScreen() {
    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(scale: value, child: child);
                },
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.brand.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check, size: 48, color: AppColors.brand),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                '회원가입이 완료되었습니다!',
                style: AppTextStyles.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '반가워요, ${_nameController.text}님!',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textSubtle,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              Text(
                '더 좋은 서비스를 제공하기 위해\n몇 가지 질문을 드릴게요',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSubtle,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              AppButton(
                text: '시작하기',
                size: AppButtonSize.large,
                expanded: true,
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const OnboardingSurveyScreen(),
                    ),
                    (route) => false,
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSubtle),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    FocusNode? focusNode,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    int? maxLength,
    bool enabled = true,
    TextInputAction? textInputAction,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLength: maxLength,
      enabled: enabled,
      textInputAction: textInputAction,
      style: AppTextStyles.bodyMedium,
      onChanged: onChanged ?? (_) => setState(() {}),
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
        filled: true,
        fillColor: enabled
            ? AppColors.backgroundSurface
            : AppColors.disabled.withValues(alpha: 0.3),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.brand),
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }

  Widget _buildDomainDropdown({bool enabled = true}) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: enabled
            ? AppColors.backgroundSurface
            : AppColors.disabled.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedDomain.isEmpty ? null : _selectedDomain,
          hint: Text(
            '선택',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
          ),
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.textSubtle,
          ),
          items: enabled
              ? _domains.map((domain) {
                  return DropdownMenuItem(
                    value: domain == '직접입력' ? '' : domain,
                    child: Text(domain, style: AppTextStyles.bodyMedium),
                  );
                }).toList()
              : null,
          onChanged: enabled
              ? (value) => setState(() => _selectedDomain = value ?? '')
              : null,
        ),
      ),
    );
  }

  Widget _buildCheckbox({
    required bool value,
    required String label,
    required ValueChanged<bool?> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: value ? AppColors.brand : AppColors.border,
                width: 1.5,
              ),
              color: value ? AppColors.brand : Colors.transparent,
            ),
            child: value
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 8),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  Widget _buildPasswordRequirements() {
    final password = _passwordController.text;
    final hasUpperCase = password.contains(RegExp(r'[A-Z]'));
    final hasLowerCase = password.contains(RegExp(r'[a-z]'));
    final hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    final isValidLength = password.length >= 8 && password.length <= 16;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRequirementRow('8~16자', isValidLength),
        _buildRequirementRow('대문자 포함', hasUpperCase),
        _buildRequirementRow('소문자 포함', hasLowerCase),
        _buildRequirementRow('특수문자 포함 (!@#\$%^&*)', hasSpecialChar),
      ],
    );
  }

  Widget _buildRequirementRow(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: isMet ? AppColors.success : AppColors.textHint,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTextStyles.captionRegular.copyWith(
              color: isMet ? AppColors.success : AppColors.textSubtle,
            ),
          ),
        ],
      ),
    );
  }
}
