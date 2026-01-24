import '../../data/repositories/record_repository.dart';
import '../../domain/models/record_data.dart';
import 'base_viewmodel.dart';

/// 기록 홈 화면 ViewModel
///
/// 캘린더와 기록 목록 데이터를 관리
class RecordHomeViewModel extends CachingViewModel {
  final RecordRepository _repository = PocketBaseRecordRepository.instance;

  // 현재 월에서 기록이 있는 날짜들
  Set<DateTime> _datesWithRecords = {};
  Set<DateTime> get datesWithRecords => _datesWithRecords;

  // 선택된 날짜의 기록들
  List<RecordData> _selectedDateRecords = [];
  List<RecordData> get selectedDateRecords => _selectedDateRecords;

  // 캐시 키 생성
  String _monthCacheKey(DateTime month) => 'month_${month.year}_${month.month}';
  String _dateCacheKey(DateTime date) =>
      'date_${date.year}_${date.month}_${date.day}';

  /// 특정 월의 기록이 있는 날짜 목록 로드
  /// [forceRefresh]가 true이면 캐시를 무시하고 새로 로드
  Future<void> loadRecordDatesInMonth(
    DateTime month, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = _monthCacheKey(month);

    // 캐시가 유효하고 강제 새로고침이 아니면 스킵
    if (!forceRefresh &&
        isCacheValid(cacheKey) &&
        _datesWithRecords.isNotEmpty) {
      return;
    }

    await runAsync(() async {
      final dates = await _repository.getRecordDatesInMonth(month);
      _datesWithRecords = dates.toSet();
      updateCacheTimestamp(cacheKey);
      return _datesWithRecords;
    }, errorPrefix: '기록 날짜를 불러오는 중 오류가 발생했습니다');

    if (errorMessage != null) {
      _datesWithRecords = {};
    }
  }

  /// 특정 날짜의 기록 목록 로드
  /// [forceRefresh]가 true이면 캐시를 무시하고 새로 로드
  Future<void> loadRecordsByDate(
    DateTime date, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = _dateCacheKey(date);

    // 캐시가 유효하고 강제 새로고침이 아니면 스킵
    if (!forceRefresh && isCacheValid(cacheKey)) {
      return;
    }

    await runAsync(() async {
      _selectedDateRecords = await _repository.getRecordsByDate(date);
      updateCacheTimestamp(cacheKey);
      return _selectedDateRecords;
    }, errorPrefix: '기록을 불러오는 중 오류가 발생했습니다');

    if (errorMessage != null) {
      _selectedDateRecords = [];
    }
  }

  /// 데이터 새로고침 (강제 새로고침)
  Future<void> refresh(DateTime month, DateTime selectedDate) async {
    await loadRecordDatesInMonth(month, forceRefresh: true);
    await loadRecordsByDate(selectedDate, forceRefresh: true);
  }

  /// 날짜에 기록이 있는지 확인
  bool hasRecordOnDate(DateTime date) {
    return _datesWithRecords.any(
      (d) => d.year == date.year && d.month == date.month && d.day == date.day,
    );
  }
}
