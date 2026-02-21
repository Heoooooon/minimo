import '../../../presentation/viewmodels/base_viewmodel.dart';
import '../../data/services/admin_content_service.dart';

/// 관리자 콘텐츠 관리 뷰모델
///
/// BaseViewModel을 상속하여 게시글, 질문, 카탈로그 목록 로딩 및 상태 관리
class AdminContentViewModel extends BaseViewModel {
  AdminContentViewModel({AdminContentService? contentService})
      : _contentService = contentService ?? AdminContentService.instance;

  final AdminContentService _contentService;

  // ============================================
  // 게시글(Posts) 상태
  // ============================================

  List<dynamic> _posts = [];
  List<dynamic> get posts => _posts;
  int _postPage = 1;
  int get postPage => _postPage;
  int _postTotalPages = 1;
  int get postTotalPages => _postTotalPages;

  // ============================================
  // 질문(Questions) 상태
  // ============================================

  List<dynamic> _questions = [];
  List<dynamic> get questions => _questions;
  int _questionPage = 1;
  int get questionPage => _questionPage;
  int _questionTotalPages = 1;
  int get questionTotalPages => _questionTotalPages;

  // ============================================
  // 카탈로그(Catalog) 상태
  // ============================================

  List<dynamic> _pendingCatalog = [];
  List<dynamic> get pendingCatalog => _pendingCatalog;
  int _catalogPage = 1;
  int get catalogPage => _catalogPage;
  int _catalogTotalPages = 1;
  int get catalogTotalPages => _catalogTotalPages;

  // ============================================
  // 필터 및 검색 상태
  // ============================================

  String? _statusFilter;
  String? get statusFilter => _statusFilter;
  String _searchQuery = '';

  /// 상태 필터 설정 후 게시글/질문 새로고침
  void setStatusFilter(String? status) {
    _statusFilter = status;
    loadPosts();
    loadQuestions();
  }

  /// 검색어 설정 후 게시글/질문 새로고침
  void setSearchQuery(String query) {
    _searchQuery = query;
    loadPosts();
    loadQuestions();
  }

  // ============================================
  // 게시글 관련 메서드
  // ============================================

  /// 게시글 목록 로드
  Future<void> loadPosts({int? page}) async {
    if (page != null) _postPage = page;
    await runAsync(() async {
      final result = await _contentService.getPosts(
        page: _postPage,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        status: _statusFilter,
      );
      _posts = result['items'] as List<dynamic>? ?? [];
      _postTotalPages = result['totalPages'] as int? ?? 1;
      return true;
    }, errorPrefix: '게시글 로딩 실패');
  }

  /// 게시글 상태 변경
  Future<bool> updatePostStatus(String id, String status) async {
    final success = await runAsync(() async {
      await _contentService.updatePostStatus(id, status);
      return true;
    }, errorPrefix: '게시글 상태 변경 실패');
    if (success == true) await loadPosts();
    return success == true;
  }

  // ============================================
  // 질문 관련 메서드
  // ============================================

  /// 질문 목록 로드
  Future<void> loadQuestions({int? page}) async {
    if (page != null) _questionPage = page;
    await runAsync(() async {
      final result = await _contentService.getQuestions(
        page: _questionPage,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        status: _statusFilter,
      );
      _questions = result['items'] as List<dynamic>? ?? [];
      _questionTotalPages = result['totalPages'] as int? ?? 1;
      return true;
    }, errorPrefix: '질문 로딩 실패');
  }

  /// 질문 상태 변경
  Future<bool> updateQuestionStatus(String id, String status) async {
    final success = await runAsync(() async {
      await _contentService.updateQuestionStatus(id, status);
      return true;
    }, errorPrefix: '질문 상태 변경 실패');
    if (success == true) await loadQuestions();
    return success == true;
  }

  // ============================================
  // 댓글/답변 삭제
  // ============================================

  /// 댓글 삭제
  Future<bool> deleteComment(String id) async {
    final success = await runAsync(() async {
      await _contentService.deleteComment(id);
      return true;
    }, errorPrefix: '댓글 삭제 실패');
    return success == true;
  }

  /// 답변 삭제
  Future<bool> deleteAnswer(String id) async {
    final success = await runAsync(() async {
      await _contentService.deleteAnswer(id);
      return true;
    }, errorPrefix: '답변 삭제 실패');
    return success == true;
  }

  // ============================================
  // 카탈로그 관련 메서드
  // ============================================

  /// 승인 대기 카탈로그 목록 로드
  Future<void> loadPendingCatalog({int? page}) async {
    if (page != null) _catalogPage = page;
    await runAsync(() async {
      final result = await _contentService.getPendingCatalog(page: _catalogPage);
      _pendingCatalog = result['items'] as List<dynamic>? ?? [];
      _catalogTotalPages = result['totalPages'] as int? ?? 1;
      return true;
    }, errorPrefix: '카탈로그 로딩 실패');
  }

  /// 카탈로그 승인/거절
  Future<bool> approveCatalog(String id, bool approved) async {
    final success = await runAsync(() async {
      await _contentService.approveCatalog(id, approved);
      return true;
    }, errorPrefix: '카탈로그 처리 실패');
    if (success == true) await loadPendingCatalog();
    return success == true;
  }
}
