import 'package:flutter/foundation.dart';
import '../../core/utils/app_logger.dart';

/// 모든 ViewModel의 기본 클래스
///
/// 공통 상태 관리 로직을 제공합니다:
/// - 로딩 상태 관리 (isLoading)
/// - 에러 메시지 관리 (errorMessage)
/// - 비동기 작업 실행 헬퍼 (runAsync)
abstract class BaseViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isDisposed = false;
  bool get isDisposed => _isDisposed;

  /// 로딩 상태 설정
  @protected
  void setLoading(bool value) {
    if (_isDisposed) return;
    _isLoading = value;
    notifyListeners();
  }

  /// 에러 메시지 설정
  @protected
  void setError(String? message) {
    if (_isDisposed) return;
    _errorMessage = message;
    notifyListeners();
  }

  /// 에러 메시지 초기화
  void clearError() {
    if (_isDisposed) return;
    _errorMessage = null;
    notifyListeners();
  }

  /// 안전한 notifyListeners 호출
  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  /// 비동기 작업 실행 헬퍼
  ///
  /// 로딩 상태와 에러 처리를 자동으로 관리합니다.
  ///
  /// [action]: 실행할 비동기 작업
  /// [errorPrefix]: 에러 발생 시 표시할 메시지 접두사
  /// [showLoading]: 로딩 상태를 표시할지 여부 (기본값: true)
  /// [rethrowError]: 에러를 다시 throw할지 여부 (기본값: false)
  ///
  /// 반환값: 작업 성공 시 결과값, 실패 시 null
  @protected
  Future<T?> runAsync<T>(
    Future<T> Function() action, {
    String? errorPrefix,
    bool showLoading = true,
    bool rethrowError = false,
  }) async {
    if (showLoading) {
      setLoading(true);
    }
    _errorMessage = null;

    try {
      final result = await action();
      return result;
    } catch (e) {
      final message = errorPrefix != null ? '$errorPrefix: $e' : '$e';
      setError(message);
      AppLogger.error('[${runtimeType.toString()}] Error: $e');

      if (rethrowError) {
        rethrow;
      }
      return null;
    } finally {
      if (showLoading) {
        setLoading(false);
      }
    }
  }

  /// 비동기 작업 실행 (bool 반환)
  ///
  /// 작업 성공 여부를 bool로 반환합니다.
  @protected
  Future<bool> runAsyncBool(
    Future<void> Function() action, {
    String? errorPrefix,
    bool showLoading = true,
  }) async {
    if (showLoading) {
      setLoading(true);
    }
    _errorMessage = null;

    try {
      await action();
      return true;
    } catch (e) {
      final message = errorPrefix ?? '오류가 발생했습니다';
      setError(message);
      AppLogger.error('[${runtimeType.toString()}] Error: $e');
      return false;
    } finally {
      if (showLoading) {
        setLoading(false);
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

/// 캐싱 기능을 제공하는 ViewModel 기본 클래스
///
/// 시간 기반 캐시 유효성 검사를 제공합니다.
abstract class CachingViewModel extends BaseViewModel {
  /// 캐시 유효 시간 (기본값: 5분)
  Duration get cacheValidDuration => const Duration(minutes: 5);

  /// 캐시 타임스탬프 저장소
  final Map<String, DateTime> _cacheTimestamps = {};

  /// 캐시 유효성 확인
  @protected
  bool isCacheValid(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < cacheValidDuration;
  }

  /// 캐시 타임스탬프 업데이트
  @protected
  void updateCacheTimestamp(String key) {
    _cacheTimestamps[key] = DateTime.now();
  }

  /// 특정 캐시 무효화
  @protected
  void invalidateCache(String key) {
    _cacheTimestamps.remove(key);
  }

  /// 모든 캐시 무효화
  @protected
  void invalidateAllCaches() {
    _cacheTimestamps.clear();
  }
}
