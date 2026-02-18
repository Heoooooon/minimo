import 'package:pocketbase/pocketbase.dart';
import 'package:url_launcher/url_launcher.dart';
import 'pocketbase_service.dart';
import 'fcm_service.dart';
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
  Future<void> logout() async {
    // 서버에서 FCM 토큰 제거 (로그아웃 전에 호출해야 userId 접근 가능)
    await FcmService.instance.clearTokenOnLogout();
    _pb.authStore.clear();
    AppLogger.auth('Logged out');
  }

  /// 현재 비밀번호 검증 (재인증)
  Future<bool> verifyCurrentPassword(String password) async {
    final user = currentUser;
    if (user == null) {
      throw AuthException.unauthorized();
    }

    try {
      final email = user.getStringValue('email');
      await _pb.collection('users').authWithPassword(email, password);
      AppLogger.auth('Password verification successful');
      return true;
    } on ClientException catch (e) {
      AppLogger.auth('Password verification failed: $e', isError: true);
      if (e.statusCode == 400) {
        return false;
      }
      throw NetworkException.clientError(
        message: '비밀번호 확인에 실패했습니다.',
        statusCode: e.statusCode,
        originalError: e,
      );
    } catch (e) {
      AppLogger.auth('Password verification failed: $e', isError: true);
      throw NetworkException(
        message: '비밀번호 확인 중 오류가 발생했습니다.',
        originalError: e,
      );
    }
  }

  /// 비밀번호 변경
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw AuthException.unauthorized();
    }

    // 유효성 검사
    if (newPassword.length < 8 || newPassword.length > 16) {
      throw AuthException.weakPassword();
    }
    if (newPassword != newPasswordConfirm) {
      throw AuthException.passwordMismatch();
    }

    try {
      await _pb
          .collection('users')
          .update(
            user.id,
            body: {
              'oldPassword': oldPassword,
              'password': newPassword,
              'passwordConfirm': newPasswordConfirm,
            },
          );
      AppLogger.auth('Password changed successfully');

      // 비밀번호 변경 후 새 비밀번호로 재인증
      final email = user.getStringValue('email');
      await _pb.collection('users').authWithPassword(email, newPassword);
      AppLogger.auth('Re-authenticated with new password');
    } on ClientException catch (e) {
      AppLogger.auth('Password change failed: $e', isError: true);
      if (e.statusCode == 400) {
        throw const AuthException(
          message: '현재 비밀번호가 올바르지 않습니다.',
          code: 'INVALID_OLD_PASSWORD',
        );
      }
      throw NetworkException.clientError(
        message: '비밀번호 변경에 실패했습니다.',
        statusCode: e.statusCode,
        originalError: e,
      );
    } catch (e) {
      AppLogger.auth('Password change failed: $e', isError: true);
      throw NetworkException(
        message: '비밀번호 변경 중 오류가 발생했습니다.',
        originalError: e,
      );
    }
  }

  /// 닉네임(이름) 변경
  Future<RecordModel> updateName(String newName) async {
    final user = currentUser;
    if (user == null) {
      throw AuthException.unauthorized();
    }

    try {
      final updated = await _pb
          .collection('users')
          .update(user.id, body: {'name': newName});
      AppLogger.auth('Name updated to: $newName');

      // authStore 갱신
      await _pb.collection('users').authRefresh();
      return updated;
    } on ClientException catch (e) {
      AppLogger.auth('Name update failed: $e', isError: true);
      throw NetworkException.clientError(
        message: '닉네임 변경에 실패했습니다.',
        statusCode: e.statusCode,
        originalError: e,
      );
    } catch (e) {
      AppLogger.auth('Name update failed: $e', isError: true);
      throw NetworkException(message: '닉네임 변경 중 오류가 발생했습니다.', originalError: e);
    }
  }

  /// 회원 탈퇴
  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) {
      throw AuthException.unauthorized();
    }

    try {
      await _pb.collection('users').delete(user.id);
      _pb.authStore.clear();
      AppLogger.auth('Account deleted: ${user.id}');
    } on ClientException catch (e) {
      AppLogger.auth('Account deletion failed: $e', isError: true);
      throw NetworkException.clientError(
        message: '회원 탈퇴에 실패했습니다.',
        statusCode: e.statusCode,
        originalError: e,
      );
    } catch (e) {
      AppLogger.auth('Account deletion failed: $e', isError: true);
      throw NetworkException(message: '회원 탈퇴 중 오류가 발생했습니다.', originalError: e);
    }
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
        AppLogger.auth('OAuth2 URL: $url');
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('OAuth2 URL을 열 수 없습니다.');
        }
      });
      AppLogger.auth('OAuth2 login successful: ${authData.record.id}');

      // 로그인 성공 후 토큰 저장
      await PocketBaseService.instance.onLoginSuccess();

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
