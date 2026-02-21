import '../../../presentation/viewmodels/base_viewmodel.dart';
import '../../data/services/admin_stats_service.dart';

/// 관리자 대시보드 뷰모델
///
/// BaseViewModel을 상속하여 대시보드 통계 데이터 로딩 및 상태 관리
class AdminDashboardViewModel extends BaseViewModel {
  AdminDashboardViewModel({AdminStatsService? statsService})
      : _statsService = statsService ?? AdminStatsService.instance;

  final AdminStatsService _statsService;

  /// 대시보드 개요 데이터
  Map<String, dynamic>? _overview;
  Map<String, dynamic>? get overview => _overview;

  /// 최근 활동 데이터 (7일 기준)
  List<Map<String, dynamic>> _activity = [];
  List<Map<String, dynamic>> get activity => _activity;

  /// 대시보드 데이터 전체 로드
  Future<void> loadDashboard() async {
    await runAsync(() async {
      final results = await Future.wait([
        _statsService.getOverview(),
        _statsService.getActivity(days: 7),
      ]);
      _overview = results[0] as Map<String, dynamic>;
      _activity = results[1] as List<Map<String, dynamic>>;
      return true;
    }, errorPrefix: '대시보드 로딩 실패');
  }
}
