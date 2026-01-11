import 'package:flutter/foundation.dart';
import '../../domain/models/record_data.dart';
import '../services/record_service.dart';

/// 기록 Repository 인터페이스
abstract class RecordRepository {
  Future<List<RecordData>> getRecords({
    int page = 1,
    int perPage = 20,
    String? filter,
    String sort = '-date',
  });
  Future<RecordData> createRecord(RecordData data);
  Future<void> deleteRecord(String id);
}

/// Mock 기록 Repository
///
/// 백엔드 없이 로컬 메모리에서 동작
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
      date: data.date,
      tags: data.tags,
      content: data.content,
      isPublic: data.isPublic,
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
}

/// PocketBase 기록 Repository
///
/// 실제 PocketBase 백엔드와 통신
class PocketBaseRecordRepository implements RecordRepository {
  PocketBaseRecordRepository._();

  static PocketBaseRecordRepository? _instance;
  static PocketBaseRecordRepository get instance =>
      _instance ??= PocketBaseRecordRepository._();

  final RecordService _service = RecordService.instance;

  @override
  Future<List<RecordData>> getRecords({
    int page = 1,
    int perPage = 20,
    String? filter,
    String sort = '-date',
  }) async {
    return _service.getRecords(
      page: page,
      perPage: perPage,
      filter: filter,
      sort: sort,
    );
  }

  @override
  Future<RecordData> createRecord(RecordData data) async {
    return _service.createRecord(data);
  }

  @override
  Future<void> deleteRecord(String id) async {
    return _service.deleteRecord(id);
  }
}
