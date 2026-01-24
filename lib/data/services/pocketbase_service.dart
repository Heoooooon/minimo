import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';
import '../../core/utils/app_logger.dart';

/// PocketBase 서비스
///
/// PocketBase 클라이언트 초기화 및 공통 기능 제공
class PocketBaseService {
  PocketBaseService._();

  static PocketBaseService? _instance;
  static PocketBaseService get instance => _instance ??= PocketBaseService._();

  PocketBase? _client;

  static const String _tokenKey = 'pb_auth_token';
  static const String _recordKey = 'pb_auth_record';
  static const String _autoLoginKey = 'auto_login_enabled';

  /// PocketBase 클라이언트 getter
  PocketBase get client {
    if (_client == null) {
      throw Exception(
        'PocketBase client not initialized. Call initialize() first.',
      );
    }
    return _client!;
  }

  /// 초기화 여부
  bool get isInitialized => _client != null;

  /// PocketBase 서버 URL
  /// AppConfig에서 환경변수를 통해 관리
  static String get serverUrl => AppConfig.pocketbaseUrl;

  /// PocketBase 초기화
  Future<void> initialize({String? customUrl}) async {
    final url = customUrl ?? serverUrl;
    _client = PocketBase(url);
    AppLogger.network('PocketBase initialized with URL: $url');

    // 자동 로그인이 활성화되어 있으면 저장된 토큰 복원
    await _restoreAuthIfEnabled();
  }

  /// 테스트용 초기화 (mock client 주입)
  @visibleForTesting
  void initializeForTesting(PocketBase mockClient) {
    _client = mockClient;
    AppLogger.debug('PocketBase initialized with mock client for testing');
  }

  /// 테스트용 리셋
  @visibleForTesting
  void resetForTesting() {
    _client = null;
    _instance = null;
  }

  /// 자동 로그인 설정 저장
  Future<void> setAutoLogin(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoLoginKey, enabled);
    AppLogger.auth('Auto login set to: $enabled');

    if (enabled && _client?.authStore.isValid == true) {
      // 자동 로그인 활성화 시 현재 토큰 저장
      await _saveAuth();
    } else if (!enabled) {
      // 자동 로그인 비활성화 시 저장된 토큰 삭제
      await _clearSavedAuth();
    }
  }

  /// 자동 로그인 활성화 여부
  Future<bool> isAutoLoginEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoLoginKey) ?? false;
  }

  /// 인증 정보 저장
  Future<void> _saveAuth() async {
    if (_client == null || !_client!.authStore.isValid) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, _client!.authStore.token);
    if (_client!.authStore.record != null) {
      await prefs.setString(_recordKey, _client!.authStore.record!.toString());
    }
    AppLogger.auth('Auth saved to SharedPreferences');
  }

  /// 저장된 인증 정보 삭제
  Future<void> _clearSavedAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_recordKey);
    AppLogger.auth('Saved auth cleared');
  }

  /// 자동 로그인이 활성화되어 있으면 저장된 토큰 복원
  Future<void> _restoreAuthIfEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final autoLoginEnabled = prefs.getBool(_autoLoginKey) ?? false;

    if (!autoLoginEnabled) {
      AppLogger.auth('Auto login disabled, skipping auth restore');
      return;
    }

    final token = prefs.getString(_tokenKey);
    if (token != null && token.isNotEmpty) {
      _client!.authStore.save(token, null);
      AppLogger.auth('Auth token restored from SharedPreferences');

      // 토큰 유효성 확인
      try {
        await _client!.collection('users').authRefresh();
        AppLogger.auth('Auth token is valid');
      } catch (e) {
        AppLogger.auth('Auth token expired or invalid: $e', isError: true);
        _client!.authStore.clear();
        await _clearSavedAuth();
      }
    }
  }

  /// 로그인 성공 후 호출 - 자동 로그인이 활성화되어 있으면 토큰 저장
  Future<void> onLoginSuccess() async {
    final autoLoginEnabled = await isAutoLoginEnabled();
    if (autoLoginEnabled) {
      await _saveAuth();
    }
  }

  /// 로그아웃 시 호출 - 저장된 토큰 삭제
  Future<void> onLogout() async {
    await _clearSavedAuth();
  }

  /// 파일 URL 생성
  String getFileUrl(String collectionId, String recordId, String filename) {
    return client.files
        .getUrl(
          RecordModel({'id': recordId, 'collectionId': collectionId}),
          filename,
        )
        .toString();
  }

  /// Health check
  Future<bool> healthCheck() async {
    try {
      await client.health.check();
      return true;
    } catch (e) {
      AppLogger.network('PocketBase health check failed: $e', isError: true);
      return false;
    }
  }
}
