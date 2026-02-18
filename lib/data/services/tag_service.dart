import 'package:pocketbase/pocketbase.dart';
import 'pocketbase_service.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/pb_filter.dart';

/// 태그 데이터 모델
class TagData {
  TagData({
    this.id,
    required this.name,
    this.usageCount = 0,
    this.category,
    this.created,
  });

  String? id;
  String name;
  int usageCount;
  String? category;
  DateTime? created;

  factory TagData.fromJson(Map<String, dynamic> json) {
    return TagData(
      id: json['id'],
      name: json['name'] ?? '',
      usageCount: json['usage_count'] ?? 0,
      category: json['category'],
      created: DateTime.tryParse(json['created'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'usage_count': usageCount, 'category': category};
  }
}

/// 태그 서비스
///
/// PocketBase tags 컬렉션과 통신
class TagService {
  TagService._();

  static TagService? _instance;
  static TagService get instance => _instance ??= TagService._();

  PocketBase get _pb => PocketBaseService.instance.client;

  static const String _collection = 'tags';

  /// 인기 태그 조회
  Future<List<TagData>> getPopularTags({
    int limit = 10,
    String? category,
  }) async {
    try {
      String filter = '';
      if (category != null && category.isNotEmpty) {
        filter = PbFilter.eq('category', category);
      }

      final result = await _pb
          .collection(_collection)
          .getList(
            page: 1,
            perPage: limit,
            filter: filter,
            sort: '-usage_count',
          );

      return result.items.map((record) => _recordToTagData(record)).toList();
    } catch (e) {
      AppLogger.data('Failed to get popular tags: $e', isError: true);
      return [];
    }
  }

  /// 태그 검색
  Future<List<TagData>> searchTags({
    required String query,
    int limit = 20,
  }) async {
    try {
      final result = await _pb
          .collection(_collection)
          .getList(
            page: 1,
            perPage: limit,
            filter: 'name ~ "${PbFilter.sanitize(query)}"',
            sort: '-usage_count',
          );

      return result.items.map((record) => _recordToTagData(record)).toList();
    } catch (e) {
      AppLogger.data('Failed to search tags: $e', isError: true);
      return [];
    }
  }

  /// 태그 조회 (이름으로)
  Future<TagData?> getTagByName(String name) async {
    try {
      final result = await _pb
          .collection(_collection)
          .getList(page: 1, perPage: 1, filter: PbFilter.eq('name', name));

      if (result.items.isNotEmpty) {
        return _recordToTagData(result.items.first);
      }
      return null;
    } catch (e) {
      AppLogger.data('Failed to get tag by name: $e', isError: true);
      return null;
    }
  }

  /// 태그 생성 또는 사용량 증가
  Future<TagData> getOrCreateTag({
    required String name,
    String? category,
  }) async {
    try {
      // 기존 태그 확인
      final existing = await getTagByName(name);

      if (existing != null) {
        // 사용량 증가
        await incrementUsageCount(existing.id!);
        return existing.copyWith(usageCount: existing.usageCount + 1);
      }

      // 새 태그 생성
      final record = await _pb
          .collection(_collection)
          .create(body: {'name': name, 'usage_count': 1, 'category': category});

      AppLogger.data('Tag created: $name');
      return _recordToTagData(record);
    } catch (e) {
      AppLogger.data('Failed to get or create tag: $e', isError: true);
      rethrow;
    }
  }

  /// 사용량 증가
  Future<void> incrementUsageCount(String id) async {
    try {
      final record = await _pb.collection(_collection).getOne(id);
      final currentCount = record.getIntValue('usage_count');
      await _pb
          .collection(_collection)
          .update(id, body: {'usage_count': currentCount + 1});
    } catch (e) {
      AppLogger.data('Failed to increment usage count: $e', isError: true);
    }
  }

  /// 사용량 감소
  Future<void> decrementUsageCount(String id) async {
    try {
      final record = await _pb.collection(_collection).getOne(id);
      final currentCount = record.getIntValue('usage_count');
      await _pb
          .collection(_collection)
          .update(
            id,
            body: {'usage_count': currentCount > 0 ? currentCount - 1 : 0},
          );
    } catch (e) {
      AppLogger.data('Failed to decrement usage count: $e', isError: true);
    }
  }

  /// 모든 태그 조회
  Future<List<TagData>> getAllTags({
    int page = 1,
    int perPage = 100,
    String? sort,
  }) async {
    try {
      final result = await _pb
          .collection(_collection)
          .getList(page: page, perPage: perPage, sort: sort ?? 'name');

      return result.items.map((record) => _recordToTagData(record)).toList();
    } catch (e) {
      AppLogger.data('Failed to get all tags: $e', isError: true);
      return [];
    }
  }

  // ==================== Helpers ====================

  /// RecordModel을 TagData로 변환
  TagData _recordToTagData(RecordModel record) {
    return TagData.fromJson({
      'id': record.id,
      'name': record.getStringValue('name'),
      'usage_count': record.getIntValue('usage_count'),
      'category': record.data['category'],
      'created': record.getStringValue('created'),
    });
  }
}

/// TagData extension for copyWith
extension TagDataCopyWith on TagData {
  TagData copyWith({
    String? id,
    String? name,
    int? usageCount,
    String? category,
    DateTime? created,
  }) {
    return TagData(
      id: id ?? this.id,
      name: name ?? this.name,
      usageCount: usageCount ?? this.usageCount,
      category: category ?? this.category,
      created: created ?? this.created,
    );
  }
}
