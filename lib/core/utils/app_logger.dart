import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// 앱 전역 로거
///
/// debugPrint 대신 사용하여 구조화된 로깅 제공
/// - 개발 환경: 컬러 출력, 상세 정보
/// - 프로덕션: 간소화된 출력, 에러만 표시
class AppLogger {
  AppLogger._();

  static final Map<String, _PerfMetricAccumulator> _perfMetrics = {};

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

  /// 성능 측정 로그
  ///
  /// 예시: `[PERF] Community.loadRecommendTab: 123ms | posts=10, tags=5`
  static void perf(
    String metricName,
    Duration elapsed, {
    Map<String, Object?>? fields,
    bool isError = false,
  }) {
    final buffer = StringBuffer(
      '[PERF] $metricName: ${elapsed.inMilliseconds}ms',
    );
    if (fields != null && fields.isNotEmpty) {
      final serialized = fields.entries
          .map((entry) => '${entry.key}=${entry.value}')
          .join(', ');
      buffer.write(' | $serialized');
    }

    final message = buffer.toString();
    if (isError) {
      warning(message);
    } else {
      debug(message);
    }

    _recordPerfMetric(metricName, elapsed, fields: fields, isError: isError);
  }

  /// 현재까지 누적된 성능 메트릭 스냅샷
  static Map<String, PerfMetricSummary> getPerfMetricSnapshot() {
    final result = <String, PerfMetricSummary>{};
    for (final entry in _perfMetrics.entries) {
      result[entry.key] = entry.value.toSummary(entry.key);
    }
    return result;
  }

  /// 누적된 성능 메트릭을 문자열로 내보냅니다.
  ///
  /// 로그 업로드, 디버그 화면, QA 리포트에 그대로 사용할 수 있는 형식입니다.
  static String exportPerfMetrics({
    bool clearAfterExport = false,
    int minSamples = 1,
  }) {
    final summaries =
        getPerfMetricSnapshot().values
            .where((summary) => summary.count >= minSamples)
            .toList()
          ..sort((a, b) => b.avgMs.compareTo(a.avgMs));

    if (summaries.isEmpty) {
      return '[PERF] no metrics collected';
    }

    final lines = <String>[
      '[PERF] summary (metrics=${summaries.length}, minSamples=$minSamples)',
    ];

    for (final summary in summaries) {
      final extraFields = summary.lastFields.entries
          .map((entry) => '${entry.key}=${entry.value}')
          .join(', ');
      lines.add(
        '- ${summary.metricName}: '
        'count=${summary.count}, '
        'avg=${summary.avgMs.toStringAsFixed(1)}ms, '
        'min=${summary.minMs}ms, '
        'max=${summary.maxMs}ms, '
        'errors=${summary.errorCount}'
        '${extraFields.isNotEmpty ? ', last={$extraFields}' : ''}',
      );
    }

    if (clearAfterExport) {
      clearPerfMetrics();
    }
    return lines.join('\n');
  }

  /// 누적된 성능 메트릭 초기화
  static void clearPerfMetrics() {
    _perfMetrics.clear();
  }

  static void _recordPerfMetric(
    String metricName,
    Duration elapsed, {
    Map<String, Object?>? fields,
    required bool isError,
  }) {
    final accumulator = _perfMetrics.putIfAbsent(
      metricName,
      () => _PerfMetricAccumulator(),
    );
    accumulator.record(
      elapsed.inMilliseconds,
      isError: isError,
      fields: fields,
    );
  }
}

class PerfMetricSummary {
  const PerfMetricSummary({
    required this.metricName,
    required this.count,
    required this.errorCount,
    required this.minMs,
    required this.maxMs,
    required this.avgMs,
    required this.lastFields,
  });

  final String metricName;
  final int count;
  final int errorCount;
  final int minMs;
  final int maxMs;
  final double avgMs;
  final Map<String, Object?> lastFields;
}

class _PerfMetricAccumulator {
  int count = 0;
  int errorCount = 0;
  int totalMs = 0;
  int minMs = 0;
  int maxMs = 0;
  Map<String, Object?> lastFields = const {};

  void record(
    int elapsedMs, {
    required bool isError,
    Map<String, Object?>? fields,
  }) {
    count += 1;
    totalMs += elapsedMs;
    if (count == 1) {
      minMs = elapsedMs;
      maxMs = elapsedMs;
    } else {
      if (elapsedMs < minMs) minMs = elapsedMs;
      if (elapsedMs > maxMs) maxMs = elapsedMs;
    }
    if (isError) {
      errorCount += 1;
    }
    if (fields != null && fields.isNotEmpty) {
      lastFields = Map<String, Object?>.from(fields);
    }
  }

  PerfMetricSummary toSummary(String metricName) {
    return PerfMetricSummary(
      metricName: metricName,
      count: count,
      errorCount: errorCount,
      minMs: minMs,
      maxMs: maxMs,
      avgMs: count == 0 ? 0 : totalMs / count,
      lastFields: lastFields,
    );
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
