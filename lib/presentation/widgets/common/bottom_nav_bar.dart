import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 하단 네비게이션 탭 열거형
enum NavTab {
  home('홈', 'assets/icons/icon_home.svg'),
  aquarium('어항', 'assets/icons/icon_aquarium.svg'),
  record('기록', 'assets/icons/icon_record.svg'),
  community('커뮤니티', 'assets/icons/icon_community.svg'),
  settings('설정', 'assets/icons/icon_settings.svg');

  const NavTab(this.label, this.iconPath);
  final String label;
  final String iconPath;
}

/// 하단 네비게이션 바 위젯
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  final NavTab currentTab;
  final ValueChanged<NavTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFF),
        border: const Border(
          top: BorderSide(color: Color(0xFFE8EBF0), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 68,
          padding: const EdgeInsets.only(top: 0, bottom: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: NavTab.values.map((tab) {
              final isSelected = currentTab == tab;
              return _NavItem(
                tab: tab,
                isSelected: isSelected,
                onTap: () => onTabSelected(tab),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.isSelected,
    required this.onTap,
  });

  final NavTab tab;
  final bool isSelected;
  final VoidCallback onTap;

  // Figma 스펙
  static const Color _activeColor = Color(0xFF0165FE);
  static const Color _inactiveColor = Color(0xFF9CA5AE);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              tab.iconPath,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                isSelected ? _activeColor : _inactiveColor,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              tab.label,
              style: TextStyle(
                fontFamily: 'WantedSans',
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? _activeColor : _inactiveColor,
                height: 1.5,
                letterSpacing: -0.154,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
