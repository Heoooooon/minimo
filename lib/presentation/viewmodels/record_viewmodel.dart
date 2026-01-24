import '../../data/repositories/record_repository.dart';
import '../../domain/models/record_data.dart';
import 'base_viewmodel.dart';

class RecordViewModel extends BaseViewModel {
  // PocketBase Repository 사용
  final RecordRepository _repository = PocketBaseRecordRepository.instance;

  Future<bool> saveRecord({
    required DateTime date,
    required List<RecordTag> tags,
    required String content,
    required bool isPublic,
    String? aquariumId,
  }) async {
    return await runAsyncBool(() async {
      final record = RecordData(
        date: date,
        tags: tags,
        content: content,
        isPublic: isPublic,
        aquariumId: aquariumId,
      );

      await _repository.createRecord(record);
    }, errorPrefix: '기록 저장 중 오류가 발생했습니다');
  }
}
