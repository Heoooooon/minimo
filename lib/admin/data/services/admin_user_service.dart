import 'package:pocketbase/pocketbase.dart';
import '../../../data/services/pocketbase_service.dart';

/// 관리자 사용자 관리 서비스
///
/// 사용자 목록 조회, 역할 변경, 상태 변경 등
class AdminUserService {
  AdminUserService._();
  static AdminUserService? _instance;
  static AdminUserService get instance => _instance ??= AdminUserService._();

  PocketBase get _pb => PocketBaseService.instance.client;

  /// 사용자 목록 조회 (페이징, 검색, 역할 필터)
  Future<Map<String, dynamic>> getUsers({
    int page = 1,
    int perPage = 20,
    String? search,
    String? role,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'perPage': '$perPage',
    };
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (role != null && role.isNotEmpty) params['role'] = role;

    final queryString = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    final result = await _pb.send('/api/admin/users?$queryString');
    return Map<String, dynamic>.from(result);
  }

  /// 개별 사용자 상세 조회
  Future<Map<String, dynamic>> getUser(String id) async {
    final result = await _pb.send('/api/admin/users/$id');
    return Map<String, dynamic>.from(result);
  }

  /// 사용자 역할 변경
  Future<void> updateRole(String id, String role) async {
    await _pb.send('/api/admin/users/$id/role', method: 'PATCH', body: {'role': role});
  }

  /// 사용자 상태(인증 여부) 변경
  Future<void> updateStatus(String id, bool verified) async {
    await _pb.send('/api/admin/users/$id/status', method: 'PATCH', body: {'verified': verified});
  }
}
