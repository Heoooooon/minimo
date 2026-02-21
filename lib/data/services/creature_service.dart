import 'dart:io';
import 'package:pocketbase/pocketbase.dart';
import 'package:http/http.dart' as http;
import '../../core/exceptions/app_exceptions.dart';
import '../../core/utils/pb_filter.dart';
import '../../domain/models/creature_data.dart';
import 'pocketbase_service.dart';
import '../../core/utils/app_logger.dart';

/// 생물 관리 서비스
///
/// PocketBase creatures 컬렉션 CRUD 및 파일 업로드
class CreatureService {
  CreatureService._();

  static CreatureService? _instance;
  static CreatureService get instance => _instance ??= CreatureService._();

  PocketBase get _client => PocketBaseService.instance.client;
  String get _baseUrl => PocketBaseService.serverUrl;
  String? get _currentUserId => _client.authStore.record?.id;

  static const String _collection = 'creatures';

  /// 어항별 생물 목록 조회
  Future<List<CreatureData>> getCreaturesByAquarium(String aquariumId) async {
    try {
      final records = await _client
          .collection(_collection)
          .getFullList(filter: PbFilter.eq('aquarium_id', aquariumId));

      return records
          .map((r) => CreatureData.fromJson(r.toJson(), baseUrl: _baseUrl))
          .toList();
    } on ClientException catch (e) {
      AppLogger.data('Failed to get creatures: $e', isError: true);
      throw NetworkException.clientError(
        message: '생물 목록을 불러오는데 실패했습니다.',
        statusCode: e.statusCode,
        originalError: e,
      );
    } catch (e) {
      AppLogger.data('Failed to get creatures: $e', isError: true);
      throw NetworkException(
        message: '생물 목록 조회 중 오류가 발생했습니다.',
        originalError: e,
      );
    }
  }

  /// 생물 상세 조회
  Future<CreatureData> getCreature(String id) async {
    try {
      final record = await _client.collection(_collection).getOne(id);
      return CreatureData.fromJson(record.toJson(), baseUrl: _baseUrl);
    } on ClientException catch (e) {
      AppLogger.data('Failed to get creature: $e', isError: true);
      if (e.statusCode == 404) {
        throw NotFoundException(
          message: '생물을 찾을 수 없습니다.',
          code: 'CREATURE_NOT_FOUND',
          resourceType: 'creature',
          resourceId: id,
        );
      }
      throw NetworkException.clientError(
        message: '생물 정보를 불러오는데 실패했습니다.',
        statusCode: e.statusCode,
        originalError: e,
      );
    } catch (e) {
      AppLogger.data('Failed to get creature: $e', isError: true);
      throw NetworkException(
        message: '생물 조회 중 오류가 발생했습니다.',
        originalError: e,
      );
    }
  }

  /// 생물 상세 조회 (메모 포함)
  Future<CreatureData> getCreatureWithMemos(String id) async {
    try {
      final record = await _client.collection(_collection).getOne(id);
      final creature = CreatureData.fromJson(
        record.toJson(),
        baseUrl: _baseUrl,
      );

      // 메모 조회
      final memoRecords = await _client
          .collection('creature_memos')
          .getFullList(filter: PbFilter.eq('creature_id', id));

      final memos = memoRecords
          .map((r) => CreatureMemoData.fromJson(r.toJson()))
          .toList();

      return creature.copyWith(memos: memos);
    } on ClientException catch (e) {
      AppLogger.data('Failed to get creature with memos: $e', isError: true);
      if (e.statusCode == 404) {
        throw NotFoundException(
          message: '생물을 찾을 수 없습니다.',
          code: 'CREATURE_NOT_FOUND',
          resourceType: 'creature',
          resourceId: id,
        );
      }
      throw NetworkException.clientError(
        message: '생물 정보를 불러오는데 실패했습니다.',
        statusCode: e.statusCode,
        originalError: e,
      );
    } catch (e) {
      AppLogger.data('Failed to get creature with memos: $e', isError: true);
      throw NetworkException(
        message: '생물 조회 중 오류가 발생했습니다.',
        originalError: e,
      );
    }
  }

  Future<CreatureData> createCreature(CreatureData creature) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw const AuthException(
        message: '로그인이 필요합니다.',
        code: 'UNAUTHORIZED',
      );
    }

    try {
      final files = <http.MultipartFile>[];
      for (final filePath in creature.photoFiles) {
        final file = File(filePath);
        if (await file.exists()) {
          files.add(await http.MultipartFile.fromPath('photos', filePath));
        }
      }

      final body = creature.toJson();
      body['owner'] = userId;

      final record = await _client
          .collection(_collection)
          .create(body: body, files: files);

      AppLogger.data('Creature created: ${record.id}');
      return CreatureData.fromJson(record.toJson(), baseUrl: _baseUrl);
    } on ClientException catch (e) {
      AppLogger.data('Failed to create creature: $e', isError: true);
      throw NetworkException.clientError(
        message: '생물 등록에 실패했습니다.',
        statusCode: e.statusCode,
        originalError: e,
      );
    } catch (e) {
      AppLogger.data('Failed to create creature: $e', isError: true);
      throw NetworkException(
        message: '생물 등록 중 오류가 발생했습니다.',
        originalError: e,
      );
    }
  }

  /// 생물 수정
  Future<CreatureData> updateCreature(CreatureData creature) async {
    if (creature.id == null) {
      throw ArgumentError('Creature ID is required for update');
    }

    try {
      // 새 파일 업로드 준비
      final files = <http.MultipartFile>[];
      for (final filePath in creature.photoFiles) {
        final file = File(filePath);
        if (await file.exists()) {
          files.add(await http.MultipartFile.fromPath('photos', filePath));
        }
      }

      final record = await _client
          .collection(_collection)
          .update(creature.id!, body: creature.toJson(), files: files);

      AppLogger.data('Creature updated: ${record.id}');
      return CreatureData.fromJson(record.toJson(), baseUrl: _baseUrl);
    } on ClientException catch (e) {
      AppLogger.data('Failed to update creature: $e', isError: true);
      if (e.statusCode == 404) {
        throw NotFoundException(
          message: '생물을 찾을 수 없습니다.',
          code: 'CREATURE_NOT_FOUND',
          resourceType: 'creature',
          resourceId: creature.id,
        );
      }
      throw NetworkException.clientError(
        message: '생물 수정에 실패했습니다.',
        statusCode: e.statusCode,
        originalError: e,
      );
    } catch (e) {
      AppLogger.data('Failed to update creature: $e', isError: true);
      throw NetworkException(
        message: '생물 수정 중 오류가 발생했습니다.',
        originalError: e,
      );
    }
  }

  /// 생물 삭제
  Future<void> deleteCreature(String id) async {
    try {
      await _client.collection(_collection).delete(id);
      AppLogger.data('Creature deleted: $id');
    } on ClientException catch (e) {
      AppLogger.data('Failed to delete creature: $e', isError: true);
      if (e.statusCode == 404) {
        throw NotFoundException(
          message: '생물을 찾을 수 없습니다.',
          code: 'CREATURE_NOT_FOUND',
          resourceType: 'creature',
          resourceId: id,
        );
      }
      throw NetworkException.clientError(
        message: '생물 삭제에 실패했습니다.',
        statusCode: e.statusCode,
        originalError: e,
      );
    } catch (e) {
      AppLogger.data('Failed to delete creature: $e', isError: true);
      throw NetworkException(
        message: '생물 삭제 중 오류가 발생했습니다.',
        originalError: e,
      );
    }
  }

  /// 생물 사진 추가
  Future<CreatureData> addPhotos(String id, List<String> filePaths) async {
    try {
      final files = <http.MultipartFile>[];
      for (final filePath in filePaths) {
        final file = File(filePath);
        if (await file.exists()) {
          files.add(await http.MultipartFile.fromPath('photos', filePath));
        }
      }

      if (files.isEmpty) {
        throw ArgumentError('No valid files to upload');
      }

      final record = await _client
          .collection(_collection)
          .update(id, files: files);

      AppLogger.data('Photos added to creature: $id');
      return CreatureData.fromJson(record.toJson(), baseUrl: _baseUrl);
    } on ClientException catch (e) {
      AppLogger.data('Failed to add photos: $e', isError: true);
      throw NetworkException.clientError(
        message: '사진 추가에 실패했습니다.',
        statusCode: e.statusCode,
        originalError: e,
      );
    } catch (e) {
      AppLogger.data('Failed to add photos: $e', isError: true);
      throw NetworkException(
        message: '사진 추가 중 오류가 발생했습니다.',
        originalError: e,
      );
    }
  }

  /// 생물 사진 삭제
  Future<CreatureData> removePhoto(String id, String filename) async {
    try {
      final record = await _client
          .collection(_collection)
          .update(id, body: {'photos-': filename});

      AppLogger.data('Photo removed from creature: $id');
      return CreatureData.fromJson(record.toJson(), baseUrl: _baseUrl);
    } on ClientException catch (e) {
      AppLogger.data('Failed to remove photo: $e', isError: true);
      throw NetworkException.clientError(
        message: '사진 삭제에 실패했습니다.',
        statusCode: e.statusCode,
        originalError: e,
      );
    } catch (e) {
      AppLogger.data('Failed to remove photo: $e', isError: true);
      throw NetworkException(
        message: '사진 삭제 중 오류가 발생했습니다.',
        originalError: e,
      );
    }
  }

  /// 어항별 생물 수 조회
  Future<int> getCreatureCount(String aquariumId) async {
    try {
      final result = await _client
          .collection(_collection)
          .getList(
            page: 1,
            perPage: 1,
            filter: PbFilter.eq('aquarium_id', aquariumId),
          );
      return result.totalItems;
    } on ClientException catch (e) {
      AppLogger.data('Failed to get creature count: $e', isError: true);
      return 0;
    } catch (e) {
      AppLogger.data('Failed to get creature count: $e', isError: true);
      return 0;
    }
  }
}
