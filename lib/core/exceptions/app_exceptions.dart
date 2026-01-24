/// Minimo 앱 커스텀 예외 클래스 모음
///
/// 각 예외는 특정 도메인/상황에 맞게 분류되어 있음
library;

/// 앱 예외의 기본 클래스
///
/// 모든 커스텀 예외는 이 클래스를 상속받음
abstract class AppException implements Exception {
  const AppException({required this.message, this.code, this.originalError});

  /// 사용자에게 표시할 수 있는 메시지
  final String message;

  /// 에러 코드 (서버 에러 코드 또는 앱 내부 코드)
  final String? code;

  /// 원본 에러 (디버깅용)
  final Object? originalError;

  @override
  String toString() => 'AppException: $message (code: $code)';
}

// ============================================================================
// 네트워크 관련 예외
// ============================================================================

/// 네트워크 요청 실패 예외
class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.code,
    super.originalError,
    this.statusCode,
  });

  /// HTTP 상태 코드
  final int? statusCode;

  /// 네트워크 연결 없음
  factory NetworkException.noConnection() =>
      const NetworkException(message: '인터넷 연결을 확인해주세요.', code: 'NO_CONNECTION');

  /// 요청 타임아웃
  factory NetworkException.timeout() => const NetworkException(
    message: '요청 시간이 초과되었습니다. 다시 시도해주세요.',
    code: 'TIMEOUT',
  );

  /// 서버 에러 (5xx)
  factory NetworkException.serverError({
    int? statusCode,
    Object? originalError,
  }) => NetworkException(
    message: '서버에 문제가 발생했습니다. 잠시 후 다시 시도해주세요.',
    code: 'SERVER_ERROR',
    statusCode: statusCode,
    originalError: originalError,
  );

  /// 클라이언트 에러 (4xx)
  factory NetworkException.clientError({
    required String message,
    int? statusCode,
    Object? originalError,
  }) => NetworkException(
    message: message,
    code: 'CLIENT_ERROR',
    statusCode: statusCode,
    originalError: originalError,
  );

  @override
  String toString() =>
      'NetworkException: $message (code: $code, statusCode: $statusCode)';
}

// ============================================================================
// 인증 관련 예외
// ============================================================================

/// 인증 관련 예외
class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.code,
    super.originalError,
  });

  /// 잘못된 자격 증명 (이메일/비밀번호 오류)
  factory AuthException.invalidCredentials() => const AuthException(
    message: '이메일 또는 비밀번호가 올바르지 않습니다.',
    code: 'INVALID_CREDENTIALS',
  );

  /// 이메일 중복
  factory AuthException.emailAlreadyExists() =>
      const AuthException(message: '이미 사용 중인 이메일입니다.', code: 'EMAIL_EXISTS');

  /// 이메일 미인증
  factory AuthException.emailNotVerified() => const AuthException(
    message: '이메일 인증이 필요합니다.',
    code: 'EMAIL_NOT_VERIFIED',
  );

  /// 토큰 만료
  factory AuthException.tokenExpired() => const AuthException(
    message: '로그인이 만료되었습니다. 다시 로그인해주세요.',
    code: 'TOKEN_EXPIRED',
  );

  /// 권한 없음
  factory AuthException.unauthorized() =>
      const AuthException(message: '접근 권한이 없습니다.', code: 'UNAUTHORIZED');

  /// 비밀번호 불일치
  factory AuthException.passwordMismatch() => const AuthException(
    message: '비밀번호가 일치하지 않습니다.',
    code: 'PASSWORD_MISMATCH',
  );

  /// 약한 비밀번호
  factory AuthException.weakPassword() => const AuthException(
    message: '비밀번호는 8자 이상이어야 합니다.',
    code: 'WEAK_PASSWORD',
  );
}

// ============================================================================
// 유효성 검사 예외
// ============================================================================

/// 입력 유효성 검사 실패 예외
class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.code,
    this.field,
    this.validationErrors,
  });

  /// 유효성 검사 실패한 필드 이름
  final String? field;

  /// 필드별 에러 목록 (여러 필드 동시 검증 시)
  final Map<String, String>? validationErrors;

  /// 필수 필드 누락
  factory ValidationException.required(String fieldName) => ValidationException(
    message: '$fieldName을(를) 입력해주세요.',
    code: 'REQUIRED',
    field: fieldName,
  );

  /// 잘못된 형식
  factory ValidationException.invalidFormat(String fieldName) =>
      ValidationException(
        message: '$fieldName 형식이 올바르지 않습니다.',
        code: 'INVALID_FORMAT',
        field: fieldName,
      );

  /// 잘못된 이메일 형식
  factory ValidationException.invalidEmail() => const ValidationException(
    message: '올바른 이메일 주소를 입력해주세요.',
    code: 'INVALID_EMAIL',
    field: 'email',
  );

  /// 길이 초과
  factory ValidationException.tooLong(String fieldName, int maxLength) =>
      ValidationException(
        message: '$fieldName은(는) $maxLength자 이하로 입력해주세요.',
        code: 'TOO_LONG',
        field: fieldName,
      );

  /// 길이 부족
  factory ValidationException.tooShort(String fieldName, int minLength) =>
      ValidationException(
        message: '$fieldName은(는) $minLength자 이상 입력해주세요.',
        code: 'TOO_SHORT',
        field: fieldName,
      );

  @override
  String toString() => 'ValidationException: $message (field: $field)';
}

// ============================================================================
// 데이터/리소스 관련 예외
// ============================================================================

/// 데이터를 찾을 수 없는 경우
class NotFoundException extends AppException {
  const NotFoundException({
    required super.message,
    super.code,
    this.resourceType,
    this.resourceId,
  });

  /// 리소스 타입 (예: 'aquarium', 'user', 'record')
  final String? resourceType;

  /// 리소스 ID
  final String? resourceId;

  factory NotFoundException.aquarium(String? id) => NotFoundException(
    message: '어항을 찾을 수 없습니다.',
    code: 'AQUARIUM_NOT_FOUND',
    resourceType: 'aquarium',
    resourceId: id,
  );

  factory NotFoundException.user(String? id) => NotFoundException(
    message: '사용자를 찾을 수 없습니다.',
    code: 'USER_NOT_FOUND',
    resourceType: 'user',
    resourceId: id,
  );

  factory NotFoundException.record(String? id) => NotFoundException(
    message: '기록을 찾을 수 없습니다.',
    code: 'RECORD_NOT_FOUND',
    resourceType: 'record',
    resourceId: id,
  );

  factory NotFoundException.schedule(String? id) => NotFoundException(
    message: '일정을 찾을 수 없습니다.',
    code: 'SCHEDULE_NOT_FOUND',
    resourceType: 'schedule',
    resourceId: id,
  );

  @override
  String toString() =>
      'NotFoundException: $message (type: $resourceType, id: $resourceId)';
}

// ============================================================================
// 캐시 관련 예외
// ============================================================================

/// 캐시 관련 예외
class CacheException extends AppException {
  const CacheException({
    required super.message,
    super.code,
    super.originalError,
  });

  /// 캐시 읽기 실패
  factory CacheException.readFailed() => const CacheException(
    message: '데이터를 불러오는데 실패했습니다.',
    code: 'CACHE_READ_FAILED',
  );

  /// 캐시 쓰기 실패
  factory CacheException.writeFailed() => const CacheException(
    message: '데이터를 저장하는데 실패했습니다.',
    code: 'CACHE_WRITE_FAILED',
  );

  /// 캐시 만료
  factory CacheException.expired() =>
      const CacheException(message: '캐시된 데이터가 만료되었습니다.', code: 'CACHE_EXPIRED');
}

// ============================================================================
// 비즈니스 로직 예외
// ============================================================================

/// 비즈니스 로직 위반 예외
class BusinessException extends AppException {
  const BusinessException({
    required super.message,
    super.code,
    super.originalError,
  });

  /// 어항 최대 개수 초과
  factory BusinessException.aquariumLimitExceeded(int maxCount) =>
      BusinessException(
        message: '어항은 최대 $maxCount개까지 등록할 수 있습니다.',
        code: 'AQUARIUM_LIMIT_EXCEEDED',
      );

  /// 이미 완료된 작업
  factory BusinessException.alreadyCompleted() => const BusinessException(
    message: '이미 완료된 작업입니다.',
    code: 'ALREADY_COMPLETED',
  );

  /// 자신에게 수행할 수 없는 작업
  factory BusinessException.cannotActOnSelf() => const BusinessException(
    message: '자신에게는 이 작업을 수행할 수 없습니다.',
    code: 'CANNOT_ACT_ON_SELF',
  );
}
