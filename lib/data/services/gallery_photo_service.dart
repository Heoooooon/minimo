import 'dart:io';
import 'package:pocketbase/pocketbase.dart';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/pb_filter.dart';
import '../../domain/models/gallery_photo_data.dart';
import 'pocketbase_service.dart';

/// 갤러리 사진 관리 서비스
///
/// PocketBase gallery_photos 컬렉션 CRUD 및 파일 업로드
class GalleryPhotoService {
  GalleryPhotoService._();

  static GalleryPhotoService? _instance;
  static GalleryPhotoService get instance =>
      _instance ??= GalleryPhotoService._();
  int get _batchConcurrency => AppConfig.galleryBatchConcurrency > 0
      ? AppConfig.galleryBatchConcurrency
      : 3;

  PocketBase get _client => PocketBaseService.instance.client;
  String get _baseUrl => PocketBaseService.serverUrl;
  String? get _currentUserId => _client.authStore.record?.id;

  static const String _collection = 'gallery_photos';

  /// 어항별 갤러리 사진 조회
  Future<List<GalleryPhotoData>> getPhotosByAquarium(
    String aquariumId, {
    String? creatureId,
    bool newestFirst = true,
    int? limit,
  }) async {
    try {
      String filter = PbFilter.eq('aquarium_id', aquariumId);
      if (creatureId != null) {
        filter += ' && ${PbFilter.eq('creature_id', creatureId)}';
      }

      final sort = newestFirst ? '-photo_date' : 'photo_date';
      if (limit != null) {
        final result = await _client
            .collection(_collection)
            .getList(
              page: 1,
              perPage: limit,
              filter: filter,
              sort: sort,
              expand: 'creature_id',
            );
        return result.items
            .map(
              (r) => GalleryPhotoData.fromJson(r.toJson(), baseUrl: _baseUrl),
            )
            .toList();
      }

      final records = await _client
          .collection(_collection)
          .getFullList(filter: filter, sort: sort, expand: 'creature_id');

      return records
          .map((r) => GalleryPhotoData.fromJson(r.toJson(), baseUrl: _baseUrl))
          .toList();
    } on ClientException catch (e) {
      AppLogger.data('Failed to get gallery photos: $e', isError: true);
      throw NetworkException.clientError(
        message: '갤러리 사진을 불러오는데 실패했습니다.',
        statusCode: e.statusCode,
        originalError: e,
      );
    } catch (e) {
      AppLogger.data('Failed to get gallery photos: $e', isError: true);
      throw NetworkException(message: '갤러리 사진 조회 중 오류가 발생했습니다.', originalError: e);
    }
  }

  /// 생물별 갤러리 사진 조회
  Future<List<GalleryPhotoData>> getPhotosByCreature(
    String creatureId, {
    bool newestFirst = true,
  }) async {
    try {
      final sort = newestFirst ? '-photo_date' : 'photo_date';

      final records = await _client
          .collection(_collection)
          .getFullList(
            filter: PbFilter.eq('creature_id', creatureId),
            sort: sort,
          );

      return records
          .map((r) => GalleryPhotoData.fromJson(r.toJson(), baseUrl: _baseUrl))
          .toList();
    } on ClientException catch (e) {
      AppLogger.data('Failed to get photos by creature: $e', isError: true);
      throw NetworkException.clientError(
        message: '생물 사진을 불러오는데 실패했습니다.',
        statusCode: e.statusCode,
        originalError: e,
      );
    } catch (e) {
      AppLogger.data('Failed to get photos by creature: $e', isError: true);
      throw NetworkException(message: '생물 사진 조회 중 오류가 발생했습니다.', originalError: e);
    }
  }

  /// 사진 상세 조회
  Future<GalleryPhotoData> getPhoto(String id) async {
    try {
      final record = await _client
          .collection(_collection)
          .getOne(id, expand: 'creature_id');
      return GalleryPhotoData.fromJson(record.toJson(), baseUrl: _baseUrl);
    } on ClientException catch (e) {
      AppLogger.data('Failed to get photo: $e', isError: true);
      throw NetworkException.clientError(
        message: '사진을 불러오는데 실패했습니다.',
        statusCode: e.statusCode,
        originalError: e,
      );
    } catch (e) {
      AppLogger.data('Failed to get photo: $e', isError: true);
      throw NetworkException(message: '사진 조회 중 오류가 발생했습니다.', originalError: e);
    }
  }

  Future<GalleryPhotoData> uploadPhoto(GalleryPhotoData photo) async {
    if (photo.imageFile == null) {
      throw ArgumentError('Image file is required');
    }

    final userId = _currentUserId;
    if (userId == null) {
      throw const AuthException(message: '로그인이 필요합니다.', code: 'LOGIN_REQUIRED');
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

      final body = photo.toJson();
      body['owner'] = userId;

      final record = await _client
          .collection(_collection)
          .create(body: body, files: [multipartFile]);

      return GalleryPhotoData.fromJson(record.toJson(), baseUrl: _baseUrl);
    } on ClientException catch (e) {
      AppLogger.data('Failed to upload photo: $e', isError: true);
      throw NetworkException.clientError(
        message: '사진 업로드에 실패했습니다.',
        statusCode: e.statusCode,
        originalError: e,
      );
    } catch (e) {
      AppLogger.data('Failed to upload photo: $e', isError: true);
      throw NetworkException(message: '사진 업로드 중 오류가 발생했습니다.', originalError: e);
    }
  }

  /// 여러 사진 업로드
  Future<List<GalleryPhotoData>> uploadPhotos(
    String aquariumId,
    List<String> filePaths, {
    String? creatureId,
    DateTime? photoDate,
  }) async {
    final stopwatch = Stopwatch()..start();
    bool hasError = false;
    int uploadedCount = 0;
    final results = <GalleryPhotoData>[];
    final date = photoDate ?? DateTime.now();

    try {
      for (int i = 0; i < filePaths.length; i += _batchConcurrency) {
        final chunk = filePaths.skip(i).take(_batchConcurrency);
        final uploadedChunk = await Future.wait(
          chunk.map((filePath) {
            final photo = GalleryPhotoData(
              aquariumId: aquariumId,
              creatureId: creatureId,
              imageFile: filePath,
              photoDate: date,
            );
            return uploadPhoto(photo);
          }),
        );
        uploadedCount += uploadedChunk.length;
        results.addAll(uploadedChunk);
      }

      return results;
    } catch (_) {
      hasError = true;
      rethrow;
    } finally {
      stopwatch.stop();
      AppLogger.perf(
        'Gallery.uploadPhotos',
        stopwatch.elapsed,
        fields: {
          'requested': filePaths.length,
          'uploaded': uploadedCount,
          'concurrency': _batchConcurrency,
          if (creatureId != null) 'creatureId': creatureId,
        },
        isError: hasError,
      );
    }
  }

  /// 사진 수정 (메타데이터만)
  Future<GalleryPhotoData> updatePhoto(GalleryPhotoData photo) async {
    if (photo.id == null) {
      throw ArgumentError('Photo ID is required for update');
    }

    try {
      final record = await _client
          .collection(_collection)
          .update(photo.id!, body: photo.toJson());

      return GalleryPhotoData.fromJson(record.toJson(), baseUrl: _baseUrl);
    } on ClientException catch (e) {
      AppLogger.data('Failed to update photo: $e', isError: true);
      throw NetworkException.clientError(
        message: '사진 수정에 실패했습니다.',
        statusCode: e.statusCode,
        originalError: e,
      );
    } catch (e) {
      AppLogger.data('Failed to update photo: $e', isError: true);
      throw NetworkException(message: '사진 수정 중 오류가 발생했습니다.', originalError: e);
    }
  }

  /// 사진 삭제
  Future<void> deletePhoto(String id) async {
    try {
      await _client.collection(_collection).delete(id);
    } on ClientException catch (e) {
      AppLogger.data('Failed to delete photo: $e', isError: true);
      throw NetworkException.clientError(
        message: '사진 삭제에 실패했습니다.',
        statusCode: e.statusCode,
        originalError: e,
      );
    } catch (e) {
      AppLogger.data('Failed to delete photo: $e', isError: true);
      throw NetworkException(message: '사진 삭제 중 오류가 발생했습니다.', originalError: e);
    }
  }

  /// 여러 사진 삭제
  Future<void> deletePhotos(List<String> ids) async {
    final stopwatch = Stopwatch()..start();
    bool hasError = false;
    int deletedCount = 0;

    try {
      for (int i = 0; i < ids.length; i += _batchConcurrency) {
        final chunk = ids.skip(i).take(_batchConcurrency).toList();
        await Future.wait(chunk.map(deletePhoto));
        deletedCount += chunk.length;
      }
    } catch (_) {
      hasError = true;
      rethrow;
    } finally {
      stopwatch.stop();
      AppLogger.perf(
        'Gallery.deletePhotos',
        stopwatch.elapsed,
        fields: {
          'requested': ids.length,
          'deleted': deletedCount,
          'concurrency': _batchConcurrency,
        },
        isError: hasError,
      );
    }
  }

  /// 어항별 사진 수 조회
  Future<int> getPhotoCount(String aquariumId, {String? creatureId}) async {
    try {
      String filter = PbFilter.eq('aquarium_id', aquariumId);
      if (creatureId != null) {
        filter += ' && ${PbFilter.eq('creature_id', creatureId)}';
      }

      final result = await _client
          .collection(_collection)
          .getList(page: 1, perPage: 1, filter: filter);
      return result.totalItems;
    } catch (e) {
      AppLogger.data('Failed to get photo count: $e', isError: true);
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
