/// PocketBase 필터 쿼리 안전 유틸리티
///
/// 필터 문자열에 삽입되는 값을 sanitize하여
/// 필터 injection을 방지합니다.
class PbFilter {
  PbFilter._();

  /// PocketBase ID 형식 검증 (15자 영소문자+숫자)
  static final _idPattern = RegExp(r'^[a-z0-9]{15}$');

  /// PocketBase 필터에 안전하게 삽입할 수 있도록 값을 sanitize합니다.
  ///
  /// 쌍따옴표와 백슬래시를 이스케이프합니다.
  static String sanitize(String value) {
    return value.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
  }

  /// ID 값이 유효한 PocketBase ID 형식인지 검증합니다.
  ///
  /// 유효하지 않으면 빈 문자열을 반환합니다.
  static String sanitizeId(String? id) {
    if (id == null || id.isEmpty) return '';
    if (_idPattern.hasMatch(id)) return id;
    // 비표준 ID (마이그레이션 등)인 경우 sanitize 처리
    return sanitize(id);
  }

  /// 안전한 equals 필터 조건을 생성합니다.
  ///
  /// 예: `PbFilter.eq('owner', userId)` → `owner = "abc123def456789"`
  static String eq(String field, String value) {
    return '$field = "${sanitize(value)}"';
  }

  /// 안전한 날짜 범위 필터 조건을 생성합니다.
  static String dateRange(String field, DateTime start, DateTime end) {
    final startStr = _formatDate(start);
    final endStr = _formatDate(end);
    return '$field >= "$startStr" && $field < "$endStr"';
  }

  /// 안전한 날짜 이하 조건을 생성합니다.
  static String dateLte(String field, DateTime date) {
    return '$field <= "${_formatDate(date)}"';
  }

  /// PocketBase용 날짜 포맷 (YYYY-MM-DD HH:MM:SS)
  static String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}:'
        '${date.second.toString().padLeft(2, '0')}';
  }
}
