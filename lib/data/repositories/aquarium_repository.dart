import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pocketbase/pocketbase.dart';
import '../../domain/models/aquarium_data.dart';
import '../services/pocketbase_service.dart';

/// 어항 Repository
///
/// 어항 데이터 CRUD 및 파일 업로드 처리
class AquariumRepository {
  AquariumRepository._();

  static AquariumRepository? _instance;
  static AquariumRepository get instance =>
      _instance ??= AquariumRepository._();

  static const String _collectionName = 'aquariums';

  PocketBase get _pb => PocketBaseService.instance.client;

  /// 어항 목록 조회
  Future<List<AquariumData>> getAquariums({
    int page = 1,
    int perPage = 20,
    String? filter,
    String sort = '-created',
  }) async {
    try {
      final result = await _pb
          .collection(_collectionName)
          .getList(page: page, perPage: perPage, filter: filter, sort: sort);

      return result.items.map((record) {
        final data = AquariumData.fromJson(record.toJson());
        // 파일 URL 설정
        if (record.data['photo'] != null &&
            record.data['photo'].toString().isNotEmpty) {
          data.photoUrl = _pb.files
              .getUrl(record, record.data['photo'])
              .toString();
        }
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error fetching aquariums: $e');
      rethrow;
    }
  }

  /// 어항 단일 조회
  Future<AquariumData?> getAquarium(String id) async {
    try {
      final record = await _pb.collection(_collectionName).getOne(id);
      final data = AquariumData.fromJson(record.toJson());

      if (record.data['photo'] != null &&
          record.data['photo'].toString().isNotEmpty) {
        data.photoUrl = _pb.files
            .getUrl(record, record.data['photo'])
            .toString();
      }

      return data;
    } catch (e) {
      debugPrint('Error fetching aquarium: $e');
      return null;
    }
  }

  /// 어항 생성
  Future<AquariumData> createAquarium(AquariumData data) async {
    try {
      // 파일 업로드가 있는 경우
      List<http.MultipartFile> files = [];

      if (data.photoPath != null && !kIsWeb) {
        final file = File(data.photoPath!);
        if (await file.exists()) {
          files.add(await http.MultipartFile.fromPath('photo', file.path));
        }
      }

      final record = await _pb
          .collection(_collectionName)
          .create(body: data.toJson(), files: files);

      final result = AquariumData.fromJson(record.toJson());
      if (record.data['photo'] != null &&
          record.data['photo'].toString().isNotEmpty) {
        result.photoUrl = _pb.files
            .getUrl(record, record.data['photo'])
            .toString();
      }

      return result;
    } catch (e) {
      debugPrint('Error creating aquarium: $e');
      rethrow;
    }
  }

  /// 어항 수정
  Future<AquariumData> updateAquarium(
    String id,
    AquariumData data, {
    bool updatePhoto = false,
  }) async {
    try {
      List<http.MultipartFile> files = [];

      if (updatePhoto && data.photoPath != null && !kIsWeb) {
        final file = File(data.photoPath!);
        if (await file.exists()) {
          files.add(await http.MultipartFile.fromPath('photo', file.path));
        }
      }

      final record = await _pb
          .collection(_collectionName)
          .update(id, body: data.toJson(), files: files);

      final result = AquariumData.fromJson(record.toJson());
      if (record.data['photo'] != null &&
          record.data['photo'].toString().isNotEmpty) {
        result.photoUrl = _pb.files
            .getUrl(record, record.data['photo'])
            .toString();
      }

      return result;
    } catch (e) {
      debugPrint('Error updating aquarium: $e');
      rethrow;
    }
  }

  /// 어항 삭제
  Future<void> deleteAquarium(String id) async {
    try {
      await _pb.collection(_collectionName).delete(id);
    } catch (e) {
      debugPrint('Error deleting aquarium: $e');
      rethrow;
    }
  }

  /// 어항 개수 조회
  Future<int> getAquariumCount({String? filter}) async {
    try {
      final result = await _pb
          .collection(_collectionName)
          .getList(page: 1, perPage: 1, filter: filter);
      return result.totalItems;
    } catch (e) {
      debugPrint('Error counting aquariums: $e');
      return 0;
    }
  }
}
