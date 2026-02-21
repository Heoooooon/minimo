import 'package:pocketbase/pocketbase.dart';
import '../../../data/services/pocketbase_service.dart';

/// 관리자 콘텐츠 관리 서비스
///
/// 게시글, 질문, 댓글, 답변, 카탈로그 관리 API 호출
class AdminContentService {
  AdminContentService._();
  static AdminContentService? _instance;
  static AdminContentService get instance => _instance ??= AdminContentService._();

  PocketBase get _pb => PocketBaseService.instance.client;

  /// 게시글 목록 조회 (페이징, 검색, 상태 필터)
  Future<Map<String, dynamic>> getPosts({
    int page = 1,
    int perPage = 20,
    String? search,
    String? status,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'perPage': '$perPage',
    };
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (status != null && status.isNotEmpty) params['status'] = status;

    final queryString = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    final result = await _pb.send('/api/admin/posts?$queryString');
    return Map<String, dynamic>.from(result);
  }

  /// 게시글 상태 변경
  Future<void> updatePostStatus(String id, String status) async {
    await _pb.send('/api/admin/posts/$id/status', method: 'PATCH', body: {'status': status});
  }

  /// 질문 목록 조회 (페이징, 검색, 상태 필터)
  Future<Map<String, dynamic>> getQuestions({
    int page = 1,
    int perPage = 20,
    String? search,
    String? status,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'perPage': '$perPage',
    };
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (status != null && status.isNotEmpty) params['status'] = status;

    final queryString = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    final result = await _pb.send('/api/admin/questions?$queryString');
    return Map<String, dynamic>.from(result);
  }

  /// 질문 상태 변경
  Future<void> updateQuestionStatus(String id, String status) async {
    await _pb.send('/api/admin/questions/$id/status', method: 'PATCH', body: {'status': status});
  }

  /// 댓글 삭제
  Future<void> deleteComment(String id) async {
    await _pb.send('/api/admin/comments/$id', method: 'DELETE');
  }

  /// 답변 삭제
  Future<void> deleteAnswer(String id) async {
    await _pb.send('/api/admin/answers/$id', method: 'DELETE');
  }

  /// 승인 대기중인 카탈로그 목록 조회
  Future<Map<String, dynamic>> getPendingCatalog({
    int page = 1,
    int perPage = 20,
  }) async {
    final result = await _pb.send('/api/admin/catalog/pending?page=$page&perPage=$perPage');
    return Map<String, dynamic>.from(result);
  }

  /// 카탈로그 승인/거절
  Future<void> approveCatalog(String id, bool approved) async {
    await _pb.send('/api/admin/catalog/$id/approve', method: 'PATCH', body: {'approved': approved});
  }
}
