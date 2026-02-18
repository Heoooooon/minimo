import '../../domain/models/record_data.dart';
import '../services/record_service.dart';

abstract class RecordRepository {
  Future<List<RecordData>> getRecords({
    int page = 1,
    int perPage = 20,
    String? filter,
    String sort = '-date',
  });
  Future<List<RecordData>> getRecordsByDate(DateTime date);
  Future<List<RecordData>> getRecordsByDateAndAquarium(
    DateTime date,
    String? aquariumId,
  );
  Future<List<RecordData>> getRecordsByDateAquariumAndCreature(
    DateTime date,
    String? aquariumId, {
    String? creatureId,
    String? recordType,
  });
  Future<List<DateTime>> getRecordDatesInMonth(DateTime month);
  Future<RecordData> createRecord(RecordData data);
  Future<RecordData> updateRecord(String id, RecordData data);
  Future<void> updateRecordCompletion(String id, bool isCompleted);
  Future<void> deleteRecord(String id);
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

  @override
  Future<List<RecordData>> getRecordsByDate(DateTime date) async {
    return _service.getRecordsByDate(date);
  }

  @override
  Future<List<DateTime>> getRecordDatesInMonth(DateTime month) async {
    return _service.getRecordDatesInMonth(month);
  }

  @override
  Future<List<RecordData>> getRecordsByDateAndAquarium(
    DateTime date,
    String? aquariumId,
  ) async {
    return _service.getRecordsByDateAndAquarium(date, aquariumId);
  }

  @override
  Future<List<RecordData>> getRecordsByDateAquariumAndCreature(
    DateTime date,
    String? aquariumId, {
    String? creatureId,
    String? recordType,
  }) async {
    return _service.getRecordsByDateAquariumAndCreature(
      date,
      aquariumId,
      creatureId: creatureId,
      recordType: recordType,
    );
  }

  @override
  Future<RecordData> updateRecord(String id, RecordData data) async {
    return _service.updateRecord(id, data);
  }

  @override
  Future<void> updateRecordCompletion(String id, bool isCompleted) async {
    return _service.updateRecordCompletion(id, isCompleted);
  }
}
