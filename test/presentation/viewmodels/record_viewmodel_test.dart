import 'package:flutter_test/flutter_test.dart';
import 'package:oomool/domain/models/record_data.dart';
import 'package:oomool/presentation/viewmodels/record_viewmodel.dart';
import 'package:oomool/data/repositories/record_repository.dart';

/// 테스트용 RecordRepository Mock
class TestRecordRepository implements RecordRepository {
  final List<RecordData> _records = [];
  int _idCounter = 1;
  bool shouldThrow = false;

  @override
  Future<RecordData> createRecord(RecordData data) async {
    if (shouldThrow) throw Exception('Create failed');
    final created = RecordData(
      id: 'test_${_idCounter++}',
      ownerId: 'user1',
      aquariumId: data.aquariumId,
      creatureId: data.creatureId,
      recordType: data.recordType,
      date: data.date,
      tags: data.tags,
      content: data.content,
      isPublic: data.isPublic,
      isCompleted: data.isCompleted,
      created: DateTime.now(),
    );
    _records.add(created);
    return created;
  }

  @override
  Future<void> deleteRecord(String id) async {
    if (shouldThrow) throw Exception('Delete failed');
    _records.removeWhere((r) => r.id == id);
  }

  @override
  Future<List<RecordData>> getRecords({
    int page = 1,
    int perPage = 20,
    String? filter,
    String sort = '-date',
  }) async {
    if (shouldThrow) throw Exception('Get records failed');
    return List.from(_records);
  }

  @override
  Future<List<RecordData>> getRecordsByDate(DateTime date) async {
    if (shouldThrow) throw Exception('Get by date failed');
    return _records
        .where((r) =>
            r.date.year == date.year &&
            r.date.month == date.month &&
            r.date.day == date.day)
        .toList();
  }

  @override
  Future<List<RecordData>> getRecordsByDateAndAquarium(
    DateTime date,
    String? aquariumId,
  ) async {
    if (shouldThrow) throw Exception('Get by date and aquarium failed');
    return _records.where((r) {
      if (r.date.year != date.year ||
          r.date.month != date.month ||
          r.date.day != date.day) {
        return false;
      }
      if (aquariumId != null && r.aquariumId != aquariumId) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<List<RecordData>> getRecordsByDateAquariumAndCreature(
    DateTime date,
    String? aquariumId, {
    String? creatureId,
    String? recordType,
  }) async {
    if (shouldThrow) throw Exception('Get by creature failed');
    return _records.where((r) {
      if (r.date.year != date.year ||
          r.date.month != date.month ||
          r.date.day != date.day) {
        return false;
      }
      if (aquariumId != null && r.aquariumId != aquariumId) {
        return false;
      }
      if (creatureId != null &&
          creatureId.isNotEmpty &&
          r.creatureId != creatureId) {
        return false;
      }
      if (recordType != null &&
          recordType.isNotEmpty &&
          r.recordType.name != recordType) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<List<DateTime>> getRecordDatesInMonth(DateTime month) async {
    if (shouldThrow) throw Exception('Get dates failed');
    final dates = <DateTime>{};
    for (final r in _records) {
      if (r.date.year == month.year && r.date.month == month.month) {
        dates.add(DateTime(r.date.year, r.date.month, r.date.day));
      }
    }
    return dates.toList()..sort();
  }

  @override
  Future<RecordData> updateRecord(String id, RecordData data) async {
    if (shouldThrow) throw Exception('Update record failed');
    final index = _records.indexWhere((r) => r.id == id);
    if (index != -1) {
      _records[index] = data;
    }
    return data;
  }

  @override
  Future<void> updateRecordCompletion(String id, bool isCompleted) async {
    if (shouldThrow) throw Exception('Update failed');
    final record = _records.firstWhere((r) => r.id == id);
    record.isCompleted = isCompleted;
  }

  void addRecord(RecordData record) {
    _records.add(record);
  }

  void clear() {
    _records.clear();
    _idCounter = 1;
    shouldThrow = false;
  }
}

void main() {
  late RecordViewModel viewModel;
  late TestRecordRepository repository;

  setUp(() {
    repository = TestRecordRepository();
    viewModel = RecordViewModel.withRepository(repository);
  });

  tearDown(() {
    repository.clear();
    viewModel.dispose();
  });

  group('saveRecord', () {
    test('creates record successfully', () async {
      final result = await viewModel.saveRecord(
        date: DateTime(2025, 6, 15),
        tags: [RecordTag.waterChange],
        content: '물갈이 완료',
        isPublic: true,
        aquariumId: 'aq1',
      );

      expect(result, isNotNull);
      expect(result!.content, '물갈이 완료');
      expect(result.aquariumId, 'aq1');
      expect(result.id, isNotNull);
    });

    test('returns null on failure', () async {
      repository.shouldThrow = true;

      final result = await viewModel.saveRecord(
        date: DateTime(2025, 6, 15),
        tags: [],
        content: 'test',
        isPublic: true,
      );

      expect(result, isNull);
      expect(viewModel.errorMessage, isNotNull);
    });

    test('sets correct record type', () async {
      final result = await viewModel.saveRecord(
        date: DateTime(2025, 6, 15),
        tags: [],
        content: '일기 내용',
        isPublic: false,
        recordType: RecordType.diary,
      );

      expect(result, isNotNull);
      expect(result!.recordType, RecordType.diary);
    });
  });

  group('updateRecordCompletion', () {
    test('updates completion state', () async {
      repository.addRecord(RecordData(
        id: 'rec1',
        date: DateTime(2025, 6, 15),
        content: 'test',
        isCompleted: false,
      ));

      final success = await viewModel.updateRecordCompletion('rec1', true);
      expect(success, true);
    });

    test('returns false on failure', () async {
      repository.shouldThrow = true;
      final success = await viewModel.updateRecordCompletion('rec1', true);
      expect(success, false);
    });
  });

  group('getRecordsByDateAndAquarium', () {
    test('returns records for specific date and aquarium', () async {
      repository.addRecord(RecordData(
        id: 'rec1',
        date: DateTime(2025, 6, 15),
        aquariumId: 'aq1',
        content: '기록1',
      ));
      repository.addRecord(RecordData(
        id: 'rec2',
        date: DateTime(2025, 6, 15),
        aquariumId: 'aq2',
        content: '기록2',
      ));
      repository.addRecord(RecordData(
        id: 'rec3',
        date: DateTime(2025, 6, 16),
        aquariumId: 'aq1',
        content: '기록3',
      ));

      final results = await viewModel.getRecordsByDateAndAquarium(
        DateTime(2025, 6, 15),
        'aq1',
      );

      expect(results.length, 1);
      expect(results.first.content, '기록1');
    });

    test('rethrows on error', () async {
      repository.shouldThrow = true;
      expect(
        () => viewModel.getRecordsByDateAndAquarium(DateTime.now(), 'aq1'),
        throwsException,
      );
    });
  });

  group('getRecordsByCreature', () {
    test('filters by creature and record type', () async {
      repository.addRecord(RecordData(
        id: 'rec1',
        date: DateTime(2025, 6, 15),
        aquariumId: 'aq1',
        creatureId: 'cr1',
        recordType: RecordType.todo,
        content: '할 일',
      ));
      repository.addRecord(RecordData(
        id: 'rec2',
        date: DateTime(2025, 6, 15),
        aquariumId: 'aq1',
        creatureId: 'cr1',
        recordType: RecordType.diary,
        content: '일기',
      ));
      repository.addRecord(RecordData(
        id: 'rec3',
        date: DateTime(2025, 6, 15),
        aquariumId: 'aq1',
        creatureId: 'cr2',
        recordType: RecordType.todo,
        content: '다른 생물',
      ));

      final results = await viewModel.getRecordsByCreature(
        DateTime(2025, 6, 15),
        'aq1',
        creatureId: 'cr1',
        recordType: RecordType.todo,
      );

      expect(results.length, 1);
      expect(results.first.content, '할 일');
    });
  });
}
