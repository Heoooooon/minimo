import 'package:pocketbase/pocketbase.dart';
import '../../../data/services/pocketbase_service.dart';
import '../../../core/utils/app_logger.dart';

/// 관리자 인증 서비스
///
/// 관리자 로그인/로그아웃 및 권한 확인
class AdminAuthService {
  AdminAuthService._();
  static AdminAuthService? _instance;
  static AdminAuthService get instance => _instance ??= AdminAuthService._();

  PocketBase get _pb => PocketBaseService.instance.client;

  /// 현재 로그인된 사용자
  RecordModel? get currentUser => _pb.authStore.record;

  /// 로그인 여부
  bool get isLoggedIn => _pb.authStore.isValid;

  /// 관리자 권한 확인
  bool get isAdmin {
    if (!isLoggedIn || currentUser == null) return false;
    return currentUser!.getStringValue('role') == 'admin';
  }

  /// 관리자 이름
  String get adminName => currentUser?.getStringValue('name') ?? '관리자';

  /// 관리자 이메일
  String get adminEmail => currentUser?.getStringValue('email') ?? '';

  /// 관리자 로그인
  Future<RecordModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final authData = await _pb.collection('users').authWithPassword(email, password);

      if (authData.record.getStringValue('role') != 'admin') {
        _pb.authStore.clear();
        throw Exception('관리자 권한이 없습니다.');
      }

      AppLogger.auth('Admin login successful: ${authData.record.id}');
      return authData.record;
    } catch (e) {
      AppLogger.auth('Admin login failed: $e', isError: true);
      rethrow;
    }
  }

  /// 관리자 로그아웃
  void logout() {
    _pb.authStore.clear();
    AppLogger.auth('Admin logged out');
  }
}
