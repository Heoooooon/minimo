import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';

/// PocketBase 서비스
///
/// PocketBase 클라이언트 초기화 및 공통 기능 제공
class PocketBaseService {
  PocketBaseService._();

  static PocketBaseService? _instance;
  static PocketBaseService get instance => _instance ??= PocketBaseService._();

  PocketBase? _client;

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

  /// PocketBase 서버 URL (환경에 따라 변경)
  static String get serverUrl {
    // 개발 환경: 로컬 서버
    if (kDebugMode) {
      // Web에서는 localhost, 모바일에서는 실제 IP 필요
      if (kIsWeb) {
        return 'http://127.0.0.1:8090';
      }
      // iOS 시뮬레이터/Android 에뮬레이터
      return 'http://10.0.2.2:8090'; // Android 에뮬레이터
      // return 'http://localhost:8090'; // iOS 시뮬레이터
    }
    // 프로덕션: 실제 서버 URL
    return 'https://your-pocketbase-server.com';
  }

  /// PocketBase 초기화
  Future<void> initialize({String? customUrl}) async {
    final url = customUrl ?? serverUrl;
    _client = PocketBase(url);
    debugPrint('PocketBase initialized with URL: $url');
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
      debugPrint('PocketBase health check failed: $e');
      return false;
    }
  }
}
