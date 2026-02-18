import 'package:flutter/material.dart';
import '../../data/services/data_backup_service.dart';
import '../widgets/common/bottom_nav_bar.dart';
import 'home_screen.dart';
import 'aquarium/aquarium_list_screen.dart';
import 'record_home_screen.dart';
import 'community/community_screen.dart';
import 'settings/settings_screen.dart';

/// 메인 셸 화면
///
/// BottomNavBar와 화면 전환을 관리하는 컨테이너
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _currentTabIndex = 0;
  // ignore: unused_field - 탭 전환 애니메이션 방향 결정용 (추후 활용)
  int _previousTabIndex = 0;

  // 각 화면의 GlobalKey
  final GlobalKey<HomeContentState> _homeKey = GlobalKey<HomeContentState>();
  final GlobalKey<AquariumListScreenState> _aquariumListKey =
      GlobalKey<AquariumListScreenState>();
  final GlobalKey<RecordHomeScreenState> _recordHomeKey =
      GlobalKey<RecordHomeScreenState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _screens = [
      HomeContent(key: _homeKey),
      AquariumListScreen(key: _aquariumListKey),
      RecordHomeScreen(key: _recordHomeKey),
      const CommunityScreen(),
      const SettingsScreen(),
    ];
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      DataBackupService.instance.performAutoBackupIfNeeded();
    }
  }

  void _onTabSelected(NavTab tab) {
    final newIndex = tab.index;

    if (newIndex != _currentTabIndex) {
      _previousTabIndex = _currentTabIndex;
      setState(() {
        _currentTabIndex = newIndex;
      });

      // 탭 전환 시 해당 화면 새로고침 트리거
      _refreshTabData(newIndex);
    }
  }

  /// 탭 전환 시 데이터 새로고침
  void _refreshTabData(int tabIndex) {
    // 약간의 딜레이 후 새로고침 (UI 전환 완료 후)
    Future.microtask(() {
      switch (tabIndex) {
        case 0:
          _homeKey.currentState?.refreshData();
          break;
        case 1:
          _aquariumListKey.currentState?.refreshData();
          break;
        case 2:
          _recordHomeKey.currentState?.refreshData();
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentTabIndex, children: _screens),
      bottomNavigationBar: AppBottomNavBar(
        currentTab: NavTab.values[_currentTabIndex],
        onTabSelected: _onTabSelected,
      ),
    );
  }
}
