import 'package:pocketbase/pocketbase.dart';
import '../../../data/services/pocketbase_service.dart';

/// 관리자 통계 서비스
///
/// 대시보드 개요 및 활동 통계 API 호출
class AdminStatsService {
  AdminStatsService._();
  static AdminStatsService? _instance;
  static AdminStatsService get instance => _instance ??= AdminStatsService._();

  PocketBase get _pb => PocketBaseService.instance.client;

  /// 대시보드 개요 통계 조회
  Future<Map<String, dynamic>> getOverview() async {
    final result = await _pb.send('/api/admin/stats/overview');
    return Map<String, dynamic>.from(result);
  }

  /// 활동 통계 조회 (기간별)
  Future<List<Map<String, dynamic>>> getActivity({int days = 7}) async {
    final result = await _pb.send('/api/admin/stats/activity?days=$days');
    return (result as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }
}
