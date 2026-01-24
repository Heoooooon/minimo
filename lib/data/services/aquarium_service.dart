import 'package:pocketbase/pocketbase.dart';
import 'package:http/http.dart' as http;
import 'pocketbase_service.dart';
import 'auth_service.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../../core/utils/app_logger.dart';
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
    String? sort,
  }) async {
    try {
      final result = await _pb
          .collection(_collection)
          .getList(
            page: page,
            perPage: perPage,
            filter: filter,
            sort: (sort != null && sort.isNotEmpty) ? sort : null,
          );

      return result.items
          .map((record) => _recordToAquariumData(record))
          .toList();
    } on ClientException catch (e) {
      AppLogger.data('Failed to get aquariums: $e', isError: true);
      throw NetworkException.clientError(
        message: '어항 목록을 불러오는데 실패했습니다.',
        statusCode: e.statusCode,
        originalError: e,
      );
    } catch (e) {
      AppLogger.data('Failed to get aquariums: $e', isError: true);
      throw NetworkException(
        message: '어항 목록 조회 중 오류가 발생했습니다.',
        originalError: e,
      );
    }
  }

  /// 모든 어항 전체 목록 조회
  Future<List<AquariumData>> getAllAquariums({String? sort}) async {
    try {
      final records = await _pb
          .collection(_collection)
          .getFullList(sort: (sort != null && sort.isNotEmpty) ? sort : null);

      return records.map((record) => _recordToAquariumData(record)).toList();
    } on ClientException catch (e) {
      AppLogger.data('Failed to get all aquariums: $e', isError: true);
      throw NetworkException.clientError(
        message: '어항 목록을 불러오는데 실패했습니다.',
        statusCode: e.statusCode,
        originalError: e,
      );
    } catch (e) {
      AppLogger.data('Failed to get all aquariums: $e', isError: true);
      throw NetworkException(
        message: '어항 목록 조회 중 오류가 발생했습니다.',
        originalError: e,
      );
    }
  }

  /// 특정 어항 조회
  Future<AquariumData?> getAquarium(String id) async {
    try {
      final record = await _pb.collection(_collection).getOne(id);
      return _recordToAquariumData(record);
    } on ClientException catch (e) {
      AppLogger.data('Failed to get aquarium: $e', isError: true);
      if (e.statusCode == 404) {
        throw NotFoundException.aquarium(id);
      }
      throw NetworkException.clientError(
        message: '어항을 불러오는데 실패했습니다.',
        statusCode: e.statusCode,
        originalError: e,
      );
    } catch (e) {
      AppLogger.data('Failed to get aquarium: $e', isError: true);
      throw NetworkException(message: '어항 조회 중 오류가 발생했습니다.', originalError: e);
    }
  }

  /// 어항 개수 조회
  Future<int> getAquariumCount({String? filter}) async {
    try {
      final result = await _pb
          .collection(_collection)
          .getList(page: 1, perPage: 1, filter: filter);
      return result.totalItems;
    } catch (e) {
      AppLogger.data('Failed to get aquarium count: $e', isError: true);
      return 0;
    }
  }

  Future<AquariumData> createAquarium(AquariumData aquarium) async {
    if (aquarium.name == null || aquarium.name!.isEmpty) {
      throw ValidationException.required('어항 이름');
    }

    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) {
      throw AuthException(message: '로그인이 필요합니다.');
    }

    try {
      final body = aquarium.toJson();
      body['owner'] = userId;

      RecordModel record;

      if (aquarium.photoPath != null && aquarium.photoPath!.isNotEmpty) {
        // 사진이 있는 경우 멀티파트로 업로드
        final file = await http.MultipartFile.fromPath(
          'photo',
          aquarium.photoPath!,
        );
        record = await _pb
            .collection(_collection)
            .create(body: body, files: [file]);
      } else {
        record = await _pb.collection(_collection).create(body: body);
      }

      AppLogger.data('Aquarium created: ${record.id}');
      return _recordToAquariumData(record);
    } on ClientException catch (e) {
      AppLogger.data('Failed to create aquarium: $e', isError: true);
      throw NetworkException.clientError(
        message: '어항 등록에 실패했습니다.',
        statusCode: e.statusCode,
        originalError: e,
      );
    } catch (e) {
      AppLogger.data('Failed to create aquarium: $e', isError: true);
      throw NetworkException(message: '어항 등록 중 오류가 발생했습니다.', originalError: e);
    }
  }

  /// 어항 수정
  Future<AquariumData> updateAquarium(String id, AquariumData aquarium) async {
    try {
      final body = aquarium.toJson();

      RecordModel record;

      if (aquarium.photoPath != null && aquarium.photoPath!.isNotEmpty) {
        final file = await http.MultipartFile.fromPath(
          'photo',
          aquarium.photoPath!,
        );
        record = await _pb
            .collection(_collection)
            .update(id, body: body, files: [file]);
      } else {
        record = await _pb.collection(_collection).update(id, body: body);
      }

      AppLogger.data('Aquarium updated: ${record.id}');
      return _recordToAquariumData(record);
    } on ClientException catch (e) {
      AppLogger.data('Failed to update aquarium: $e', isError: true);
      if (e.statusCode == 404) {
        throw NotFoundException.aquarium(id);
      }
      throw NetworkException.clientError(
        message: '어항 수정에 실패했습니다.',
        statusCode: e.statusCode,
        originalError: e,
      );
    } catch (e) {
      AppLogger.data('Failed to update aquarium: $e', isError: true);
      throw NetworkException(message: '어항 수정 중 오류가 발생했습니다.', originalError: e);
    }
  }

  /// 어항 삭제
  Future<void> deleteAquarium(String id) async {
    try {
      await _pb.collection(_collection).delete(id);
      AppLogger.data('Aquarium deleted: $id');
    } on ClientException catch (e) {
      AppLogger.data('Failed to delete aquarium: $e', isError: true);
      if (e.statusCode == 404) {
        throw NotFoundException.aquarium(id);
      }
      throw NetworkException.clientError(
        message: '어항 삭제에 실패했습니다.',
        statusCode: e.statusCode,
        originalError: e,
      );
    } catch (e) {
      AppLogger.data('Failed to delete aquarium: $e', isError: true);
      throw NetworkException(message: '어항 삭제 중 오류가 발생했습니다.', originalError: e);
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
