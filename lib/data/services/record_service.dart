import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'pocketbase_service.dart';
import '../../domain/models/record_data.dart';

/// 기록 관리 서비스
///
/// PocketBase records 컬렉션과 통신
class RecordService {
  RecordService._();

  static RecordService? _instance;
  static RecordService get instance => _instance ??= RecordService._();

  PocketBase get _pb => PocketBaseService.instance.client;

  static const String _collection = 'records';

  /// 기록 목록 조회
  Future<List<RecordData>> getRecords({
    int page = 1,
    int perPage = 20,
    String? filter,
    String sort = '-date',
  }) async {
    try {
      final result = await _pb.collection(_collection).getList(
        page: page,
        perPage: perPage,
        filter: filter,
        sort: sort,
      );

      return result.items.map((record) => _recordToRecordData(record)).toList();
    } catch (e) {
      debugPrint('Failed to get records: $e');
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
      filter: 'aquarium = "$aquariumId"',
      sort: sort,
    );
  }

  /// 특정 날짜의 기록 조회
  Future<List<RecordData>> getRecordsByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final filter = 'date >= "${startOfDay.toIso8601String()}" && date < "${endOfDay.toIso8601String()}"';

    return getRecords(
      filter: filter,
      perPage: 100,
      sort: '-created',
    );
  }

  /// 특정 월의 기록이 있는 날짜 목록 조회
  Future<List<DateTime>> getRecordDatesInMonth(DateTime month) async {
    try {
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

      final filter =
          'date >= "${startOfMonth.toIso8601String()}" && date <= "${endOfMonth.toIso8601String()}"';

      final result = await _pb.collection(_collection).getList(
        page: 1,
        perPage: 100,
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
      debugPrint('Failed to get record dates in month: $e');
      return [];
    }
  }

  /// 특정 기록 조회
  Future<RecordData?> getRecord(String id) async {
    try {
      final record = await _pb.collection(_collection).getOne(id);
      return _recordToRecordData(record);
    } catch (e) {
      debugPrint('Failed to get record: $e');
      return null;
    }
  }

  /// 기록 생성
  Future<RecordData> createRecord(RecordData data) async {
    try {
      final body = data.toJson();

      final record = await _pb.collection(_collection).create(body: body);

      debugPrint('Record created: ${record.id}');
      return _recordToRecordData(record);
    } catch (e) {
      debugPrint('Failed to create record: $e');
      rethrow;
    }
  }

  /// 기록 수정
  Future<RecordData> updateRecord(String id, RecordData data) async {
    try {
      final body = data.toJson();

      final record = await _pb.collection(_collection).update(id, body: body);

      debugPrint('Record updated: ${record.id}');
      return _recordToRecordData(record);
    } catch (e) {
      debugPrint('Failed to update record: $e');
      rethrow;
    }
  }

  /// 기록 삭제
  Future<void> deleteRecord(String id) async {
    try {
      await _pb.collection(_collection).delete(id);
      debugPrint('Record deleted: $id');
    } catch (e) {
      debugPrint('Failed to delete record: $e');
      rethrow;
    }
  }

  /// 기록 개수 조회
  Future<int> getRecordCount({String? filter}) async {
    try {
      final result = await _pb.collection(_collection).getList(
        page: 1,
        perPage: 1,
        filter: filter,
      );
      return result.totalItems;
    } catch (e) {
      debugPrint('Failed to get record count: $e');
      return 0;
    }
  }

  /// RecordModel을 RecordData로 변환
  RecordData _recordToRecordData(RecordModel record) {
    // tags 파싱
    final tagsRaw = record.data['tags'];
    List<RecordTag> tags = [];
    if (tagsRaw is List) {
      tags = tagsRaw
          .map((e) => RecordTag.fromValue(e.toString()))
          .whereType<RecordTag>()
          .toList();
    }

    return RecordData(
      id: record.id,
      aquariumId: record.getStringValue('aquarium'),
      date: DateTime.tryParse(record.getStringValue('date')) ?? DateTime.now(),
      tags: tags,
      content: record.getStringValue('content'),
      isPublic: record.getBoolValue('is_public'),
      created: DateTime.tryParse(record.getStringValue('created')),
      updated: DateTime.tryParse(record.getStringValue('updated')),
    );
  }
}
