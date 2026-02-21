import '../../core/utils/app_logger.dart';
import '../../data/repositories/record_repository.dart';
import '../../domain/models/record_data.dart';
import 'base_viewmodel.dart';

class RecordViewModel extends BaseViewModel {
  RecordViewModel() : _repository = PocketBaseRecordRepository.instance;

  /// 테스트용 생성자 (Repository 주입)
  RecordViewModel.withRepository(this._repository);

  final RecordRepository _repository;

  Future<RecordData?> saveRecord({
    required DateTime date,
    required List<RecordTag> tags,
    required String content,
    required bool isPublic,
    String? aquariumId,
    String? creatureId,
    RecordType recordType = RecordType.todo,
    bool isCompleted = false,
  }) async {
    RecordData? created;
    final success = await runAsyncBool(() async {
      final record = RecordData(
        date: date,
        tags: tags,
        content: content,
        isPublic: isPublic,
        aquariumId: aquariumId,
        creatureId: creatureId,
        recordType: recordType,
        isCompleted: isCompleted,
      );

      created = await _repository.createRecord(record);
    }, errorPrefix: '기록 저장 중 오류가 발생했습니다');

    return success ? created : null;
  }

  Future<RecordData?> updateRecord(RecordData record) async {
    if (record.id == null) return null;
    RecordData? updated;
    final success = await runAsyncBool(() async {
      updated = await _repository.updateRecord(record.id!, record);
    }, errorPrefix: '기록 수정 중 오류가 발생했습니다');
    return success ? updated : null;
  }

  Future<bool> updateRecordCompletion(String recordId, bool isCompleted) async {
    return await runAsyncBool(() async {
      await _repository.updateRecordCompletion(recordId, isCompleted);
    }, errorPrefix: '기록 업데이트 중 오류가 발생했습니다');
  }

  Future<List<RecordData>> getRecordsByDateAndAquarium(
    DateTime date,
    String? aquariumId,
  ) async {
    try {
      return await _repository.getRecordsByDateAndAquarium(date, aquariumId);
    } catch (e) {
      AppLogger.error('[RecordViewModel] Failed to get records by date and aquarium: $e');
      rethrow;
    }
  }

  Future<List<RecordData>> getRecordsByCreature(
    DateTime date,
    String? aquariumId, {
    String? creatureId,
    RecordType? recordType,
  }) async {
    try {
      return await _repository.getRecordsByDateAquariumAndCreature(
        date,
        aquariumId,
        creatureId: creatureId,
        recordType: recordType?.name,
      );
    } catch (e) {
      AppLogger.error('[RecordViewModel] Failed to get records by creature: $e');
      rethrow;
    }
  }
}
