import 'package:flutter/foundation.dart';
import 'package:oomool/data/repositories/aquarium_repository.dart';
import 'package:oomool/domain/models/aquarium_data.dart';

/// Mock 어항 Repository
///
/// 백엔드 없이 로컬 메모리에서 동작
/// 테스트 및 개발 목적으로 사용
class MockAquariumRepository implements AquariumRepository {
  MockAquariumRepository._();

  static MockAquariumRepository? _instance;
  static MockAquariumRepository get instance =>
      _instance ??= MockAquariumRepository._();

  // 인메모리 저장소
  final List<AquariumData> _aquariums = [];
  int _idCounter = 1;

  @override
  Future<List<AquariumData>> getAquariums({
    int page = 1,
    int perPage = 20,
    String? filter,
    String? sort,
  }) async {
    // 네트워크 지연 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 300));

    // 정렬 (최신순)
    final sorted = List<AquariumData>.from(_aquariums);
    if (sort != null && sort.startsWith('-')) {
      sorted.sort((a, b) => (b.id ?? '').compareTo(a.id ?? ''));
    } else if (sort != null && sort.isNotEmpty) {
      sorted.sort((a, b) => (a.id ?? '').compareTo(b.id ?? ''));
    }

    // 페이지네이션
    final start = (page - 1) * perPage;
    final end = start + perPage;
    if (start >= sorted.length) return [];

    return sorted.sublist(start, end.clamp(0, sorted.length));
  }

  @override
  Future<AquariumData?> getAquarium(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _aquariums.where((a) => a.id == id).firstOrNull;
  }

  @override
  Future<AquariumData> createAquarium(AquariumData data) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final newAquarium = data.copyWith(
      id: 'aquarium_${_idCounter++}',
      photoUrl: data.photoPath, // 로컬 경로를 URL로 사용
    );
    _aquariums.add(newAquarium);

    debugPrint('[MockAquariumRepository] Created: ${newAquarium.name}');
    return newAquarium;
  }

  @override
  Future<AquariumData> updateAquarium(String id, AquariumData data) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _aquariums.indexWhere((a) => a.id == id);
    if (index == -1) {
      throw Exception('Aquarium not found: $id');
    }

    final updated = data.copyWith(id: id);
    _aquariums[index] = updated;

    debugPrint('[MockAquariumRepository] Updated: ${updated.name}');
    return updated;
  }

  @override
  Future<void> deleteAquarium(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _aquariums.indexWhere((a) => a.id == id);
    if (index != -1) {
      final removed = _aquariums.removeAt(index);
      debugPrint('[MockAquariumRepository] Deleted: ${removed.name}');
    }
  }

  @override
  Future<int> getAquariumCount({String? filter}) async {
    return _aquariums.length;
  }

  /// 테스트용: 샘플 데이터 추가
  void addSampleData() {
    if (_aquariums.isNotEmpty) return;

    _aquariums.addAll([
      AquariumData(
        id: 'aquarium_${_idCounter++}',
        name: '호동이네',
        type: AquariumType.freshwater,
        settingDate: DateTime(2024, 1, 15),
        dimensions: '60x30x36',
        filterType: FilterType.hangOn,
        substrate: '소일',
        lighting: LightingType.led,
        hasHeater: true,
        purpose: AquariumPurpose.general,
        notes: '구피, 네온테트라 합사 중',
      ),
      AquariumData(
        id: 'aquarium_${_idCounter++}',
        name: '러키네',
        type: AquariumType.freshwater,
        settingDate: DateTime(2024, 3, 20),
        dimensions: '45x27x30',
        filterType: FilterType.sponge,
        substrate: '모래',
        lighting: LightingType.led,
        hasHeater: false,
        purpose: AquariumPurpose.breeding,
        notes: '베타 단독 사육',
      ),
    ]);
  }

  /// 테스트용: 데이터 초기화
  void clearAll() {
    _aquariums.clear();
    _idCounter = 1;
  }

  /// 테스트용: 인스턴스 리셋
  @visibleForTesting
  static void resetInstance() {
    _instance = null;
  }
}
