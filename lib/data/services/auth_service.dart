import 'package:pocketbase/pocketbase.dart';
import 'pocketbase_service.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../../core/utils/app_logger.dart';

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
      final authData = await _pb
          .collection('users')
          .authWithPassword(email, password);
      AppLogger.auth('Login successful: ${authData.record.id}');
      return authData.record;
    } on ClientException catch (e) {
      AppLogger.auth('Login failed: $e', isError: true);
      // PocketBase 에러 코드 매핑
      if (e.statusCode == 400) {
        throw AuthException.invalidCredentials();
      }
      throw NetworkException.clientError(
        message: '로그인에 실패했습니다.',
        statusCode: e.statusCode,
        originalError: e,
      );
    } catch (e) {
      AppLogger.auth('Login failed: $e', isError: true);
      throw NetworkException(message: '로그인 중 오류가 발생했습니다.', originalError: e);
    }
  }

  /// 이메일 회원가입
  Future<RecordModel> signUpWithEmail({
    required String email,
    required String password,
    required String passwordConfirm,
    required String name,
  }) async {
    // 비밀번호 유효성 검사
    if (password.length < 8) {
      throw AuthException.weakPassword();
    }
    if (password != passwordConfirm) {
      throw AuthException.passwordMismatch();
    }

    try {
      final record = await _pb
          .collection('users')
          .create(
            body: {
              'email': email,
              'password': password,
              'passwordConfirm': passwordConfirm,
              'name': name,
            },
          );
      AppLogger.auth('Sign up successful: ${record.id}');

      // 회원가입 후 자동 로그인
      await loginWithEmail(email: email, password: password);

      return record;
    } on ClientException catch (e) {
      AppLogger.auth('Sign up failed: $e', isError: true);
      // PocketBase 에러 코드 매핑
      final errorData = e.response['data'] as Map<String, dynamic>?;
      if (errorData != null && errorData.containsKey('email')) {
        throw AuthException.emailAlreadyExists();
      }
      throw NetworkException.clientError(
        message: '회원가입에 실패했습니다.',
        statusCode: e.statusCode,
        originalError: e,
      );
    } catch (e) {
      AppLogger.auth('Sign up failed: $e', isError: true);
      throw NetworkException(message: '회원가입 중 오류가 발생했습니다.', originalError: e);
    }
  }

  /// 이메일 인증 요청 (실제 구현시 서버에서 처리)
  Future<void> requestEmailVerification(String email) async {
    try {
      await _pb.collection('users').requestVerification(email);
      AppLogger.auth('Verification email sent to: $email');
    } on ClientException catch (e) {
      AppLogger.auth('Verification request failed: $e', isError: true);
      throw NetworkException.clientError(
        message: '인증 메일 전송에 실패했습니다.',
        statusCode: e.statusCode,
        originalError: e,
      );
    } catch (e) {
      AppLogger.auth('Verification request failed: $e', isError: true);
      throw NetworkException(message: '인증 요청 중 오류가 발생했습니다.', originalError: e);
    }
  }

  /// 로그아웃
  void logout() {
    _pb.authStore.clear();
    AppLogger.auth('Logged out');
  }

  /// 비밀번호 재설정 요청
  Future<void> requestPasswordReset(String email) async {
    try {
      await _pb.collection('users').requestPasswordReset(email);
      AppLogger.auth('Password reset email sent to: $email');
    } on ClientException catch (e) {
      AppLogger.auth('Password reset request failed: $e', isError: true);
      throw NetworkException.clientError(
        message: '비밀번호 재설정 메일 전송에 실패했습니다.',
        statusCode: e.statusCode,
        originalError: e,
      );
    } catch (e) {
      AppLogger.auth('Password reset request failed: $e', isError: true);
      throw NetworkException(
        message: '비밀번호 재설정 요청 중 오류가 발생했습니다.',
        originalError: e,
      );
    }
  }

  /// OAuth2 소셜 로그인 (카카오, 구글, 네이버, 애플)
  Future<RecordModel?> loginWithOAuth2(String provider) async {
    try {
      final authData = await _pb.collection('users').authWithOAuth2(provider, (
        url,
      ) async {
        // URL을 열어서 OAuth2 인증 진행
        AppLogger.auth('OAuth2 URL: $url');
      });
      AppLogger.auth('OAuth2 login successful: ${authData.record.id}');
      return authData.record;
    } on ClientException catch (e) {
      AppLogger.auth('OAuth2 login failed: $e', isError: true);
      throw NetworkException.clientError(
        message: '소셜 로그인에 실패했습니다.',
        statusCode: e.statusCode,
        originalError: e,
      );
    } catch (e) {
      AppLogger.auth('OAuth2 login failed: $e', isError: true);
      throw NetworkException(message: '소셜 로그인 중 오류가 발생했습니다.', originalError: e);
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
      AppLogger.auth('Verification code sent: $response');
      return response['success'] == true;
    } on ClientException catch (e) {
      AppLogger.auth('Failed to send verification code: $e', isError: true);
      throw NetworkException.clientError(
        message: '인증 코드 전송에 실패했습니다.',
        statusCode: e.statusCode,
        originalError: e,
      );
    } catch (e) {
      AppLogger.auth('Failed to send verification code: $e', isError: true);
      throw NetworkException(
        message: '인증 코드 전송 중 오류가 발생했습니다.',
        originalError: e,
      );
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
      AppLogger.auth('Code verified: $response');
      return response['success'] == true;
    } on ClientException catch (e) {
      AppLogger.auth('Failed to verify code: $e', isError: true);
      if (e.statusCode == 400) {
        throw const AuthException(
          message: '인증 코드가 올바르지 않습니다.',
          code: 'INVALID_CODE',
        );
      }
      throw NetworkException.clientError(
        message: '인증 코드 검증에 실패했습니다.',
        statusCode: e.statusCode,
        originalError: e,
      );
    } catch (e) {
      AppLogger.auth('Failed to verify code: $e', isError: true);
      throw NetworkException(
        message: '인증 코드 검증 중 오류가 발생했습니다.',
        originalError: e,
      );
    }
  }
}
