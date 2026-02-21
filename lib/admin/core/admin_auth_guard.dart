import 'package:flutter/material.dart';
import '../data/services/admin_auth_service.dart';
import '../presentation/screens/admin_login_screen.dart';

/// 관리자 인증 가드 위젯
///
/// 관리자 권한이 없으면 로그인 화면으로 리다이렉트
class AdminAuthGuard extends StatelessWidget {
  const AdminAuthGuard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!AdminAuthService.instance.isAdmin) {
      return const AdminLoginScreen();
    }
    return child;
  }
}
