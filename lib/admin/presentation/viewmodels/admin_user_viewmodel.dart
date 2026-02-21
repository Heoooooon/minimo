import '../../../presentation/viewmodels/base_viewmodel.dart';
import '../../data/services/admin_user_service.dart';

/// 관리자 사용자 관리 뷰모델
///
/// BaseViewModel을 상속하여 사용자 목록 로딩, 검색, 역할/상태 변경 등 관리
class AdminUserViewModel extends BaseViewModel {
  AdminUserViewModel({AdminUserService? userService})
      : _userService = userService ?? AdminUserService.instance;

  final AdminUserService _userService;

  /// 사용자 목록
  List<dynamic> _users = [];
  List<dynamic> get users => _users;

  /// 선택된 사용자 상세 정보
  Map<String, dynamic>? _selectedUser;
  Map<String, dynamic>? get selectedUser => _selectedUser;

  /// 페이지네이션 상태
  int _currentPage = 1;
  int get currentPage => _currentPage;
  int _totalPages = 1;
  int get totalPages => _totalPages;
  int _totalItems = 0;
  int get totalItems => _totalItems;

  /// 검색 및 필터 상태
  String _searchQuery = '';
  String get searchQuery => _searchQuery;
  String? _roleFilter;
  String? get roleFilter => _roleFilter;

  /// 검색어 설정 후 목록 새로고침
  void setSearchQuery(String query) {
    _searchQuery = query;
    _currentPage = 1;
    loadUsers();
  }

  /// 역할 필터 설정 후 목록 새로고침
  void setRoleFilter(String? role) {
    _roleFilter = role;
    _currentPage = 1;
    loadUsers();
  }

  /// 특정 페이지로 이동
  void goToPage(int page) {
    _currentPage = page;
    loadUsers();
  }

  /// 사용자 목록 로드
  Future<void> loadUsers() async {
    await runAsync(() async {
      final result = await _userService.getUsers(
        page: _currentPage,
        perPage: 20,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        role: _roleFilter,
      );
      _users = result['items'] as List<dynamic>? ?? [];
      _totalPages = result['totalPages'] as int? ?? 1;
      _totalItems = result['totalItems'] as int? ?? 0;
      return true;
    }, errorPrefix: '사용자 목록 로딩 실패');
  }

  /// 사용자 상세 정보 로드
  Future<void> loadUserDetail(String id) async {
    await runAsync(() async {
      _selectedUser = await _userService.getUser(id);
      return true;
    }, errorPrefix: '사용자 상세 로딩 실패');
  }

  /// 사용자 역할 변경
  Future<bool> updateUserRole(String id, String role) async {
    final success = await runAsync(() async {
      await _userService.updateRole(id, role);
      return true;
    }, errorPrefix: '역할 변경 실패');
    if (success == true) {
      await loadUsers();
      // 선택된 사용자가 변경 대상이면 상세 정보도 새로고침
      if (_selectedUser != null && _selectedUser!['id'] == id) {
        await loadUserDetail(id);
      }
    }
    return success == true;
  }

  /// 사용자 상태(인증 여부) 변경
  Future<bool> updateUserStatus(String id, bool verified) async {
    final success = await runAsync(() async {
      await _userService.updateStatus(id, verified);
      return true;
    }, errorPrefix: '상태 변경 실패');
    if (success == true) await loadUsers();
    return success == true;
  }
}
