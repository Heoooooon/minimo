import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// 하단 네비게이션 탭 열거형
enum NavTab {
  home('홈', Icons.home_outlined, Icons.home),
  aquarium('어항', Icons.water_drop_outlined, Icons.water_drop),
  record('기록', Icons.edit_note_outlined, Icons.edit_note),
  community('커뮤니티', Icons.forum_outlined, Icons.forum),
  settings('설정', Icons.settings_outlined, Icons.settings);

  const NavTab(this.label, this.icon, this.activeIcon);
  final String label;
  final IconData icon;
  final IconData activeIcon;
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
        color: AppColors.backgroundSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? tab.activeIcon : tab.icon,
              size: 24,
              color: isSelected ? AppColors.brand : AppColors.textSubtle,
            ),
            const SizedBox(height: 4),
            Text(
              tab.label,
              style:
                  (isSelected
                          ? AppTextStyles.captionMedium
                          : AppTextStyles.captionRegular)
                      .copyWith(
                        color: isSelected
                            ? AppColors.brand
                            : AppColors.textSubtle,
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
