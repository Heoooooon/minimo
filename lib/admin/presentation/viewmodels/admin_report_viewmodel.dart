import '../../../presentation/viewmodels/base_viewmodel.dart';
import '../../data/services/admin_report_service.dart';

/// 관리자 신고 관리 뷰모델
///
/// BaseViewModel을 상속하여 신고 목록 로딩, 상세 조회, 처리 등 관리
class AdminReportViewModel extends BaseViewModel {
  AdminReportViewModel({AdminReportService? reportService})
      : _reportService = reportService ?? AdminReportService.instance;

  final AdminReportService _reportService;

  /// 신고 목록
  List<dynamic> _reports = [];
  List<dynamic> get reports => _reports;

  /// 선택된 신고 상세 정보
  Map<String, dynamic>? _selectedReport;
  Map<String, dynamic>? get selectedReport => _selectedReport;

  /// 페이지네이션 상태
  int _currentPage = 1;
  int get currentPage => _currentPage;
  int _totalPages = 1;
  int get totalPages => _totalPages;

  /// 상태 필터 (기본값: pending)
  String _statusFilter = 'pending';
  String get statusFilter => _statusFilter;

  /// 상태 필터 설정 후 목록 새로고침
  void setStatusFilter(String status) {
    _statusFilter = status;
    _currentPage = 1;
    loadReports();
  }

  /// 특정 페이지로 이동
  void goToPage(int page) {
    _currentPage = page;
    loadReports();
  }

  /// 신고 목록 로드
  Future<void> loadReports() async {
    await runAsync(() async {
      final result = await _reportService.getReports(
        page: _currentPage,
        status: _statusFilter.isNotEmpty ? _statusFilter : null,
      );
      _reports = result['items'] as List<dynamic>? ?? [];
      _totalPages = result['totalPages'] as int? ?? 1;
      return true;
    }, errorPrefix: '신고 목록 로딩 실패');
  }

  /// 신고 상세 정보 로드
  Future<void> loadReportDetail(String id) async {
    await runAsync(() async {
      _selectedReport = await _reportService.getReport(id);
      return true;
    }, errorPrefix: '신고 상세 로딩 실패');
  }

  /// 신고 처리 (액션 및 관리자 메모)
  Future<bool> resolveReport(String id, {required String action, String? adminNote}) async {
    final success = await runAsync(() async {
      await _reportService.resolveReport(id, action: action, adminNote: adminNote);
      return true;
    }, errorPrefix: '신고 처리 실패');
    if (success == true) {
      await loadReports();
      _selectedReport = null;
    }
    return success == true;
  }
}
