import 'package:flutter/material.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_spacing.dart';
import '../../theme/admin_theme.dart';
import '../../data/services/admin_auth_service.dart';

/// 관리자 페이지 열거형
enum AdminPage { dashboard, users, content, reports }

/// 관리자 패널 사이드바 네비게이션
///
/// 260px 너비의 다크 사이드바로, 페이지 전환 및 관리자 정보/로그아웃 제공
class AdminSidebar extends StatelessWidget {
  const AdminSidebar({
    super.key,
    required this.currentPage,
    required this.onPageChanged,
  });

  final AdminPage currentPage;
  final ValueChanged<AdminPage> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: AdminTheme.sidebarBg,
      child: Column(
        children: [
          // 로고/브랜드 영역
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.centerLeft,
            child: const Text(
              '우물 관리자',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Divider(color: AppColors.slate700, height: 1),
          const SizedBox(height: 8),
          // 네비게이션 항목들
          _NavItem(
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            label: '대시보드',
            isActive: currentPage == AdminPage.dashboard,
            onTap: () => onPageChanged(AdminPage.dashboard),
          ),
          _NavItem(
            icon: Icons.people_outlined,
            activeIcon: Icons.people,
            label: '사용자 관리',
            isActive: currentPage == AdminPage.users,
            onTap: () => onPageChanged(AdminPage.users),
          ),
          _NavItem(
            icon: Icons.article_outlined,
            activeIcon: Icons.article,
            label: '콘텐츠 관리',
            isActive: currentPage == AdminPage.content,
            onTap: () => onPageChanged(AdminPage.content),
          ),
          _NavItem(
            icon: Icons.flag_outlined,
            activeIcon: Icons.flag,
            label: '신고 관리',
            isActive: currentPage == AdminPage.reports,
            onTap: () => onPageChanged(AdminPage.reports),
          ),
          const Spacer(),
          // 관리자 정보 및 로그아웃
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.slate500,
                  child: Icon(Icons.person, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AdminAuthService.instance.adminName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        AdminAuthService.instance.adminEmail,
                        style: const TextStyle(
                          color: AppColors.slate400,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, size: 18, color: AppColors.slate400),
                  onPressed: () {
                    AdminAuthService.instance.logout();
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/admin/login',
                      (_) => false,
                    );
                  },
                  tooltip: '로그아웃',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 사이드바 네비게이션 항목
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isActive ? AdminTheme.sidebarActiveBg : Colors.transparent,
        borderRadius: AppRadius.smBorderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.smBorderRadius,
          hoverColor: AppColors.slate700.withValues(alpha: 0.5),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  size: 20,
                  color: isActive
                      ? AdminTheme.sidebarActiveText
                      : AdminTheme.sidebarText,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive
                        ? AdminTheme.sidebarActiveText
                        : AdminTheme.sidebarText,
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
