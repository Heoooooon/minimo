import 'package:pocketbase/pocketbase.dart';
import 'pocketbase_service.dart';
import '../../domain/models/record_data.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/pb_filter.dart';

/// 기록 관리 서비스
///
/// PocketBase records 컬렉션과 통신
class RecordService {
  RecordService._();

  static RecordService? _instance;
  static RecordService get instance => _instance ??= RecordService._();

  PocketBase get _pb => PocketBaseService.instance.client;

  static const String _collection = 'records';
  static const int _dailyMaxRecords = 200;
  static const int _monthlyMaxRecords = 500;

  String? get _currentUserId => _pb.authStore.record?.id;

  /// 기록 목록 조회
  Future<List<RecordData>> getRecords({
    int page = 1,
    int perPage = 20,
    String? filter,
    String sort = '-date',
  }) async {
    try {
      final result = await _pb
          .collection(_collection)
          .getList(page: page, perPage: perPage, filter: filter, sort: sort);

      return result.items.map((record) => _recordToRecordData(record)).toList();
    } catch (e) {
      AppLogger.data('Failed to get records: $e', isError: true);
      rethrow;
    }
  }

  /// 특정 어항의 기록 조회
  Future<List<RecordData>> getRecordsByAquarium(
    String aquariumId, {
    int page = 1,
    int perPage = 20,
    String sort = '-date',
  }) async {
    return getRecords(
      page: page,
      perPage: perPage,
      filter: PbFilter.eq('aquarium', aquariumId),
      sort: sort,
    );
  }

  /// 특정 날짜의 기록 조회
  Future<List<RecordData>> getRecordsByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final filter = PbFilter.dateRange('date', startOfDay, endOfDay);

    return getRecords(filter: filter, perPage: _dailyMaxRecords, sort: '-date');
  }

  /// 특정 날짜와 어항의 기록 조회
  Future<List<RecordData>> getRecordsByDateAndAquarium(
    DateTime date,
    String? aquariumId,
  ) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    String filter = PbFilter.dateRange('date', startOfDay, endOfDay);

    if (aquariumId != null && aquariumId.isNotEmpty) {
      filter += ' && ${PbFilter.eq('aquarium', aquariumId)}';
    }

    return getRecords(filter: filter, perPage: _dailyMaxRecords, sort: '-date');
  }

  /// 특정 날짜 + 어항 + 생물 + 타입별 기록 조회
  Future<List<RecordData>> getRecordsByDateAquariumAndCreature(
    DateTime date,
    String? aquariumId, {
    String? creatureId,
    String? recordType,
  }) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    String filter = PbFilter.dateRange('date', startOfDay, endOfDay);

    if (aquariumId != null && aquariumId.isNotEmpty) {
      filter += ' && ${PbFilter.eq('aquarium', aquariumId)}';
    }

    if (creatureId != null && creatureId.isNotEmpty) {
      filter += ' && ${PbFilter.eq('creature', creatureId)}';
    }

    if (recordType != null && recordType.isNotEmpty) {
      filter += ' && ${PbFilter.eq('record_type', recordType)}';
    }

    return getRecords(filter: filter, perPage: _dailyMaxRecords, sort: '-date');
  }

  /// 기록 완료 상태 업데이트
  Future<void> updateRecordCompletion(String id, bool isCompleted) async {
    try {
      await _pb
          .collection(_collection)
          .update(id, body: {'is_completed': isCompleted});
      AppLogger.data('Record completion updated: $id -> $isCompleted');
    } catch (e) {
      AppLogger.data('Failed to update record completion: $e', isError: true);
      rethrow;
    }
  }

  /// 특정 월의 기록이 있는 날짜 목록 조회
  Future<List<DateTime>> getRecordDatesInMonth(DateTime month) async {
    try {
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

      final filter = PbFilter.dateRange(
        'date',
        startOfMonth,
        endOfMonth.add(const Duration(seconds: 1)),
      );
      // endOfMonth에 1초 추가하여 <= 효과 달성 (dateRange는 < 연산)

      final result = await _pb
          .collection(_collection)
          .getList(
            page: 1,
            perPage: _monthlyMaxRecords,
            filter: filter,
            sort: 'date',
          );

      // 날짜만 추출하고 중복 제거
      final dates = <DateTime>{};
      for (final record in result.items) {
        final dateStr = record.getStringValue('date');
        final date = DateTime.tryParse(dateStr);
        if (date != null) {
          dates.add(DateTime(date.year, date.month, date.day));
        }
      }

      return dates.toList()..sort();
    } catch (e) {
      AppLogger.data('Failed to get record dates in month: $e', isError: true);
      return [];
    }
  }

  /// 특정 기록 조회
  Future<RecordData?> getRecord(String id) async {
    try {
      final record = await _pb.collection(_collection).getOne(id);
      return _recordToRecordData(record);
    } catch (e) {
      AppLogger.data('Failed to get record: $e', isError: true);
      return null;
    }
  }

  Future<RecordData> createRecord(RecordData data) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('로그인이 필요합니다.');
    }

    try {
      final body = data.toJson();
      body['owner'] = userId;

      final record = await _pb.collection(_collection).create(body: body);

      AppLogger.data('Record created: ${record.id}');
      return _recordToRecordData(record);
    } catch (e) {
      AppLogger.data('Failed to create record: $e', isError: true);
      rethrow;
    }
  }

  /// 기록 수정
  Future<RecordData> updateRecord(String id, RecordData data) async {
    try {
      final body = data.toJson();

      final record = await _pb.collection(_collection).update(id, body: body);

      AppLogger.data('Record updated: ${record.id}');
      return _recordToRecordData(record);
    } catch (e) {
      AppLogger.data('Failed to update record: $e', isError: true);
      rethrow;
    }
  }

  /// 기록 삭제
  Future<void> deleteRecord(String id) async {
    try {
      await _pb.collection(_collection).delete(id);
      AppLogger.data('Record deleted: $id');
    } catch (e) {
      AppLogger.data('Failed to delete record: $e', isError: true);
      rethrow;
    }
  }

  /// 기록 개수 조회
  Future<int> getRecordCount({String? filter}) async {
    try {
      final result = await _pb
          .collection(_collection)
          .getList(page: 1, perPage: 1, filter: filter);
      return result.totalItems;
    } catch (e) {
      AppLogger.data('Failed to get record count: $e', isError: true);
      return 0;
    }
  }

  RecordData _recordToRecordData(RecordModel record) {
    final tagsRaw = record.data['tags'];
    List<RecordTag> tags = [];
    if (tagsRaw is List) {
      tags = tagsRaw
          .map((e) => RecordTag.fromValue(e.toString()))
          .whereType<RecordTag>()
          .toList();
    }

    final creatureRaw = record.getStringValue('creature');
    final recordTypeRaw = record.getStringValue('record_type');

    return RecordData(
      id: record.id,
      ownerId: record.getStringValue('owner'),
      aquariumId: record.getStringValue('aquarium'),
      creatureId: creatureRaw.isNotEmpty ? creatureRaw : null,
      recordType: RecordType.fromValue(
        recordTypeRaw.isNotEmpty ? recordTypeRaw : null,
      ),
      date: DateTime.tryParse(record.getStringValue('date')) ?? DateTime.now(),
      tags: tags,
      content: record.getStringValue('content'),
      isPublic: record.getBoolValue('is_public'),
      isCompleted: record.getBoolValue('is_completed'),
      created: DateTime.tryParse(record.getStringValue('created')),
      updated: DateTime.tryParse(record.getStringValue('updated')),
    );
  }
}
