import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import '../../domain/models/record_data.dart';
import '../services/pocketbase_service.dart';

/// 기록 Repository
class RecordRepository {
  RecordRepository._();

  static RecordRepository? _instance;
  static RecordRepository get instance => _instance ??= RecordRepository._();

  static const String _collectionName = 'records';

  PocketBase get _pb => PocketBaseService.instance.client;

  /// 기록 목록 조회
  Future<List<RecordData>> getRecords({
    int page = 1,
    int perPage = 20,
    String? filter,
    String sort = '-date',
  }) async {
    try {
      final result = await _pb
          .collection(_collectionName)
          .getList(page: page, perPage: perPage, filter: filter, sort: sort);

      return result.items
          .map((record) => RecordData.fromJson(record.toJson()))
          .toList();
    } catch (e) {
      debugPrint('Error fetching records: $e');
      rethrow;
    }
  }

  /// 기록 생성
  Future<RecordData> createRecord(RecordData data) async {
    try {
      final record = await _pb
          .collection(_collectionName)
          .create(body: data.toJson());
      return RecordData.fromJson(record.toJson());
    } catch (e) {
      debugPrint('Error creating record: $e');
      rethrow;
    }
  }

  /// 기록 삭제
  Future<void> deleteRecord(String id) async {
    try {
      await _pb.collection(_collectionName).delete(id);
    } catch (e) {
      debugPrint('Error deleting record: $e');
      rethrow;
    }
  }
}
