import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/services/auth_service.dart';
import '../../../core/di/app_dependencies.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../widgets/common/app_button.dart';

/// 계정 정보 화면
///
/// 사용자 프로필 정보 표시 및 소셜 연동 관리
class AccountInfoScreen extends StatefulWidget {
  const AccountInfoScreen({super.key});

  @override
  State<AccountInfoScreen> createState() => _AccountInfoScreenState();
}

class _AccountInfoScreenState extends State<AccountInfoScreen> {
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

  String get _userEmail {
    return _authService.currentUser?.getStringValue('email') ?? '';
  }

  String get _createdDate {
    final created = _authService.currentUser?.getStringValue('created') ?? '';
    if (created.isEmpty) return '';
    try {
      final date = DateTime.parse(created);
      return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return created;
    }
  }

  String get _accountType {
    final user = _authService.currentUser;
    if (user == null) return '';
    // PocketBase에서 OAuth로 가입한 경우 username이 "users"로 시작하는 패턴으로 자동 생성됨
    final username = user.getStringValue('username');
    if (username.startsWith('users') && username.length > 10) {
      return '소셜 로그인';
    }
    return '이메일 로그인';
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
        title: Text('계정 정보', style: AppTextStyles.bodyMediumMedium),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          // ── 이름(닉네임) 섹션 ──
          _buildSectionHeader('이름(닉네임)'),
          _buildNameRow(),
          const _InfoDivider(),
          _buildInfoRow('이메일', _userEmail),
          const _InfoDivider(),
          _buildInfoRow('가입일', _createdDate),
          const _InfoDivider(),
          _buildInfoRow('계정 유형', _accountType),

          const SizedBox(height: 32),

          // ── 소셜 연동 섹션 ──
          _buildSectionHeader('소셜 연동'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '*다른 플랫폼 계정과 연결해 로그인할 수 있어요.',
              style: AppTextStyles.captionRegular.copyWith(
                color: AppColors.textSubtle,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSocialRow('카카오', 'assets/icons/icon_kakao.png'),
          const _InfoDivider(),
          _buildSocialRow('애플', 'assets/icons/icon_apple.png'),
          const _InfoDivider(),
          _buildSocialRow('네이버', 'assets/icons/icon_naver.png'),
          const _InfoDivider(),
          _buildSocialRow('구글', 'assets/icons/icon_google.png'),

          const SizedBox(height: 32),

          // ── 회원 탈퇴 ──
          Center(
            child: TextButton(
              onPressed: _onDeleteAccount,
              child: Text(
                '회원 탈퇴',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSubtle,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── 위젯 빌더 ──

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 12),
      child: Text(
        title,
        style: AppTextStyles.captionMedium.copyWith(
          color: AppColors.textSubtle,
        ),
      ),
    );
  }

  Widget _buildNameRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(_userName, style: AppTextStyles.titleMedium),
          GestureDetector(
            onTap: _onEditName,
            child: Text(
              '수정하기',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.brand),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSubtle,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMain),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialRow(String name, String iconPath) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              iconPath,
              width: 28,
              height: 28,
              errorBuilder: (_, error, stackTrace) => Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.backgroundDisabled,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.link,
                  size: 16,
                  color: AppColors.textSubtle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(name, style: AppTextStyles.bodyLarge),
          const Spacer(),
          AppButtonFactories.smallOutlined(
            text: '준비 중',
            onPressed: () => _onLinkSocial(name),
          ),
        ],
      ),
    );
  }

  // ── 액션 핸들러 ──

  void _onEditName() {
    final controller = TextEditingController(text: _userName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundSurface,
        title: Text('닉네임 변경', style: AppTextStyles.titleMedium),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: '새 닉네임을 입력하세요',
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textHint,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.brand),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '취소',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSubtle,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) return;

              Navigator.pop(context);
              await _updateName(newName);
            },
            child: Text(
              '변경',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.brand),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateName(String newName) async {
    try {
      await _authService.updateName(newName);
      if (!mounted) return;
      setState(() {}); // UI 갱신
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('닉네임이 변경되었습니다.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('닉네임 변경에 실패했습니다: $e')));
    }
  }

  void _onLinkSocial(String provider) {
    // TODO: 소셜 연동 구현
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$provider 연동 기능은 준비 중입니다.')));
  }

  void _onDeleteAccount() {
    final passwordController = TextEditingController();
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.backgroundSurface,
          title: Text('회원 탈퇴', style: AppTextStyles.titleMedium),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '정말 탈퇴하시겠습니까?\n탈퇴 시 모든 데이터가 삭제되며 복구할 수 없습니다.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSubtle,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '본인 확인을 위해 비밀번호를 입력해주세요.',
                style: AppTextStyles.captionMedium.copyWith(
                  color: AppColors.textSubtle,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: '현재 비밀번호',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textHint,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.error),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textHint,
                      size: 20,
                    ),
                    onPressed: () {
                      setDialogState(() => obscurePassword = !obscurePassword);
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                '취소',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSubtle,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                if (passwordController.text.isEmpty) return;
                Navigator.pop(context);
                _performDeleteAccount(passwordController.text);
              },
              child: Text(
                '탈퇴',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performDeleteAccount(String password) async {
    try {
      // 비밀번호 확인
      final isValid = await _authService.verifyCurrentPassword(password);
      if (!isValid) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('비밀번호가 올바르지 않습니다.')));
        return;
      }

      await _authService.deleteAccount();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('회원 탈퇴에 실패했습니다: $e')));
    }
  }
}

/// 정보 행 구분선
class _InfoDivider extends StatelessWidget {
  const _InfoDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 20,
      endIndent: 20,
      color: AppColors.borderLight,
    );
  }
}
