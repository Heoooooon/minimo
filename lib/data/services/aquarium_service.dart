import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:http/http.dart' as http;
import 'pocketbase_service.dart';
import '../../domain/models/aquarium_data.dart';

/// 어항 관리 서비스
///
/// PocketBase aquariums 컬렉션과 통신
class AquariumService {
  AquariumService._();

  static AquariumService? _instance;
  static AquariumService get instance => _instance ??= AquariumService._();

  PocketBase get _pb => PocketBaseService.instance.client;

  static const String _collection = 'aquariums';

  /// 모든 어항 목록 조회
  Future<List<AquariumData>> getAquariums({
    int page = 1,
    int perPage = 20,
    String? filter,
    String sort = '-created',
  }) async {
    try {
      final result = await _pb.collection(_collection).getList(
        page: page,
        perPage: perPage,
        filter: filter,
        sort: sort,
      );

      return result.items.map((record) => _recordToAquariumData(record)).toList();
    } catch (e) {
      debugPrint('Failed to get aquariums: $e');
      rethrow;
    }
  }

  /// 모든 어항 전체 목록 조회
  Future<List<AquariumData>> getAllAquariums({String sort = '-created'}) async {
    try {
      final records = await _pb.collection(_collection).getFullList(
        sort: sort,
      );

      return records.map((record) => _recordToAquariumData(record)).toList();
    } catch (e) {
      debugPrint('Failed to get all aquariums: $e');
      rethrow;
    }
  }

  /// 특정 어항 조회
  Future<AquariumData?> getAquarium(String id) async {
    try {
      final record = await _pb.collection(_collection).getOne(id);
      return _recordToAquariumData(record);
    } catch (e) {
      debugPrint('Failed to get aquarium: $e');
      return null;
    }
  }

  /// 어항 개수 조회
  Future<int> getAquariumCount({String? filter}) async {
    try {
      final result = await _pb.collection(_collection).getList(
        page: 1,
        perPage: 1,
        filter: filter,
      );
      return result.totalItems;
    } catch (e) {
      debugPrint('Failed to get aquarium count: $e');
      return 0;
    }
  }

  /// 어항 생성
  Future<AquariumData> createAquarium(AquariumData aquarium) async {
    try {
      final body = aquarium.toJson();

      RecordModel record;

      if (aquarium.photoPath != null && aquarium.photoPath!.isNotEmpty) {
        // 사진이 있는 경우 멀티파트로 업로드
        final file = await http.MultipartFile.fromPath('photo', aquarium.photoPath!);
        record = await _pb.collection(_collection).create(
          body: body,
          files: [file],
        );
      } else {
        record = await _pb.collection(_collection).create(body: body);
      }

      debugPrint('Aquarium created: ${record.id}');
      return _recordToAquariumData(record);
    } catch (e) {
      debugPrint('Failed to create aquarium: $e');
      rethrow;
    }
  }

  /// 어항 수정
  Future<AquariumData> updateAquarium(String id, AquariumData aquarium) async {
    try {
      final body = aquarium.toJson();

      RecordModel record;

      if (aquarium.photoPath != null && aquarium.photoPath!.isNotEmpty) {
        final file = await http.MultipartFile.fromPath('photo', aquarium.photoPath!);
        record = await _pb.collection(_collection).update(
          id,
          body: body,
          files: [file],
        );
      } else {
        record = await _pb.collection(_collection).update(
          id,
          body: body,
        );
      }

      debugPrint('Aquarium updated: ${record.id}');
      return _recordToAquariumData(record);
    } catch (e) {
      debugPrint('Failed to update aquarium: $e');
      rethrow;
    }
  }

  /// 어항 삭제
  Future<void> deleteAquarium(String id) async {
    try {
      await _pb.collection(_collection).delete(id);
      debugPrint('Aquarium deleted: $id');
    } catch (e) {
      debugPrint('Failed to delete aquarium: $e');
      rethrow;
    }
  }

  /// 어항 사진 URL 가져오기
  String? getPhotoUrl(RecordModel record) {
    final photo = record.getStringValue('photo');
    if (photo.isEmpty) return null;
    return _pb.files.getUrl(record, photo).toString();
  }

  /// RecordModel을 AquariumData로 변환
  AquariumData _recordToAquariumData(RecordModel record) {
    final photoUrl = getPhotoUrl(record);

    return AquariumData(
      id: record.id,
      name: record.getStringValue('name'),
      type: AquariumType.fromValue(record.getStringValue('type')),
      settingDate: DateTime.tryParse(record.getStringValue('setting_date')),
      dimensions: record.getStringValue('dimensions'),
      filterType: FilterType.fromValue(record.getStringValue('filter_type')),
      substrate: record.getStringValue('substrate'),
      productName: record.getStringValue('product_name'),
      lighting: LightingType.fromValue(record.getStringValue('lighting')),
      hasHeater: record.getBoolValue('heater'),
      purpose: AquariumPurpose.fromValue(record.getStringValue('purpose')),
      notes: record.getStringValue('notes'),
      photoUrl: photoUrl,
    );
  }
}
