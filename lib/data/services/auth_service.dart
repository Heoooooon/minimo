import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'pocketbase_service.dart';

/// 인증 서비스
///
/// PocketBase 인증 기능을 래핑하여 제공
class AuthService {
  AuthService._();

  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();

  PocketBase get _pb => PocketBaseService.instance.client;

  /// 현재 로그인된 사용자
  RecordModel? get currentUser => _pb.authStore.record;

  /// 로그인 상태 확인
  bool get isLoggedIn => _pb.authStore.isValid;

  /// 이메일/비밀번호로 로그인
  Future<RecordModel> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final authData = await _pb.collection('users').authWithPassword(
        email,
        password,
      );
      debugPrint('Login successful: ${authData.record.id}');
      return authData.record;
    } catch (e) {
      debugPrint('Login failed: $e');
      rethrow;
    }
  }

  /// 이메일 회원가입
  Future<RecordModel> signUpWithEmail({
    required String email,
    required String password,
    required String passwordConfirm,
    required String name,
  }) async {
    try {
      final record = await _pb.collection('users').create(body: {
        'email': email,
        'password': password,
        'passwordConfirm': passwordConfirm,
        'name': name,
      });
      debugPrint('Sign up successful: ${record.id}');

      // 회원가입 후 자동 로그인
      await loginWithEmail(email: email, password: password);

      return record;
    } catch (e) {
      debugPrint('Sign up failed: $e');
      rethrow;
    }
  }

  /// 이메일 인증 요청 (실제 구현시 서버에서 처리)
  Future<void> requestEmailVerification(String email) async {
    try {
      await _pb.collection('users').requestVerification(email);
      debugPrint('Verification email sent to: $email');
    } catch (e) {
      debugPrint('Verification request failed: $e');
      rethrow;
    }
  }

  /// 로그아웃
  void logout() {
    _pb.authStore.clear();
    debugPrint('Logged out');
  }

  /// 비밀번호 재설정 요청
  Future<void> requestPasswordReset(String email) async {
    try {
      await _pb.collection('users').requestPasswordReset(email);
      debugPrint('Password reset email sent to: $email');
    } catch (e) {
      debugPrint('Password reset request failed: $e');
      rethrow;
    }
  }

  /// OAuth2 소셜 로그인 (카카오, 구글, 네이버, 애플)
  Future<RecordModel?> loginWithOAuth2(String provider) async {
    try {
      final authData = await _pb.collection('users').authWithOAuth2(
        provider,
        (url) async {
          // URL을 열어서 OAuth2 인증 진행
          debugPrint('OAuth2 URL: $url');
        },
      );
      debugPrint('OAuth2 login successful: ${authData.record.id}');
      return authData.record;
    } catch (e) {
      debugPrint('OAuth2 login failed: $e');
      rethrow;
    }
  }

  /// 4자리 인증 코드 요청 (커스텀 API)
  Future<bool> sendVerificationCode(String email) async {
    try {
      final response = await _pb.send(
        '/api/custom/send-code',
        method: 'POST',
        body: {'email': email},
      );
      debugPrint('Verification code sent: $response');
      return response['success'] == true;
    } catch (e) {
      debugPrint('Failed to send verification code: $e');
      rethrow;
    }
  }

  /// 4자리 인증 코드 검증 (커스텀 API)
  Future<bool> verifyCode(String email, String code) async {
    try {
      final response = await _pb.send(
        '/api/custom/verify-code',
        method: 'POST',
        body: {'email': email, 'code': code},
      );
      debugPrint('Code verified: $response');
      return response['success'] == true;
    } catch (e) {
      debugPrint('Failed to verify code: $e');
      rethrow;
    }
  }
}
