import '../../domain/models/schedule_data.dart';
import '../services/schedule_service.dart';

/// 일정 Repository 인터페이스
abstract class ScheduleRepository {
  Future<List<ScheduleData>> getDailySchedule(DateTime date);
  Future<void> toggleComplete(String id, bool isCompleted);
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
