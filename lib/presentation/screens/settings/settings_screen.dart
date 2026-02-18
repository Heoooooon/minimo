import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../config/app_config.dart';
import '../../../core/di/app_dependencies.dart';
import '../../../core/utils/app_logger.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../widgets/common/settings_row.dart';
import 'account_info_screen.dart';
import 'data_backup_screen.dart';
import 'notice_screen.dart';
import 'notification_settings_screen.dart';
import 'password_verify_screen.dart';
import 'terms_screen.dart';

/// 설정 화면
///
/// 계정 관리, 앱 설정, 앱 정보, 계정(로그아웃) 섹션으로 구성
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSurface,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text('설정', style: AppTextStyles.bodyMediumMedium),
      ),
      body: ListView(
        children: [
          // ── 계정 관리 ──
          const SettingsSectionHeader(title: '계정 관리'),
          SettingsRow(title: '계정 정보', onTap: () => _onAccountInfo(context)),
          SettingsRow(
            title: '비밀번호 변경',
            showDivider: false,
            onTap: () => _onChangePassword(context),
          ),

          // ── 앱 설정 ──
          const SettingsSectionHeader(title: '앱 설정'),
          SettingsRow(
            title: '알림 설정',
            onTap: () => _onNotificationSettings(context),
          ),
          SettingsRow(
            title: '데이터 백업',
            showDivider: false,
            onTap: () => _onDataBackup(context),
          ),

          // ── 앱 정보 ──
          const SettingsSectionHeader(title: '앱 정보'),
          SettingsRow(title: '공지사항', onTap: () => _onNotice(context)),
          SettingsRow(
            title: '이용 약관',
            showDivider: false,
            onTap: () => _onTerms(context),
          ),

          // ── 개발자 ──
          if (kDebugMode || AppConfig.isDebug) ...[
            const SettingsSectionHeader(title: '개발자'),
            SettingsRow(
              title: '성능 메트릭 보기',
              onTap: () => _onShowPerfMetrics(context),
            ),
            SettingsRow(
              title: '성능 메트릭 초기화',
              showDivider: false,
              onTap: () => _onClearPerfMetrics(context),
            ),
          ],

          // ── 계정 ──
          const SettingsSectionHeader(title: '계정'),
          SettingsRow(
            title: '로그아웃',
            showDivider: false,
            onTap: () => _onLogout(context),
          ),
        ],
      ),
    );
  }

  // ── 탭 핸들러 ──

  void _onAccountInfo(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AccountInfoScreen()));
  }

  void _onChangePassword(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PasswordVerifyScreen()));
  }

  void _onNotificationSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
    );
  }

  void _onDataBackup(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const DataBackupScreen()));
  }

  void _onNotice(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const NoticeScreen()));
  }

  void _onTerms(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const TermsScreen()));
  }

  Future<void> _onShowPerfMetrics(BuildContext context) async {
    final metrics = AppLogger.exportPerfMetrics(minSamples: 1);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.backgroundSurface,
        title: Text('성능 메트릭', style: AppTextStyles.titleMedium),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              metrics,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMain,
                fontFamily: 'monospace',
                height: 1.4,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: metrics));
              if (!dialogContext.mounted || !context.mounted) return;
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('성능 메트릭을 복사했습니다.')));
            },
            child: Text(
              '복사',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.brand),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              '닫기',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSubtle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onClearPerfMetrics(BuildContext context) {
    AppLogger.clearPerfMetrics();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('성능 메트릭을 초기화했습니다.')));
  }

  void _onLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundSurface,
        title: Text('로그아웃', style: AppTextStyles.titleMedium),
        content: Text(
          '정말 로그아웃 하시겠습니까?',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSubtle),
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
              Navigator.pop(context);
              _performLogout(context);
            },
            child: Text(
              '로그아웃',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout(BuildContext context) async {
    await context.read<AppDependencies>().authService.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }
}
