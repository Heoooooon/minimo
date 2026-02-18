/// 앱 설정 클래스
///
/// 환경변수 또는 기본값으로부터 설정을 로드합니다.
/// 빌드 시 --dart-define 플래그를 사용하여 값을 오버라이드할 수 있습니다.
///
/// 사용 예시:
/// ```bash
/// flutter run --dart-define=POCKETBASE_URL=https://my-server.com
/// flutter build apk --dart-define=POCKETBASE_URL=https://production.com
/// ```
class AppConfig {
  AppConfig._();

  /// PocketBase 서버 URL
  ///
  /// 환경변수 POCKETBASE_URL로 오버라이드 가능
  /// 기본값: https://minimo-pocketbase.fly.dev
  static const String pocketbaseUrl = String.fromEnvironment(
    'POCKETBASE_URL',
    defaultValue: 'https://minimo-pocketbase.fly.dev',
  );

  /// 앱 환경 (development, staging, production)
  ///
  /// 환경변수 APP_ENV로 오버라이드 가능
  /// 기본값: development
  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  /// 디버그 모드 여부
  static bool get isDebug => appEnv == 'development';

  /// 스테이징 환경 여부
  static bool get isStaging => appEnv == 'staging';

  /// 프로덕션 환경 여부
  static bool get isProduction => appEnv == 'production';

  /// 캐시 유효 기간 (분)
  ///
  /// 환경변수 CACHE_DURATION_MINUTES로 오버라이드 가능
  /// 기본값: 5분
  static const int cacheDurationMinutes = int.fromEnvironment(
    'CACHE_DURATION_MINUTES',
    defaultValue: 5,
  );

  /// API 요청 타임아웃 (초)
  ///
  /// 환경변수 API_TIMEOUT_SECONDS로 오버라이드 가능
  /// 기본값: 30초
  static const int apiTimeoutSeconds = int.fromEnvironment(
    'API_TIMEOUT_SECONDS',
    defaultValue: 30,
  );

  /// 갤러리 다중 업로드/삭제 동시 처리 개수
  ///
  /// 환경변수 GALLERY_BATCH_CONCURRENCY로 오버라이드 가능
  /// 기본값: 3
  static const int galleryBatchConcurrency = int.fromEnvironment(
    'GALLERY_BATCH_CONCURRENCY',
    defaultValue: 3,
  );

  /// 알림 전체 삭제 배치 동시 처리 개수
  ///
  /// 환경변수 NOTIFICATION_DELETE_CONCURRENCY로 오버라이드 가능
  /// 기본값: 10
  static const int notificationDeleteConcurrency = int.fromEnvironment(
    'NOTIFICATION_DELETE_CONCURRENCY',
    defaultValue: 10,
  );

  /// 커뮤니티 탭 캐시 TTL(초)
  ///
  /// 환경변수 COMMUNITY_TAB_CACHE_TTL_SECONDS로 오버라이드 가능
  /// 기본값: 60초
  static const int communityTabCacheTtlSeconds = int.fromEnvironment(
    'COMMUNITY_TAB_CACHE_TTL_SECONDS',
    defaultValue: 60,
  );

  /// 커뮤니티 추천 탭 캐시 TTL(초)
  ///
  /// 환경변수 COMMUNITY_RECOMMEND_TAB_CACHE_TTL_SECONDS로 오버라이드 가능
  /// 기본값: communityTabCacheTtlSeconds
  static const int communityRecommendTabCacheTtlSeconds = int.fromEnvironment(
    'COMMUNITY_RECOMMEND_TAB_CACHE_TTL_SECONDS',
    defaultValue: communityTabCacheTtlSeconds,
  );

  /// 커뮤니티 팔로잉 탭 캐시 TTL(초)
  ///
  /// 환경변수 COMMUNITY_FOLLOWING_TAB_CACHE_TTL_SECONDS로 오버라이드 가능
  /// 기본값: communityTabCacheTtlSeconds
  static const int communityFollowingTabCacheTtlSeconds = int.fromEnvironment(
    'COMMUNITY_FOLLOWING_TAB_CACHE_TTL_SECONDS',
    defaultValue: communityTabCacheTtlSeconds,
  );

  /// 커뮤니티 Q&A 탭 캐시 TTL(초)
  ///
  /// 환경변수 COMMUNITY_QNA_TAB_CACHE_TTL_SECONDS로 오버라이드 가능
  /// 기본값: communityTabCacheTtlSeconds
  static const int communityQnaTabCacheTtlSeconds = int.fromEnvironment(
    'COMMUNITY_QNA_TAB_CACHE_TTL_SECONDS',
    defaultValue: communityTabCacheTtlSeconds,
  );

  /// 앱 버전 (빌드 시 주입)
  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0',
  );

  /// 설정 정보 출력 (디버그용)
  static void printConfig() {
    if (isDebug) {
      _debugLog('=== App Config ===');
      _debugLog('PocketBase URL: $pocketbaseUrl');
      _debugLog('Environment: $appEnv');
      _debugLog('Cache Duration: ${cacheDurationMinutes}m');
      _debugLog('API Timeout: ${apiTimeoutSeconds}s');
      _debugLog('Gallery Batch Concurrency: $galleryBatchConcurrency');
      _debugLog(
        'Notification Delete Concurrency: $notificationDeleteConcurrency',
      );
      _debugLog('Community Tab Cache TTL: ${communityTabCacheTtlSeconds}s');
      _debugLog(
        'Community Recommend Tab Cache TTL: ${communityRecommendTabCacheTtlSeconds}s',
      );
      _debugLog(
        'Community Following Tab Cache TTL: ${communityFollowingTabCacheTtlSeconds}s',
      );
      _debugLog(
        'Community QnA Tab Cache TTL: ${communityQnaTabCacheTtlSeconds}s',
      );
      _debugLog('App Version: $appVersion');
      _debugLog('==================');
    }
  }

  static void _debugLog(String message) {
    assert(() {
      // ignore: avoid_print
      // 프로덕션 빌드에서는 assert가 제거되어 실행되지 않음
      print(message); // ignore: avoid_print
      return true;
    }());
  }
}
