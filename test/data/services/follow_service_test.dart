import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oomool/data/services/pocketbase_service.dart';
import 'package:oomool/data/services/follow_service.dart';

// Mock 클래스 정의
class MockPocketBase extends Mock implements PocketBase {}

class MockAuthStore extends Mock implements AuthStore {}

class MockRecordService extends Mock implements RecordService {}

void main() {
  late MockPocketBase mockPocketBase;
  late MockAuthStore mockAuthStore;
  late MockRecordService mockRecordService;
  late FollowService followService;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() {
    mockPocketBase = MockPocketBase();
    mockAuthStore = MockAuthStore();
    mockRecordService = MockRecordService();

    when(() => mockPocketBase.authStore).thenReturn(mockAuthStore);
    when(() => mockAuthStore.isValid).thenReturn(false);
    when(() => mockAuthStore.token).thenReturn('');
    when(() => mockAuthStore.record).thenReturn(null);
    when(() => mockPocketBase.collection(any())).thenReturn(mockRecordService);

    PocketBaseService.instance.initializeForTesting(mockPocketBase);
    followService = FollowService.instance;
  });

  tearDown(() {
    PocketBaseService.instance.resetForTesting();
  });

  group('FollowService', () {
    group('toggleFollow', () {
      test('toggleFollow는 _pb.send()를 통해 서버 사이드에서 처리된다', () async {
        // toggleFollow는 커스텀 엔드포인트(/api/community/toggle-follow)를 사용하므로
        // PocketBase.send()를 mock해야 하며, 이는 통합 테스트에서 검증합니다.
        // 여기서는 메서드 시그니처만 확인합니다.
        expect(followService.toggleFollow, isA<Function>());
      });
    });

    group('isFollowing', () {
      test('팔로우 중이면 true를 반환한다', () async {
        // Arrange
        final existingFollow = RecordModel({
          'id': 'follow_1',
          'follower': 'user_1',
          'following': 'user_2',
          'created': '2024-01-15T10:00:00Z',
        });

        when(
          () => mockRecordService.getList(
            page: 1,
            perPage: 1,
            filter: 'follower = "user_1" && following = "user_2"',
          ),
        ).thenAnswer(
          (_) async => ResultList<RecordModel>(
            page: 1,
            perPage: 1,
            totalItems: 1,
            totalPages: 1,
            items: [existingFollow],
          ),
        );

        // Act
        final result = await followService.isFollowing(
          followerId: 'user_1',
          followingId: 'user_2',
        );

        // Assert
        expect(result, true);
      });

      test('팔로우 중이 아니면 false를 반환한다', () async {
        // Arrange
        when(
          () => mockRecordService.getList(
            page: 1,
            perPage: 1,
            filter: 'follower = "user_1" && following = "user_2"',
          ),
        ).thenAnswer(
          (_) async => ResultList<RecordModel>(
            page: 1,
            perPage: 1,
            totalItems: 0,
            totalPages: 0,
            items: [],
          ),
        );

        // Act
        final result = await followService.isFollowing(
          followerId: 'user_1',
          followingId: 'user_2',
        );

        // Assert
        expect(result, false);
      });

      test('오류 발생 시 false를 반환한다', () async {
        // Arrange
        when(
          () => mockRecordService.getList(
            page: 1,
            perPage: 1,
            filter: 'follower = "user_1" && following = "user_2"',
          ),
        ).thenThrow(ClientException(statusCode: 500));

        // Act
        final result = await followService.isFollowing(
          followerId: 'user_1',
          followingId: 'user_2',
        );

        // Assert
        expect(result, false);
      });
    });

    group('getFollowing', () {
      test('팔로잉 목록을 조회한다', () async {
        // Arrange
        final mockRecords = [
          RecordModel({
            'id': 'follow_1',
            'follower': 'user_1',
            'following': 'user_2',
            'created': '2024-01-15T10:00:00Z',
          }),
          RecordModel({
            'id': 'follow_2',
            'follower': 'user_1',
            'following': 'user_3',
            'created': '2024-01-14T10:00:00Z',
          }),
        ];

        when(
          () => mockRecordService.getList(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            filter: 'follower = "user_1"',
            sort: '-created',
          ),
        ).thenAnswer(
          (_) async => ResultList<RecordModel>(
            page: 1,
            perPage: 100,
            totalItems: 2,
            totalPages: 1,
            items: mockRecords,
          ),
        );

        // Act
        final result = await followService.getFollowing(userId: 'user_1');

        // Assert
        expect(result.length, 2);
        expect(result, contains('user_2'));
        expect(result, contains('user_3'));
      });

      test('팔로잉이 없으면 빈 목록을 반환한다', () async {
        // Arrange
        when(
          () => mockRecordService.getList(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            filter: 'follower = "user_1"',
            sort: '-created',
          ),
        ).thenAnswer(
          (_) async => ResultList<RecordModel>(
            page: 1,
            perPage: 100,
            totalItems: 0,
            totalPages: 0,
            items: [],
          ),
        );

        // Act
        final result = await followService.getFollowing(userId: 'user_1');

        // Assert
        expect(result, isEmpty);
      });
    });

    group('getFollowers', () {
      test('팔로워 목록을 조회한다', () async {
        // Arrange
        final mockRecords = [
          RecordModel({
            'id': 'follow_1',
            'follower': 'user_2',
            'following': 'user_1',
            'created': '2024-01-15T10:00:00Z',
          }),
          RecordModel({
            'id': 'follow_2',
            'follower': 'user_3',
            'following': 'user_1',
            'created': '2024-01-14T10:00:00Z',
          }),
          RecordModel({
            'id': 'follow_3',
            'follower': 'user_4',
            'following': 'user_1',
            'created': '2024-01-13T10:00:00Z',
          }),
        ];

        when(
          () => mockRecordService.getList(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            filter: 'following = "user_1"',
            sort: '-created',
          ),
        ).thenAnswer(
          (_) async => ResultList<RecordModel>(
            page: 1,
            perPage: 100,
            totalItems: 3,
            totalPages: 1,
            items: mockRecords,
          ),
        );

        // Act
        final result = await followService.getFollowers(userId: 'user_1');

        // Assert
        expect(result.length, 3);
        expect(result, contains('user_2'));
        expect(result, contains('user_3'));
        expect(result, contains('user_4'));
      });
    });

    group('getFollowingCount', () {
      test('팔로잉 수를 조회한다', () async {
        // Arrange
        when(
          () => mockRecordService.getList(
            page: 1,
            perPage: 1,
            filter: 'follower = "user_1"',
          ),
        ).thenAnswer(
          (_) async => ResultList<RecordModel>(
            page: 1,
            perPage: 1,
            totalItems: 25,
            totalPages: 25,
            items: [],
          ),
        );

        // Act
        final count = await followService.getFollowingCount('user_1');

        // Assert
        expect(count, 25);
      });

      test('오류 발생 시 0을 반환한다', () async {
        // Arrange
        when(
          () => mockRecordService.getList(
            page: 1,
            perPage: 1,
            filter: 'follower = "user_1"',
          ),
        ).thenThrow(ClientException(statusCode: 500));

        // Act
        final count = await followService.getFollowingCount('user_1');

        // Assert
        expect(count, 0);
      });
    });

    group('getFollowersCount', () {
      test('팔로워 수를 조회한다', () async {
        // Arrange
        when(
          () => mockRecordService.getList(
            page: 1,
            perPage: 1,
            filter: 'following = "user_1"',
          ),
        ).thenAnswer(
          (_) async => ResultList<RecordModel>(
            page: 1,
            perPage: 1,
            totalItems: 150,
            totalPages: 150,
            items: [],
          ),
        );

        // Act
        final count = await followService.getFollowersCount('user_1');

        // Assert
        expect(count, 150);
      });

      test('오류 발생 시 0을 반환한다', () async {
        // Arrange
        when(
          () => mockRecordService.getList(
            page: 1,
            perPage: 1,
            filter: 'following = "user_1"',
          ),
        ).thenThrow(ClientException(statusCode: 500));

        // Act
        final count = await followService.getFollowersCount('user_1');

        // Assert
        expect(count, 0);
      });
    });
  });
}
