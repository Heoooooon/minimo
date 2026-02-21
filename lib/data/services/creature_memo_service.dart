import 'package:pocketbase/pocketbase.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/pb_filter.dart';
import '../../domain/models/creature_data.dart';
import 'pocketbase_service.dart';

/// 생물 메모 관리 서비스
///
/// PocketBase creature_memos 컬렉션 CRUD
class CreatureMemoService {
  CreatureMemoService._();

  static CreatureMemoService? _instance;
  static CreatureMemoService get instance =>
      _instance ??= CreatureMemoService._();

  PocketBase get _client => PocketBaseService.instance.client;

  static const String _collection = 'creature_memos';

  /// 생물별 메모 목록 조회
  Future<List<CreatureMemoData>> getMemosByCreature(String creatureId) async {
    try {
      final records = await _client
          .collection(_collection)
          .getFullList(filter: PbFilter.eq('creature_id', creatureId));

      return records.map((r) => CreatureMemoData.fromJson(r.toJson())).toList();
    } on ClientException catch (e) {
      AppLogger.data('Failed to get memos: $e', isError: true);
      throw NetworkException.clientError(
        message: '메모 목록을 불러오는데 실패했습니다.',
        statusCode: e.statusCode,
        originalError: e,
      );
    } catch (e) {
      AppLogger.data('Failed to get memos: $e', isError: true);
      throw NetworkException(message: '메모 목록 조회 중 오류가 발생했습니다.', originalError: e);
    }
  }

  /// 메모 상세 조회
  Future<CreatureMemoData> getMemo(String id) async {
    try {
      final record = await _client.collection(_collection).getOne(id);
      return CreatureMemoData.fromJson(record.toJson());
    } on ClientException catch (e) {
      AppLogger.data('Failed to get memo: $e', isError: true);
      throw NetworkException.clientError(
        message: '메모를 불러오는데 실패했습니다.',
        statusCode: e.statusCode,
        originalError: e,
      );
    } catch (e) {
      AppLogger.data('Failed to get memo: $e', isError: true);
      throw NetworkException(message: '메모 조회 중 오류가 발생했습니다.', originalError: e);
    }
  }

  /// 메모 추가
  Future<CreatureMemoData> createMemo(CreatureMemoData memo) async {
    try {
      final record = await _client
          .collection(_collection)
          .create(body: memo.toJson());

      return CreatureMemoData.fromJson(record.toJson());
    } on ClientException catch (e) {
      AppLogger.data('Failed to create memo: $e', isError: true);
      throw NetworkException.clientError(
        message: '메모 등록에 실패했습니다.',
        statusCode: e.statusCode,
        originalError: e,
      );
    } catch (e) {
      AppLogger.data('Failed to create memo: $e', isError: true);
      throw NetworkException(message: '메모 등록 중 오류가 발생했습니다.', originalError: e);
    }
  }

  /// 메모 수정
  Future<CreatureMemoData> updateMemo(CreatureMemoData memo) async {
    if (memo.id == null) {
      throw ArgumentError('Memo ID is required for update');
    }

    try {
      final record = await _client
          .collection(_collection)
          .update(memo.id!, body: memo.toJson());

      return CreatureMemoData.fromJson(record.toJson());
    } on ClientException catch (e) {
      AppLogger.data('Failed to update memo: $e', isError: true);
      throw NetworkException.clientError(
        message: '메모 수정에 실패했습니다.',
        statusCode: e.statusCode,
        originalError: e,
      );
    } catch (e) {
      AppLogger.data('Failed to update memo: $e', isError: true);
      throw NetworkException(message: '메모 수정 중 오류가 발생했습니다.', originalError: e);
    }
  }

  /// 메모 삭제
  Future<void> deleteMemo(String id) async {
    try {
      await _client.collection(_collection).delete(id);
    } on ClientException catch (e) {
      AppLogger.data('Failed to delete memo: $e', isError: true);
      throw NetworkException.clientError(
        message: '메모 삭제에 실패했습니다.',
        statusCode: e.statusCode,
        originalError: e,
      );
    } catch (e) {
      AppLogger.data('Failed to delete memo: $e', isError: true);
      throw NetworkException(message: '메모 삭제 중 오류가 발생했습니다.', originalError: e);
    }
  }

  /// 생물별 메모 수 조회
  Future<int> getMemoCount(String creatureId) async {
    try {
      final result = await _client
          .collection(_collection)
          .getList(page: 1, perPage: 1, filter: PbFilter.eq('creature_id', creatureId));
      return result.totalItems;
    } catch (e) {
      AppLogger.data('Failed to get memo count: $e', isError: true);
      return 0;
    }
  }
}
