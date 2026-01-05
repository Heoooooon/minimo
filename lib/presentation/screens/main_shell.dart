import 'package:flutter/material.dart';
import '../widgets/common/bottom_nav_bar.dart';
import 'home_screen.dart';
import 'aquarium/aquarium_list_screen.dart';
import 'record_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// 메인 셸 화면
///
/// BottomNavBar와 화면 전환을 관리하는 컨테이너
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  NavTab _currentTab = NavTab.home;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: AppBottomNavBar(
        currentTab: _currentTab,
        onTabSelected: (tab) {
          setState(() {
            _currentTab = tab;
          });
        },
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentTab) {
      case NavTab.home:
        return const HomeContent();
      case NavTab.aquarium:
        return const AquariumListScreen();
      case NavTab.record:
        return const RecordScreen();
      case NavTab.community:
        return const _PlaceholderScreen(title: '커뮤니티');
      case NavTab.settings:
        return const _PlaceholderScreen(title: '설정');
    }
  }
}

/// 플레이스홀더 화면 (추후 구현 예정)
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSurface,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundSurface,
        elevation: 0,
        centerTitle: true,
        title: Text(title, style: AppTextStyles.bodyMediumMedium),
      ),
      body: Center(
        child: Text(
          '$title 화면\n(추후 구현)',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSubtle),
        ),
      ),
    );
  }
}
