import 'package:flutter/foundation.dart';
import 'package:oomool/data/repositories/record_repository.dart';
import 'package:oomool/domain/models/record_data.dart';

/// Mock 기록 Repository
///
/// 백엔드 없이 로컬 메모리에서 동작
/// 테스트 및 개발 목적으로 사용
class MockRecordRepository implements RecordRepository {
  MockRecordRepository._();

  static MockRecordRepository? _instance;
  static MockRecordRepository get instance =>
      _instance ??= MockRecordRepository._();

  // 인메모리 저장소
  final List<RecordData> _records = [];
  int _idCounter = 1;

  @override
  Future<List<RecordData>> getRecords({
    int page = 1,
    int perPage = 20,
    String? filter,
    String sort = '-date',
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // 정렬 (최신순)
    final sorted = List<RecordData>.from(_records);
    if (sort.startsWith('-')) {
      sorted.sort((a, b) => b.date.compareTo(a.date));
    } else {
      sorted.sort((a, b) => a.date.compareTo(b.date));
    }

    // 페이지네이션
    final start = (page - 1) * perPage;
    final end = start + perPage;
    if (start >= sorted.length) return [];

    return sorted.sublist(start, end.clamp(0, sorted.length));
  }

  @override
  Future<RecordData> createRecord(RecordData data) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final newRecord = RecordData(
      id: 'record_${_idCounter++}',
      aquariumId: data.aquariumId,
      creatureId: data.creatureId,
      date: data.date,
      tags: data.tags,
      content: data.content,
      isPublic: data.isPublic,
      recordType: data.recordType,
      isCompleted: data.isCompleted,
      created: DateTime.now(),
      updated: DateTime.now(),
    );
    _records.add(newRecord);

    debugPrint('[MockRecordRepository] Created record: ${newRecord.id}');
    return newRecord;
  }

  @override
  Future<void> deleteRecord(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _records.indexWhere((r) => r.id == id);
    if (index != -1) {
      _records.removeAt(index);
      debugPrint('[MockRecordRepository] Deleted: $id');
    }
  }

  @override
  Future<List<RecordData>> getRecordsByDate(DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 200));

    return _records.where((r) {
      return r.date.year == date.year &&
          r.date.month == date.month &&
          r.date.day == date.day;
    }).toList();
  }

  @override
  Future<List<RecordData>> getRecordsByDateAndAquarium(
    DateTime date,
    String? aquariumId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));

    return _records.where((r) {
      final sameDay = r.date.year == date.year &&
          r.date.month == date.month &&
          r.date.day == date.day;
      if (aquariumId != null && aquariumId.isNotEmpty) {
        return sameDay && r.aquariumId == aquariumId;
      }
      return sameDay;
    }).toList();
  }

  @override
  Future<List<RecordData>> getRecordsByDateAquariumAndCreature(
    DateTime date,
    String? aquariumId, {
    String? creatureId,
    String? recordType,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));

    return _records.where((r) {
      final sameDay = r.date.year == date.year &&
          r.date.month == date.month &&
          r.date.day == date.day;
      if (!sameDay) return false;
      if (aquariumId != null && aquariumId.isNotEmpty && r.aquariumId != aquariumId) {
        return false;
      }
      if (creatureId != null && creatureId.isNotEmpty && r.creatureId != creatureId) {
        return false;
      }
      if (recordType != null && recordType.isNotEmpty && r.recordType.value != recordType) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<RecordData> updateRecord(String id, RecordData data) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _records.indexWhere((r) => r.id == id);
    if (index != -1) {
      final updated = data.copyWith(id: id, updated: DateTime.now());
      _records[index] = updated;
      debugPrint('[MockRecordRepository] Updated record: $id');
      return updated;
    }
    throw Exception('Record not found: $id');
  }

  @override
  Future<void> updateRecordCompletion(String id, bool isCompleted) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final index = _records.indexWhere((r) => r.id == id);
    if (index != -1) {
      _records[index].isCompleted = isCompleted;
    }
  }

  @override
  Future<List<DateTime>> getRecordDatesInMonth(DateTime month) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final dates = <DateTime>{};
    for (final record in _records) {
      if (record.date.year == month.year && record.date.month == month.month) {
        dates.add(
          DateTime(record.date.year, record.date.month, record.date.day),
        );
      }
    }
    return dates.toList()..sort();
  }

  /// 테스트용: 샘플 데이터 추가
  void addSampleData() {
    if (_records.isNotEmpty) return;

    final now = DateTime.now();
    _records.addAll([
      RecordData(
        id: 'record_${_idCounter++}',
        aquariumId: 'aquarium_1',
        date: now.subtract(const Duration(days: 1)),
        tags: [RecordTag.waterChange, RecordTag.cleaning],
        content: '주간 물갈이 30% 진행. 유리면 이끼 제거함.',
        isPublic: true,
        created: now.subtract(const Duration(days: 1)),
      ),
      RecordData(
        id: 'record_${_idCounter++}',
        aquariumId: 'aquarium_1',
        date: now.subtract(const Duration(days: 3)),
        tags: [RecordTag.feeding],
        content: '냉동 장구벌레 급여. 구피들 반응 좋음.',
        isPublic: true,
        created: now.subtract(const Duration(days: 3)),
      ),
      RecordData(
        id: 'record_${_idCounter++}',
        aquariumId: 'aquarium_2',
        date: now.subtract(const Duration(days: 5)),
        tags: [RecordTag.waterTest],
        content: 'pH 7.2, 암모니아 0, 아질산 0. 양호한 상태.',
        isPublic: true,
        created: now.subtract(const Duration(days: 5)),
      ),
    ]);
  }

  /// 테스트용: 데이터 초기화
  void clearAll() {
    _records.clear();
    _idCounter = 1;
  }

  /// 테스트용: 인스턴스 리셋
  @visibleForTesting
  static void resetInstance() {
    _instance = null;
  }
}
