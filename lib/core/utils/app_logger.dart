import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// 앱 전역 로거
///
/// debugPrint 대신 사용하여 구조화된 로깅 제공
/// - 개발 환경: 컬러 출력, 상세 정보
/// - 프로덕션: 간소화된 출력, 에러만 표시
class AppLogger {
  AppLogger._();

  static final Logger _logger = Logger(
    printer: kDebugMode
        ? PrettyPrinter(
            methodCount: 0,
            errorMethodCount: 5,
            lineLength: 80,
            colors: true,
            printEmojis: true,
            dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
          )
        : SimplePrinter(colors: false),
    level: kDebugMode ? Level.trace : Level.warning,
    filter: ProductionFilter(),
  );

  /// Trace 레벨 로그 (가장 상세한 디버깅용)
  static void trace(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.t(message, error: error, stackTrace: stackTrace);
  }

  /// Debug 레벨 로그 (개발 중 디버깅용)
  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Info 레벨 로그 (일반적인 정보)
  static void info(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Warning 레벨 로그 (주의가 필요한 상황)
  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Error 레벨 로그 (에러 발생)
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Fatal 레벨 로그 (치명적인 에러)
  static void fatal(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  // ============================================================================
  // 도메인별 편의 메서드
  // ============================================================================

  /// 인증 관련 로그
  static void auth(String message, {bool isError = false}) {
    final prefixed = '[AUTH] $message';
    isError ? error(prefixed) : info(prefixed);
  }

  /// 네트워크 요청 로그
  static void network(String message, {bool isError = false}) {
    final prefixed = '[NETWORK] $message';
    isError ? error(prefixed) : debug(prefixed);
  }

  /// 데이터베이스/캐시 로그
  static void data(String message, {bool isError = false}) {
    final prefixed = '[DATA] $message';
    isError ? error(prefixed) : debug(prefixed);
  }

  /// UI/화면 관련 로그
  static void ui(String message) {
    trace('[UI] $message');
  }

  /// 비즈니스 로직 로그
  static void business(String message, {bool isError = false}) {
    final prefixed = '[BUSINESS] $message';
    isError ? error(prefixed) : info(prefixed);
  }
}

/// 프로덕션 환경 필터
///
/// 릴리즈 빌드에서는 warning 이상만 출력
class ProductionFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    if (kDebugMode) {
      return true; // 디버그 모드에서는 모든 로그 출력
    }
    // 릴리즈 모드에서는 warning 이상만 출력
    return event.level.index >= Level.warning.index;
  }
}
