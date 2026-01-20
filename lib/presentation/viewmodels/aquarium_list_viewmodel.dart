import 'package:flutter/foundation.dart';
import '../../data/repositories/aquarium_repository.dart';
import '../../data/services/creature_service.dart';
import '../../domain/models/aquarium_data.dart';

/// 어항 목록 ViewModel
class AquariumListViewModel extends ChangeNotifier {
  AquariumListViewModel() {
    loadAquariums();
  }

  // PocketBase Repository 사용
  final AquariumRepository _repository = PocketBaseAquariumRepository.instance;

  /// 어항 목록
  List<AquariumData> _aquariums = [];
  List<AquariumData> get aquariums => _aquariums;

  /// 어항별 생물 수 (aquariumId -> creatureCount)
  Map<String, int> _creatureCounts = {};
  Map<String, int> get creatureCounts => _creatureCounts;

  /// 어항별 생물 수 조회
  int getCreatureCount(String? aquariumId) {
    if (aquariumId == null) return 0;
    return _creatureCounts[aquariumId] ?? 0;
  }

  /// 로딩 상태
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// 에러 메시지
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// 어항이 있는지 확인
  bool get hasAquariums => _aquariums.isNotEmpty;

  /// 캐싱 관련 필드
  DateTime? _lastFetchTime;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  /// 캐시가 유효한지 확인
  bool _isCacheValid() {
    return _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheValidDuration &&
        _aquariums.isNotEmpty;
  }

  /// 어항 목록 로드
  /// [forceRefresh]가 true이면 캐시를 무시하고 새로 로드
  Future<void> loadAquariums({bool forceRefresh = false}) async {
    // 캐시가 유효하고 강제 새로고침이 아니면 스킵
    if (!forceRefresh && _isCacheValid()) {
      return;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _aquariums = await _repository.getAquariums();
      _lastFetchTime = DateTime.now();

      // 각 어항별 생물 수 조회
      await _loadCreatureCounts();
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

  /// 어항별 생물 수 로드
  Future<void> _loadCreatureCounts() async {
    final newCounts = <String, int>{};
    for (final aquarium in _aquariums) {
      if (aquarium.id != null) {
        try {
          final creatures = await CreatureService.instance.getCreaturesByAquarium(aquarium.id!);
          // quantity 합계 계산
          final totalCount = creatures.fold<int>(0, (sum, c) => sum + c.quantity);
          newCounts[aquarium.id!] = totalCount;
        } catch (e) {
          debugPrint('Failed to load creature count for ${aquarium.id}: $e');
          newCounts[aquarium.id!] = 0;
        }
      }
    }
    _creatureCounts = newCounts;
  }

  /// 새로고침 (강제 새로고침)
  Future<void> refresh() async {
    await loadAquariums(forceRefresh: true);
  }

  /// 에러 초기화
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
