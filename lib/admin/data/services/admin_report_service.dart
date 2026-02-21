import 'package:pocketbase/pocketbase.dart';
import '../../../data/services/pocketbase_service.dart';

/// 관리자 신고 관리 서비스
///
/// 신고 목록 조회, 상세 조회, 처리 등
class AdminReportService {
  AdminReportService._();
  static AdminReportService? _instance;
  static AdminReportService get instance => _instance ??= AdminReportService._();

  PocketBase get _pb => PocketBaseService.instance.client;

  /// 신고 목록 조회 (페이징, 상태 필터)
  Future<Map<String, dynamic>> getReports({
    int page = 1,
    int perPage = 20,
    String? status,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'perPage': '$perPage',
    };
    if (status != null && status.isNotEmpty) params['status'] = status;

    final queryString = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    final result = await _pb.send('/api/admin/reports?$queryString');
    return Map<String, dynamic>.from(result);
  }

  /// 신고 상세 조회
  Future<Map<String, dynamic>> getReport(String id) async {
    final result = await _pb.send('/api/admin/reports/$id');
    return Map<String, dynamic>.from(result);
  }

  /// 신고 처리 (액션 및 관리자 메모)
  Future<void> resolveReport(String id, {required String action, String? adminNote}) async {
    await _pb.send('/api/admin/reports/$id/resolve', method: 'PATCH', body: {
      'action': action,
      if (adminNote != null) 'admin_note': adminNote,
    });
  }
}
