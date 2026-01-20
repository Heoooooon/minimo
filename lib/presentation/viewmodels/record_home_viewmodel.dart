import 'package:flutter/foundation.dart';
import '../../data/repositories/record_repository.dart';
import '../../domain/models/record_data.dart';

/// 기록 홈 화면 ViewModel
///
/// 캘린더와 기록 목록 데이터를 관리
class RecordHomeViewModel extends ChangeNotifier {
  final RecordRepository _repository = PocketBaseRecordRepository.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // 현재 월에서 기록이 있는 날짜들
  Set<DateTime> _datesWithRecords = {};
  Set<DateTime> get datesWithRecords => _datesWithRecords;

  // 선택된 날짜의 기록들
  List<RecordData> _selectedDateRecords = [];
  List<RecordData> get selectedDateRecords => _selectedDateRecords;

  /// 캐싱 관련 필드
  DateTime? _lastMonthFetchTime;
  DateTime? _cachedMonth;
  DateTime? _lastDateFetchTime;
  DateTime? _cachedDate;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  /// 월별 캐시가 유효한지 확인
  bool _isMonthCacheValid(DateTime month) {
    return _lastMonthFetchTime != null &&
        _cachedMonth != null &&
        _cachedMonth!.year == month.year &&
        _cachedMonth!.month == month.month &&
        DateTime.now().difference(_lastMonthFetchTime!) < _cacheValidDuration &&
        _datesWithRecords.isNotEmpty;
  }

  /// 날짜별 캐시가 유효한지 확인
  bool _isDateCacheValid(DateTime date) {
    return _lastDateFetchTime != null &&
        _cachedDate != null &&
        _cachedDate!.year == date.year &&
        _cachedDate!.month == date.month &&
        _cachedDate!.day == date.day &&
        DateTime.now().difference(_lastDateFetchTime!) < _cacheValidDuration;
  }

  /// 특정 월의 기록이 있는 날짜 목록 로드
  /// [forceRefresh]가 true이면 캐시를 무시하고 새로 로드
  Future<void> loadRecordDatesInMonth(DateTime month, {bool forceRefresh = false}) async {
    // 캐시가 유효하고 강제 새로고침이 아니면 스킵
    if (!forceRefresh && _isMonthCacheValid(month)) {
      return;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final dates = await _repository.getRecordDatesInMonth(month);
      _datesWithRecords = dates.toSet();
      _lastMonthFetchTime = DateTime.now();
      _cachedMonth = month;
    } catch (e) {
      debugPrint('Error loading record dates: $e');
      _errorMessage = '기록 날짜를 불러오는 중 오류가 발생했습니다.';
      _datesWithRecords = {};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 특정 날짜의 기록 목록 로드
  /// [forceRefresh]가 true이면 캐시를 무시하고 새로 로드
  Future<void> loadRecordsByDate(DateTime date, {bool forceRefresh = false}) async {
    // 캐시가 유효하고 강제 새로고침이 아니면 스킵
    if (!forceRefresh && _isDateCacheValid(date)) {
      return;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _selectedDateRecords = await _repository.getRecordsByDate(date);
      _lastDateFetchTime = DateTime.now();
      _cachedDate = date;
    } catch (e) {
      debugPrint('Error loading records by date: $e');
      _errorMessage = '기록을 불러오는 중 오류가 발생했습니다.';
      _selectedDateRecords = [];
    } finally {
      _isLoading = false;
      notifyListeners();
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
