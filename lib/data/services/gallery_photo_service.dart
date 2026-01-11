import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:http/http.dart' as http;
import '../../domain/models/gallery_photo_data.dart';
import 'pocketbase_service.dart';

/// 갤러리 사진 관리 서비스
///
/// PocketBase gallery_photos 컬렉션 CRUD 및 파일 업로드
class GalleryPhotoService {
  GalleryPhotoService._();

  static GalleryPhotoService? _instance;
  static GalleryPhotoService get instance => _instance ??= GalleryPhotoService._();

  PocketBase get _client => PocketBaseService.instance.client;
  String get _baseUrl => PocketBaseService.serverUrl;

  static const String _collection = 'gallery_photos';

  /// 어항별 갤러리 사진 조회
  Future<List<GalleryPhotoData>> getPhotosByAquarium(
    String aquariumId, {
    String? creatureId,
    bool newestFirst = true,
    int? limit,
  }) async {
    try {
      String filter = 'aquarium_id = "$aquariumId"';
      if (creatureId != null) {
        filter += ' && creature_id = "$creatureId"';
      }

      final sort = newestFirst ? '-photo_date' : 'photo_date';

      List<RecordModel> records;
      if (limit != null) {
        final result = await _client.collection(_collection).getList(
          page: 1,
          perPage: limit,
          filter: filter,
          sort: sort,
          expand: 'creature_id',
        );
        records = result.items;
      } else {
        records = await _client.collection(_collection).getFullList(
          filter: filter,
          sort: sort,
          expand: 'creature_id',
        );
      }

      return records
          .map((r) => GalleryPhotoData.fromJson(r.toJson(), baseUrl: _baseUrl))
          .toList();
    } catch (e) {
      debugPrint('Failed to get gallery photos: $e');
      rethrow;
    }
  }

  /// 생물별 갤러리 사진 조회
  Future<List<GalleryPhotoData>> getPhotosByCreature(
    String creatureId, {
    bool newestFirst = true,
  }) async {
    try {
      final sort = newestFirst ? '-photo_date' : 'photo_date';

      final records = await _client.collection(_collection).getFullList(
        filter: 'creature_id = "$creatureId"',
        sort: sort,
      );

      return records
          .map((r) => GalleryPhotoData.fromJson(r.toJson(), baseUrl: _baseUrl))
          .toList();
    } catch (e) {
      debugPrint('Failed to get photos by creature: $e');
      rethrow;
    }
  }

  /// 사진 상세 조회
  Future<GalleryPhotoData> getPhoto(String id) async {
    try {
      final record = await _client.collection(_collection).getOne(
        id,
        expand: 'creature_id',
      );
      return GalleryPhotoData.fromJson(record.toJson(), baseUrl: _baseUrl);
    } catch (e) {
      debugPrint('Failed to get photo: $e');
      rethrow;
    }
  }

  /// 사진 업로드
  Future<GalleryPhotoData> uploadPhoto(GalleryPhotoData photo) async {
    if (photo.imageFile == null) {
      throw ArgumentError('Image file is required');
    }

    try {
      final file = File(photo.imageFile!);
      if (!await file.exists()) {
        throw ArgumentError('Image file does not exist');
      }

      final multipartFile = await http.MultipartFile.fromPath(
        'image',
        photo.imageFile!,
      );

      final record = await _client.collection(_collection).create(
        body: photo.toJson(),
        files: [multipartFile],
      );

      return GalleryPhotoData.fromJson(record.toJson(), baseUrl: _baseUrl);
    } catch (e) {
      debugPrint('Failed to upload photo: $e');
      rethrow;
    }
  }

  /// 여러 사진 업로드
  Future<List<GalleryPhotoData>> uploadPhotos(
    String aquariumId,
    List<String> filePaths, {
    String? creatureId,
    DateTime? photoDate,
  }) async {
    final results = <GalleryPhotoData>[];
    final date = photoDate ?? DateTime.now();

    for (final filePath in filePaths) {
      final photo = GalleryPhotoData(
        aquariumId: aquariumId,
        creatureId: creatureId,
        imageFile: filePath,
        photoDate: date,
      );

      final uploaded = await uploadPhoto(photo);
      results.add(uploaded);
    }

    return results;
  }

  /// 사진 수정 (메타데이터만)
  Future<GalleryPhotoData> updatePhoto(GalleryPhotoData photo) async {
    if (photo.id == null) {
      throw ArgumentError('Photo ID is required for update');
    }

    try {
      final record = await _client.collection(_collection).update(
        photo.id!,
        body: photo.toJson(),
      );

      return GalleryPhotoData.fromJson(record.toJson(), baseUrl: _baseUrl);
    } catch (e) {
      debugPrint('Failed to update photo: $e');
      rethrow;
    }
  }

  /// 사진 삭제
  Future<void> deletePhoto(String id) async {
    try {
      await _client.collection(_collection).delete(id);
    } catch (e) {
      debugPrint('Failed to delete photo: $e');
      rethrow;
    }
  }

  /// 여러 사진 삭제
  Future<void> deletePhotos(List<String> ids) async {
    for (final id in ids) {
      await deletePhoto(id);
    }
  }

  /// 어항별 사진 수 조회
  Future<int> getPhotoCount(String aquariumId, {String? creatureId}) async {
    try {
      String filter = 'aquarium_id = "$aquariumId"';
      if (creatureId != null) {
        filter += ' && creature_id = "$creatureId"';
      }

      final result = await _client.collection(_collection).getList(
        page: 1,
        perPage: 1,
        filter: filter,
      );
      return result.totalItems;
    } catch (e) {
      debugPrint('Failed to get photo count: $e');
      return 0;
    }
  }

  /// 날짜별 그룹화된 사진 조회
  Future<Map<DateTime, List<GalleryPhotoData>>> getPhotosGroupedByDate(
    String aquariumId, {
    String? creatureId,
    bool newestFirst = true,
  }) async {
    final photos = await getPhotosByAquarium(
      aquariumId,
      creatureId: creatureId,
      newestFirst: newestFirst,
    );

    final grouped = <DateTime, List<GalleryPhotoData>>{};
    for (final photo in photos) {
      final dateKey = DateTime(
        photo.photoDate.year,
        photo.photoDate.month,
        photo.photoDate.day,
      );
      grouped.putIfAbsent(dateKey, () => []).add(photo);
    }

    return grouped;
  }
}
