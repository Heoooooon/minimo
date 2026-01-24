import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oomool/data/services/pocketbase_service.dart';
import 'package:oomool/presentation/viewmodels/community_viewmodel.dart';

// Mock 클래스 정의
class MockPocketBase extends Mock implements PocketBase {}

class MockAuthStore extends Mock implements AuthStore {}

class MockRecordService extends Mock implements RecordService {}

class MockFileService extends Mock implements FileService {}

void main() {
  late MockPocketBase mockPocketBase;
  late MockAuthStore mockAuthStore;
  late MockRecordService mockRecordService;
  late MockFileService mockFileService;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    registerFallbackValue(Uri());
  });

  setUp(() {
    mockPocketBase = MockPocketBase();
    mockAuthStore = MockAuthStore();
    mockRecordService = MockRecordService();
    mockFileService = MockFileService();

    when(() => mockPocketBase.authStore).thenReturn(mockAuthStore);
    when(() => mockAuthStore.isValid).thenReturn(false);
    when(() => mockAuthStore.token).thenReturn('');
    when(() => mockAuthStore.record).thenReturn(null);
    when(() => mockPocketBase.collection(any())).thenReturn(mockRecordService);
    when(() => mockPocketBase.files).thenReturn(mockFileService);

    PocketBaseService.instance.initializeForTesting(mockPocketBase);
  });

  tearDown(() {
    PocketBaseService.instance.resetForTesting();
  });

  group('CommunityViewModel', () {
    group('초기화', () {
      test('초기 상태가 올바르게 설정된다', () async {
        // Arrange: Mock 설정 (getPosts, getPopularTags)
        when(
          () => mockRecordService.getList(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            filter: any(named: 'filter'),
            sort: any(named: 'sort'),
          ),
        ).thenAnswer(
          (_) async => ResultList<RecordModel>(
            page: 1,
            perPage: 20,
            totalItems: 0,
            totalPages: 0,
            items: [],
          ),
        );

        // Act
        final viewModel = CommunityViewModel();

        // 비동기 초기화 대기
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(viewModel.latestPosts, isEmpty);
        expect(viewModel.followingPosts, isEmpty);
        expect(viewModel.isFilteringByTag, false);
        expect(viewModel.selectedTag, isNull);
      });
    });

    group('loadRecommendTab', () {
      test('추천 탭 데이터를 로드한다', () async {
        // Arrange
        final mockPosts = [
          RecordModel({
            'id': 'post_1',
            'author_id': 'user_1',
            'author_name': '물생활러',
            'author_image': '',
            'content': '오늘 구피 새끼가 태어났어요! 너무 귀엽습니다.',
            'image': '',
            'tags': ['구피', '번식'],
            'like_count': 15,
            'comment_count': 3,
            'bookmark_count': 2,
            'created': '2024-01-15T10:00:00Z',
          }),
          RecordModel({
            'id': 'post_2',
            'author_id': 'user_2',
            'author_name': '베타마스터',
            'author_image': '',
            'content': '베타 어항 세팅 완료!',
            'image': '',
            'tags': ['베타', '어항'],
            'like_count': 20,
            'comment_count': 5,
            'bookmark_count': 3,
            'created': '2024-01-14T10:00:00Z',
          }),
        ];

        when(
          () => mockRecordService.getList(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            filter: any(named: 'filter'),
            sort: any(named: 'sort'),
          ),
        ).thenAnswer(
          (_) async => ResultList<RecordModel>(
            page: 1,
            perPage: 10,
            totalItems: 2,
            totalPages: 1,
            items: mockPosts,
          ),
        );

        final viewModel = CommunityViewModel();
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(viewModel.latestPosts.length, 2);
        expect(viewModel.latestPosts[0].authorName, '물생활러');
        expect(viewModel.latestPosts[0].tags, ['구피', '번식']);
        expect(viewModel.latestPosts[1].authorName, '베타마스터');
      });

      test('인기 랭킹이 설정된다', () async {
        // Arrange
        final mockPosts = [
          RecordModel({
            'id': 'post_1',
            'author_id': 'user_1',
            'author_name': '물생활러',
            'author_image': '',
            'content': '오늘 구피 새끼가 태어났어요!',
            'image': '',
            'tags': [],
            'like_count': 100,
            'comment_count': 50,
            'bookmark_count': 30,
            'created': '2024-01-15T10:00:00Z',
          }),
        ];

        when(
          () => mockRecordService.getList(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            filter: any(named: 'filter'),
            sort: any(named: 'sort'),
          ),
        ).thenAnswer(
          (_) async => ResultList<RecordModel>(
            page: 1,
            perPage: 10,
            totalItems: 1,
            totalPages: 1,
            items: mockPosts,
          ),
        );

        final viewModel = CommunityViewModel();
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(viewModel.popularRanking, isNotNull);
        expect(viewModel.popularRanking!.rank, 1);
        expect(viewModel.popularRanking!.id, 'post_1');
      });

      test('추천 아이템이 최대 3개까지 설정된다', () async {
        // Arrange
        final mockPosts = List.generate(
          5,
          (i) => RecordModel({
            'id': 'post_$i',
            'author_id': 'user_$i',
            'author_name': '사용자$i',
            'author_image': '',
            'content': '게시글 내용 $i',
            'image': '',
            'tags': [],
            'like_count': 10 - i,
            'comment_count': 5,
            'bookmark_count': 2,
            'created': '2024-01-1${5 - i}T10:00:00Z',
          }),
        );

        when(
          () => mockRecordService.getList(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            filter: any(named: 'filter'),
            sort: any(named: 'sort'),
          ),
        ).thenAnswer(
          (_) async => ResultList<RecordModel>(
            page: 1,
            perPage: 10,
            totalItems: 5,
            totalPages: 1,
            items: mockPosts,
          ),
        );

        final viewModel = CommunityViewModel();
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(viewModel.recommendationItems.length, 3);
      });
    });

    group('filterByTag', () {
      test('태그로 게시글을 필터링한다', () async {
        // Arrange: 초기화 mock
        when(
          () => mockRecordService.getList(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            filter: any(named: 'filter'),
            sort: any(named: 'sort'),
          ),
        ).thenAnswer(
          (_) async => ResultList<RecordModel>(
            page: 1,
            perPage: 20,
            totalItems: 0,
            totalPages: 0,
            items: [],
          ),
        );

        final viewModel = CommunityViewModel();
        await Future.delayed(const Duration(milliseconds: 100));

        // 필터링 mock 설정
        final filteredPosts = [
          RecordModel({
            'id': 'post_1',
            'author_id': 'user_1',
            'author_name': '구피러버',
            'author_image': '',
            'content': '구피 키우기 팁 공유합니다',
            'image': '',
            'tags': ['구피', '초보'],
            'like_count': 25,
            'comment_count': 8,
            'bookmark_count': 5,
            'created': '2024-01-15T10:00:00Z',
          }),
        ];

        when(
          () => mockRecordService.getList(
            page: 1,
            perPage: 50,
            filter: 'tags ~ "구피"',
            sort: '',
          ),
        ).thenAnswer(
          (_) async => ResultList<RecordModel>(
            page: 1,
            perPage: 50,
            totalItems: 1,
            totalPages: 1,
            items: filteredPosts,
          ),
        );

        // Act
        await viewModel.filterByTag('#구피');

        // Assert
        expect(viewModel.isFilteringByTag, true);
        expect(viewModel.selectedTag, '구피');
        expect(viewModel.filteredPosts.length, 1);
        expect(viewModel.filteredPosts[0].tags, contains('구피'));
      });

      test('# 기호를 제거하고 필터링한다', () async {
        // Arrange
        when(
          () => mockRecordService.getList(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            filter: any(named: 'filter'),
            sort: any(named: 'sort'),
          ),
        ).thenAnswer(
          (_) async => ResultList<RecordModel>(
            page: 1,
            perPage: 50,
            totalItems: 0,
            totalPages: 0,
            items: [],
          ),
        );

        final viewModel = CommunityViewModel();
        await Future.delayed(const Duration(milliseconds: 100));

        // Act
        await viewModel.filterByTag('###베타');

        // Assert
        expect(viewModel.selectedTag, '베타');
      });

      test('빈 태그로 필터링하면 필터를 해제한다', () async {
        // Arrange
        when(
          () => mockRecordService.getList(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            filter: any(named: 'filter'),
            sort: any(named: 'sort'),
          ),
        ).thenAnswer(
          (_) async => ResultList<RecordModel>(
            page: 1,
            perPage: 50,
            totalItems: 0,
            totalPages: 0,
            items: [],
          ),
        );

        final viewModel = CommunityViewModel();
        await Future.delayed(const Duration(milliseconds: 100));

        // 먼저 필터 적용
        await viewModel.filterByTag('구피');
        expect(viewModel.isFilteringByTag, true);

        // Act
        await viewModel.filterByTag('');

        // Assert
        expect(viewModel.isFilteringByTag, false);
        expect(viewModel.selectedTag, isNull);
        expect(viewModel.filteredPosts, isEmpty);
      });
    });

    group('clearTagFilter', () {
      test('태그 필터를 해제한다', () async {
        // Arrange
        when(
          () => mockRecordService.getList(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            filter: any(named: 'filter'),
            sort: any(named: 'sort'),
          ),
        ).thenAnswer(
          (_) async => ResultList<RecordModel>(
            page: 1,
            perPage: 50,
            totalItems: 0,
            totalPages: 0,
            items: [],
          ),
        );

        final viewModel = CommunityViewModel();
        await Future.delayed(const Duration(milliseconds: 100));

        // 필터 적용
        await viewModel.filterByTag('구피');

        // Act
        viewModel.clearTagFilter();

        // Assert
        expect(viewModel.isFilteringByTag, false);
        expect(viewModel.selectedTag, isNull);
        expect(viewModel.filteredPosts, isEmpty);
      });
    });

    group('toggleLike', () {
      test('좋아요를 토글하고 로컬 상태를 업데이트한다', () async {
        // Arrange
        final mockPosts = [
          RecordModel({
            'id': 'post_1',
            'author_id': 'user_1',
            'author_name': '테스터',
            'author_image': '',
            'content': '테스트 게시글',
            'image': '',
            'tags': [],
            'like_count': 10,
            'comment_count': 2,
            'bookmark_count': 1,
            'created': '2024-01-15T10:00:00Z',
          }),
        ];

        when(
          () => mockRecordService.getList(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            filter: any(named: 'filter'),
            sort: any(named: 'sort'),
          ),
        ).thenAnswer(
          (_) async => ResultList<RecordModel>(
            page: 1,
            perPage: 10,
            totalItems: 1,
            totalPages: 1,
            items: mockPosts,
          ),
        );

        when(() => mockRecordService.getOne(any())).thenAnswer(
          (_) async => RecordModel({'id': 'post_1', 'like_count': 10}),
        );

        when(
          () => mockRecordService.update(any(), body: any(named: 'body')),
        ).thenAnswer((_) async => mockPosts[0]);

        final viewModel = CommunityViewModel();
        await Future.delayed(const Duration(milliseconds: 100));

        final initialLikeCount = viewModel.latestPosts[0].likeCount;

        // Act
        await viewModel.toggleLike('post_1', true);

        // Assert
        expect(viewModel.latestPosts[0].likeCount, initialLikeCount + 1);
        expect(viewModel.latestPosts[0].isLiked, true);
      });
    });

    group('toggleBookmark', () {
      test('북마크를 토글하고 로컬 상태를 업데이트한다', () async {
        // Arrange
        final mockPosts = [
          RecordModel({
            'id': 'post_1',
            'author_id': 'user_1',
            'author_name': '테스터',
            'author_image': '',
            'content': '테스트 게시글',
            'image': '',
            'tags': [],
            'like_count': 10,
            'comment_count': 2,
            'bookmark_count': 5,
            'created': '2024-01-15T10:00:00Z',
          }),
        ];

        when(
          () => mockRecordService.getList(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            filter: any(named: 'filter'),
            sort: any(named: 'sort'),
          ),
        ).thenAnswer(
          (_) async => ResultList<RecordModel>(
            page: 1,
            perPage: 10,
            totalItems: 1,
            totalPages: 1,
            items: mockPosts,
          ),
        );

        when(() => mockRecordService.getOne(any())).thenAnswer(
          (_) async => RecordModel({'id': 'post_1', 'bookmark_count': 5}),
        );

        when(
          () => mockRecordService.update(any(), body: any(named: 'body')),
        ).thenAnswer((_) async => mockPosts[0]);

        final viewModel = CommunityViewModel();
        await Future.delayed(const Duration(milliseconds: 100));

        final initialBookmarkCount = viewModel.latestPosts[0].bookmarkCount;

        // Act
        await viewModel.toggleBookmark('post_1', true);

        // Assert
        expect(
          viewModel.latestPosts[0].bookmarkCount,
          initialBookmarkCount + 1,
        );
        expect(viewModel.latestPosts[0].isBookmarked, true);
      });
    });

    group('refreshAll', () {
      test('모든 데이터를 새로고침한다', () async {
        // Arrange
        int callCount = 0;
        when(
          () => mockRecordService.getList(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            filter: any(named: 'filter'),
            sort: any(named: 'sort'),
          ),
        ).thenAnswer((_) async {
          callCount++;
          return ResultList<RecordModel>(
            page: 1,
            perPage: 10,
            totalItems: 0,
            totalPages: 0,
            items: [],
          );
        });

        final viewModel = CommunityViewModel();
        await Future.delayed(const Duration(milliseconds: 100));

        final initialCallCount = callCount;

        // Act
        await viewModel.refreshAll();

        // Assert: 새로고침으로 추가 호출 발생
        expect(callCount, greaterThan(initialCallCount));
      });
    });

    group('tags (인기 태그)', () {
      test('인기 태그가 기본값으로 설정된다 (태그 서비스 실패 시)', () async {
        // Arrange: 모든 요청에 빈 결과 반환
        when(
          () => mockRecordService.getList(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            filter: any(named: 'filter'),
            sort: any(named: 'sort'),
          ),
        ).thenAnswer(
          (_) async => ResultList<RecordModel>(
            page: 1,
            perPage: 10,
            totalItems: 0,
            totalPages: 0,
            items: [],
          ),
        );

        final viewModel = CommunityViewModel();
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert: 기본 태그가 설정됨
        expect(viewModel.tags, isNotEmpty);
        expect(viewModel.tags, contains('#베타'));
        expect(viewModel.tags, contains('#25큐브'));
        expect(viewModel.tags, contains('#초보자'));
      });
    });
  });
}
