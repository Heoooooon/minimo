import '../../domain/models/aquarium_data.dart';
import '../services/aquarium_service.dart';

/// 어항 Repository 인터페이스
abstract class AquariumRepository {
  Future<List<AquariumData>> getAquariums({
    int page = 1,
    int perPage = 20,
    String? filter,
    String? sort,
  });
  Future<AquariumData?> getAquarium(String id);
  Future<AquariumData> createAquarium(AquariumData data);
  Future<AquariumData> updateAquarium(String id, AquariumData data);
  Future<void> deleteAquarium(String id);
  Future<int> getAquariumCount({String? filter});
}

/// PocketBase 어항 Repository
///
/// 실제 PocketBase 백엔드와 통신
class PocketBaseAquariumRepository implements AquariumRepository {
  PocketBaseAquariumRepository._();

  static PocketBaseAquariumRepository? _instance;
  static PocketBaseAquariumRepository get instance =>
      _instance ??= PocketBaseAquariumRepository._();

  final AquariumService _service = AquariumService.instance;

  @override
  Future<List<AquariumData>> getAquariums({
    int page = 1,
    int perPage = 20,
    String? filter,
    String? sort,
  }) async {
    return _service.getAquariums(
      page: page,
      perPage: perPage,
      filter: filter,
      sort: sort,
    );
  }

  @override
  Future<AquariumData?> getAquarium(String id) async {
    return _service.getAquarium(id);
  }

  @override
  Future<AquariumData> createAquarium(AquariumData data) async {
    return _service.createAquarium(data);
  }

  @override
  Future<AquariumData> updateAquarium(String id, AquariumData data) async {
    return _service.updateAquarium(id, data);
  }

  @override
  Future<void> deleteAquarium(String id) async {
    return _service.deleteAquarium(id);
  }

  @override
  Future<int> getAquariumCount({String? filter}) async {
    return _service.getAquariumCount(filter: filter);
  }
}
