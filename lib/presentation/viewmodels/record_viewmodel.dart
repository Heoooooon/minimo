import 'package:flutter/foundation.dart';
import '../../data/repositories/record_repository.dart';
import '../../domain/models/record_data.dart';

class RecordViewModel extends ChangeNotifier {
  // Mock Repository 사용
  final RecordRepository _repository = MockRecordRepository.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<bool> saveRecord({
    required DateTime date,
    required List<RecordTag> tags,
    required String content,
    required bool isPublic,
    String? aquariumId,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final record = RecordData(
        date: date,
        tags: tags,
        content: content,
        isPublic: isPublic,
        aquariumId: aquariumId,
      );

      await _repository.createRecord(record);
      return true;
    } catch (e) {
      debugPrint('Error saving record: $e');
      _errorMessage = '기록 저장 중 오류가 발생했습니다.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
