import '../../core/utils/app_logger.dart';
import '../../data/repositories/aquarium_repository.dart';
import '../../data/services/creature_service.dart';
import '../../domain/models/aquarium_data.dart';
import 'base_viewmodel.dart';

/// 어항 목록 ViewModel
class AquariumListViewModel extends CachingViewModel {
  AquariumListViewModel() {
    loadAquariums();
  }

  static const String _cacheKeyAquariums = 'aquariums';

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

  /// 어항이 있는지 확인
  bool get hasAquariums => _aquariums.isNotEmpty;

  /// 어항 목록 로드
  /// [forceRefresh]가 true이면 캐시를 무시하고 새로 로드
  Future<void> loadAquariums({bool forceRefresh = false}) async {
    // 캐시가 유효하고 강제 새로고침이 아니면 스킵
    if (!forceRefresh &&
        isCacheValid(_cacheKeyAquariums) &&
        _aquariums.isNotEmpty) {
      return;
    }

    await runAsync(() async {
      _aquariums = await _repository.getAquariums();
      updateCacheTimestamp(_cacheKeyAquariums);

      // 각 어항별 생물 수 조회
      await _loadCreatureCounts();
      return _aquariums;
    }, errorPrefix: '어항 목록을 불러오는데 실패했습니다');

    if (errorMessage != null) {
      _aquariums = [];
    }
  }

  /// 어항 삭제
  Future<bool> deleteAquarium(String id) async {
    final success = await runAsyncBool(() async {
      await _repository.deleteAquarium(id);
      _aquariums.removeWhere((a) => a.id == id);
    }, errorPrefix: '어항 삭제에 실패했습니다');
    return success;
  }

  /// 어항별 생물 수 로드
  Future<void> _loadCreatureCounts() async {
    final newCounts = <String, int>{};
    for (final aquarium in _aquariums) {
      if (aquarium.id != null) {
        try {
          final creatures = await CreatureService.instance
              .getCreaturesByAquarium(aquarium.id!);
          // quantity 합계 계산
          final totalCount = creatures.fold<int>(
            0,
            (sum, c) => sum + c.quantity,
          );
          newCounts[aquarium.id!] = totalCount;
        } catch (e) {
          AppLogger.data(
            'Failed to load creature count for ${aquarium.id}: $e',
            isError: true,
          );
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
}
