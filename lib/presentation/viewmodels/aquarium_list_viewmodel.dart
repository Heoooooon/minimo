import 'package:flutter/foundation.dart';
import '../../data/repositories/aquarium_repository.dart';
import '../../domain/models/aquarium_data.dart';

/// 어항 목록 ViewModel
class AquariumListViewModel extends ChangeNotifier {
  AquariumListViewModel() {
    loadAquariums();
  }

  // Mock Repository 사용
  final AquariumRepository _repository = MockAquariumRepository.instance;

  /// 어항 목록
  List<AquariumData> _aquariums = [];
  List<AquariumData> get aquariums => _aquariums;

  /// 로딩 상태
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// 에러 메시지
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// 어항이 있는지 확인
  bool get hasAquariums => _aquariums.isNotEmpty;

  /// 어항 목록 로드
  Future<void> loadAquariums() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _aquariums = await _repository.getAquariums();
    } catch (e) {
      debugPrint('Error loading aquariums: $e');
      _errorMessage = '어항 목록을 불러오는데 실패했습니다.';
      _aquariums = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 어항 삭제
  Future<bool> deleteAquarium(String id) async {
    try {
      await _repository.deleteAquarium(id);
      _aquariums.removeWhere((a) => a.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting aquarium: $e');
      _errorMessage = '어항 삭제에 실패했습니다.';
      notifyListeners();
      return false;
    }
  }

  /// 새로고침
  Future<void> refresh() async {
    await loadAquariums();
  }

  /// 에러 초기화
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
