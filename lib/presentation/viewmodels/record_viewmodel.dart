import '../../data/repositories/record_repository.dart';
import '../../domain/models/record_data.dart';
import 'base_viewmodel.dart';

class RecordViewModel extends BaseViewModel {
  final RecordRepository _repository = PocketBaseRecordRepository.instance;

  Future<RecordData?> saveRecord({
    required DateTime date,
    required List<RecordTag> tags,
    required String content,
    required bool isPublic,
    String? aquariumId,
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
        isCompleted: isCompleted,
      );

      created = await _repository.createRecord(record);
    }, errorPrefix: '기록 저장 중 오류가 발생했습니다');

    return success ? created : null;
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
      return [];
    }
  }
}
