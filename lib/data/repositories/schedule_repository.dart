import '../../domain/models/schedule_data.dart';
import '../services/schedule_service.dart';

abstract class ScheduleRepository {
  Future<List<ScheduleData>> getDailySchedule(DateTime date);
  Future<void> toggleComplete(String id, bool isCompleted);
}

class MockScheduleRepository implements ScheduleRepository {
  // 인메모리 저장소 (앱 재시작시 초기화)
  final List<ScheduleData> _mockData = [
    ScheduleData(
      id: '1',
      time: '08:00',
      title: '호동이 먹이주기',
      aquariumName: '호동이네',
      isCompleted: true,
      date: DateTime.now(),
    ),
    ScheduleData(
      id: '2',
      time: '14:00',
      title: '러키 수질검사',
      aquariumName: '러키네',
      isCompleted: false,
      date: DateTime.now(),
    ),
    ScheduleData(
      id: '3',
      time: '18:00',
      title: '물갈이',
      aquariumName: '러키네',
      isCompleted: false,
      date: DateTime.now(),
    ),
  ];

  @override
  Future<List<ScheduleData>> getDailySchedule(DateTime date) async {
    // 실제로는 날짜 필터링을 해야 하나, Mock에서는 단순히 모두 반환하거나
    // 오늘 날짜 데이터만 반환하도록 시뮬레이션
    return _mockData;
  }

  @override
  Future<void> toggleComplete(String id, bool isCompleted) async {
    final index = _mockData.indexWhere((item) => item.id == id);
    if (index != -1) {
      _mockData[index] = _mockData[index].copyWith(isCompleted: isCompleted);
    }
  }
}

/// PocketBase 일정 Repository
///
/// 실제 PocketBase 백엔드와 통신
class PocketBaseScheduleRepository implements ScheduleRepository {
  PocketBaseScheduleRepository._();

  static PocketBaseScheduleRepository? _instance;
  static PocketBaseScheduleRepository get instance =>
      _instance ??= PocketBaseScheduleRepository._();

  final ScheduleService _service = ScheduleService.instance;

  @override
  Future<List<ScheduleData>> getDailySchedule(DateTime date) async {
    return _service.getDailySchedule(date);
  }

  @override
  Future<void> toggleComplete(String id, bool isCompleted) async {
    return _service.toggleComplete(id, isCompleted);
  }
}
