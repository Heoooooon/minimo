import 'package:flutter/material.dart';
import '../../core/admin_auth_guard.dart';
import '../../theme/admin_theme.dart';
import '../widgets/admin_sidebar.dart';
import 'dashboard/admin_dashboard_screen.dart';
import 'users/admin_user_list_screen.dart';
import 'content/admin_post_list_screen.dart';
import 'reports/admin_report_list_screen.dart';

/// 관리자 패널 셸 (사이드바 + 콘텐츠 영역)
///
/// 인증 가드 적용, AdminSidebar 위젯으로 네비게이션 제공
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  AdminPage _currentPage = AdminPage.dashboard;

  /// 현재 선택된 페이지에 따라 콘텐츠 위젯 반환
  Widget _buildContent() {
    switch (_currentPage) {
      case AdminPage.dashboard:
        return const AdminDashboardScreen();
      case AdminPage.users:
        return const AdminUserListScreen();
      case AdminPage.content:
        return const AdminPostListScreen();
      case AdminPage.reports:
        return const AdminReportListScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminAuthGuard(
      child: Scaffold(
        body: Row(
          children: [
            // 사이드바 네비게이션 (로그아웃은 사이드바 내부에서 처리)
            AdminSidebar(
              currentPage: _currentPage,
              onPageChanged: (page) => setState(() => _currentPage = page),
            ),
            // 메인 콘텐츠 영역
            Expanded(
              child: Container(
                color: AdminTheme.contentBg,
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
