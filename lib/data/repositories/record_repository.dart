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
  Future<List<RecordData>> getRecordsByDate(DateTime date);
  Future<List<DateTime>> getRecordDatesInMonth(DateTime month);
  Future<RecordData> createRecord(RecordData data);
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
}
