import 'package:pocketbase/pocketbase.dart';
import 'pocketbase_service.dart';
import '../../core/utils/app_logger.dart';

/// 팔로우 데이터 모델
class FollowData {
  FollowData({
    this.id,
    required this.followerId,
    required this.followingId,
    this.created,
  });

  String? id;
  String followerId;
  String followingId;
  DateTime? created;

  factory FollowData.fromJson(Map<String, dynamic> json) {
    return FollowData(
      id: json['id'],
      followerId: json['follower'] ?? '',
      followingId: json['following'] ?? '',
      created: DateTime.tryParse(json['created'] ?? ''),
    );
  }
}

/// 팔로우 서비스
///
/// PocketBase follows 컬렉션과 통신
class FollowService {
  FollowService._();

  static FollowService? _instance;
  static FollowService get instance => _instance ??= FollowService._();

  PocketBase get _pb => PocketBaseService.instance.client;

  static const String _collection = 'follows';

  /// 팔로우 토글 (팔로우 ↔ 언팔로우)
  Future<bool> toggleFollow({required String followingId}) async {
    try {
      final result = await _pb.send(
        '/api/community/toggle-follow',
        method: 'POST',
        body: {'following_id': followingId},
      );

      final following =
          (result as Map<String, dynamic>)['following'] as bool? ?? false;
      AppLogger.data('Follow toggled: -> $followingId (following: $following)');
      return following;
    } catch (e) {
      AppLogger.data('Failed to toggle follow: $e', isError: true);
      rethrow;
    }
  }

  /// 팔로우 여부 확인
  Future<bool> isFollowing({
    required String followerId,
    required String followingId,
  }) async {
    try {
      final existing = await _getFollowRecord(followerId, followingId);
      return existing != null;
    } catch (e) {
      AppLogger.data('Failed to check follow status: $e', isError: true);
      return false;
    }
  }

  /// 팔로잉 목록 조회 (내가 팔로우하는 사람들)
  Future<List<String>> getFollowing({
    required String userId,
    int page = 1,
    int perPage = 100,
  }) async {
    try {
      final result = await _pb
          .collection(_collection)
          .getList(
            page: page,
            perPage: perPage,
            filter: 'follower = "$userId"',
            sort: '-created',
          );

      return result.items
          .map((record) => record.getStringValue('following'))
          .toList();
    } catch (e) {
      AppLogger.data('Failed to get following: $e', isError: true);
      return [];
    }
  }

  /// 팔로워 목록 조회 (나를 팔로우하는 사람들)
  Future<List<String>> getFollowers({
    required String userId,
    int page = 1,
    int perPage = 100,
  }) async {
    try {
      final result = await _pb
          .collection(_collection)
          .getList(
            page: page,
            perPage: perPage,
            filter: 'following = "$userId"',
            sort: '-created',
          );

      return result.items
          .map((record) => record.getStringValue('follower'))
          .toList();
    } catch (e) {
      AppLogger.data('Failed to get followers: $e', isError: true);
      return [];
    }
  }

  /// 팔로잉 수 조회
  Future<int> getFollowingCount(String userId) async {
    try {
      final result = await _pb
          .collection(_collection)
          .getList(page: 1, perPage: 1, filter: 'follower = "$userId"');
      return result.totalItems;
    } catch (e) {
      AppLogger.data('Failed to get following count: $e', isError: true);
      return 0;
    }
  }

  /// 팔로워 수 조회
  Future<int> getFollowersCount(String userId) async {
    try {
      final result = await _pb
          .collection(_collection)
          .getList(page: 1, perPage: 1, filter: 'following = "$userId"');
      return result.totalItems;
    } catch (e) {
      AppLogger.data('Failed to get followers count: $e', isError: true);
      return 0;
    }
  }

  // ==================== Helpers ====================

  /// 팔로우 레코드 조회
  Future<FollowData?> _getFollowRecord(
    String followerId,
    String followingId,
  ) async {
    try {
      final result = await _pb
          .collection(_collection)
          .getList(
            page: 1,
            perPage: 1,
            filter: 'follower = "$followerId" && following = "$followingId"',
          );

      if (result.items.isNotEmpty) {
        final record = result.items.first;
        return FollowData.fromJson({
          'id': record.id,
          'follower': record.getStringValue('follower'),
          'following': record.getStringValue('following'),
          'created': record.getStringValue('created'),
        });
      }
      return null;
    } catch (e) {
      AppLogger.data('Failed to get follow record: $e', isError: true);
      return null;
    }
  }
}
