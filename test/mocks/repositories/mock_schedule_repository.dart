import 'package:flutter/foundation.dart';
import 'package:oomool/data/repositories/schedule_repository.dart';
import 'package:oomool/domain/models/schedule_data.dart';

/// Mock 일정 Repository
///
/// 백엔드 없이 로컬 메모리에서 동작
/// 테스트 및 개발 목적으로 사용
class MockScheduleRepository implements ScheduleRepository {
  MockScheduleRepository._();

  static MockScheduleRepository? _instance;
  static MockScheduleRepository get instance =>
      _instance ??= MockScheduleRepository._();

  // 인메모리 저장소 (앱 재시작시 초기화)
  final List<ScheduleData> _mockData = [];
  bool _initialized = false;

  void _ensureInitialized() {
    if (!_initialized) {
      addSampleData();
      _initialized = true;
    }
  }

  @override
  Future<List<ScheduleData>> getDailySchedule(DateTime date) async {
    _ensureInitialized();
    await Future.delayed(const Duration(milliseconds: 200));

    // 실제로는 날짜 필터링을 해야 하나, Mock에서는 오늘 날짜만 반환
    return _mockData.where((item) {
      return item.date.year == date.year &&
          item.date.month == date.month &&
          item.date.day == date.day;
    }).toList();
  }

  @override
  Future<void> toggleComplete(String id, bool isCompleted) async {
    _ensureInitialized();
    await Future.delayed(const Duration(milliseconds: 100));

    final index = _mockData.indexWhere((item) => item.id == id);
    if (index != -1) {
      _mockData[index] = _mockData[index].copyWith(isCompleted: isCompleted);
      debugPrint(
        '[MockScheduleRepository] Toggled complete: $id -> $isCompleted',
      );
    }
  }

  /// 테스트용: 샘플 데이터 추가
  void addSampleData() {
    if (_mockData.isNotEmpty) return;

    final today = DateTime.now();
    _mockData.addAll([
      ScheduleData(
        id: '1',
        time: '08:00',
        title: '호동이 먹이주기',
        aquariumName: '호동이네',
        isCompleted: true,
        date: today,
      ),
      ScheduleData(
        id: '2',
        time: '14:00',
        title: '러키 수질검사',
        aquariumName: '러키네',
        isCompleted: false,
        date: today,
      ),
      ScheduleData(
        id: '3',
        time: '18:00',
        title: '물갈이',
        aquariumName: '러키네',
        isCompleted: false,
        date: today,
      ),
    ]);
  }

  /// 테스트용: 데이터 초기화
  void clearAll() {
    _mockData.clear();
    _initialized = false;
  }

  /// 테스트용: 인스턴스 리셋
  @visibleForTesting
  static void resetInstance() {
    _instance = null;
  }
}
