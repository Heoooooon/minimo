import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'pocketbase_service.dart';
import '../../domain/models/schedule_data.dart';

/// 일정 관리 서비스
///
/// PocketBase schedules 컬렉션과 통신
class ScheduleService {
  ScheduleService._();

  static ScheduleService? _instance;
  static ScheduleService get instance => _instance ??= ScheduleService._();

  PocketBase get _pb => PocketBaseService.instance.client;

  static const String _collection = 'schedules';

  /// 특정 날짜의 일정 조회
  Future<List<ScheduleData>> getDailySchedule(DateTime date) async {
    try {
      // 날짜 범위로 필터링 (해당 날짜의 시작~끝)
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final result = await _pb.collection(_collection).getList(
        filter: 'date >= "${startOfDay.toIso8601String()}" && date < "${endOfDay.toIso8601String()}"',
        sort: 'time',
      );

      return result.items.map((record) => _recordToScheduleData(record)).toList();
    } catch (e) {
      debugPrint('Failed to get daily schedule: $e');
      rethrow;
    }
  }

  /// 모든 일정 조회
  Future<List<ScheduleData>> getAllSchedules({
    int page = 1,
    int perPage = 50,
    String? filter,
    String sort = '-date,time',
  }) async {
    try {
      final result = await _pb.collection(_collection).getList(
        page: page,
        perPage: perPage,
        filter: filter,
        sort: sort,
      );

      return result.items.map((record) => _recordToScheduleData(record)).toList();
    } catch (e) {
      debugPrint('Failed to get schedules: $e');
      rethrow;
    }
  }

  /// 특정 어항의 일정 조회
  Future<List<ScheduleData>> getSchedulesByAquarium(
    String aquariumId, {
    int page = 1,
    int perPage = 50,
  }) async {
    return getAllSchedules(
      page: page,
      perPage: perPage,
      filter: 'aquarium = "$aquariumId"',
    );
  }

  /// 일정 생성
  Future<ScheduleData> createSchedule(ScheduleData data) async {
    try {
      final body = {
        'aquarium': data.aquariumId,
        'date': data.date.toIso8601String(),
        'time': data.time,
        'title': data.title,
        'aquarium_name': data.aquariumName,
        'is_completed': data.isCompleted,
        'alarm_type': data.alarmType.value,
        'repeat_cycle': data.repeatCycle.value,
        'is_notification_enabled': data.isNotificationEnabled,
      };

      final record = await _pb.collection(_collection).create(body: body);

      debugPrint('Schedule created: ${record.id}');
      return _recordToScheduleData(record);
    } catch (e) {
      debugPrint('Failed to create schedule: $e');
      rethrow;
    }
  }

  /// 일정 수정
  Future<ScheduleData> updateSchedule(String id, ScheduleData data) async {
    try {
      final body = {
        'aquarium': data.aquariumId,
        'date': data.date.toIso8601String(),
        'time': data.time,
        'title': data.title,
        'aquarium_name': data.aquariumName,
        'is_completed': data.isCompleted,
        'alarm_type': data.alarmType.value,
        'repeat_cycle': data.repeatCycle.value,
        'is_notification_enabled': data.isNotificationEnabled,
      };

      final record = await _pb.collection(_collection).update(id, body: body);

      debugPrint('Schedule updated: ${record.id}');
      return _recordToScheduleData(record);
    } catch (e) {
      debugPrint('Failed to update schedule: $e');
      rethrow;
    }
  }

  /// 완료 상태 토글
  Future<void> toggleComplete(String id, bool isCompleted) async {
    try {
      await _pb.collection(_collection).update(id, body: {
        'is_completed': isCompleted,
      });

      debugPrint('Schedule $id completion toggled to: $isCompleted');
    } catch (e) {
      debugPrint('Failed to toggle schedule completion: $e');
      rethrow;
    }
  }

  /// 일정 삭제
  Future<void> deleteSchedule(String id) async {
    try {
      await _pb.collection(_collection).delete(id);
      debugPrint('Schedule deleted: $id');
    } catch (e) {
      debugPrint('Failed to delete schedule: $e');
      rethrow;
    }
  }

  /// RecordModel을 ScheduleData로 변환
  ScheduleData _recordToScheduleData(RecordModel record) {
    return ScheduleData(
      id: record.id,
      aquariumId: record.getStringValue('aquarium'),
      date: DateTime.tryParse(record.getStringValue('date')) ?? DateTime.now(),
      time: record.getStringValue('time'),
      title: record.getStringValue('title'),
      aquariumName: record.getStringValue('aquarium_name'),
      isCompleted: record.getBoolValue('is_completed'),
      alarmType: AlarmType.fromValue(record.getStringValue('alarm_type')),
      repeatCycle: RepeatCycle.fromValue(record.getStringValue('repeat_cycle')),
      isNotificationEnabled: record.getBoolValue('is_notification_enabled'),
    );
  }
}
