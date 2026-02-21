import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:oomool/data/services/auth_service.dart';
import 'package:oomool/data/services/community_service.dart';
import 'package:oomool/data/services/curious_service.dart';
import 'package:oomool/data/services/follow_service.dart';
import 'package:oomool/data/services/tag_service.dart';
import 'package:oomool/presentation/viewmodels/community_post_viewmodel.dart';
import 'package:oomool/presentation/viewmodels/community_following_viewmodel.dart';
import 'package:oomool/presentation/viewmodels/community_qna_viewmodel.dart';
import 'package:oomool/presentation/widgets/home/community_card.dart';

// Mock 클래스 정의
class MockCommunityService extends Mock implements CommunityService {}

class MockCuriousService extends Mock implements CuriousService {}

class MockFollowService extends Mock implements FollowService {}

class MockTagService extends Mock implements TagService {}

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockCommunityService mockCommunityService;
  late MockCuriousService mockCuriousService;
  late MockFollowService mockFollowService;
  late MockTagService mockTagService;
  late MockAuthService mockAuthService;

  setUp(() {
    mockCommunityService = MockCommunityService();
    mockCuriousService = MockCuriousService();
    mockFollowService = MockFollowService();
    mockTagService = MockTagService();
    mockAuthService = MockAuthService();

    when(() => mockAuthService.currentUser).thenReturn(null);
    when(
      () => mockCommunityService.getPosts(
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
        filter: any(named: 'filter'),
        sort: any(named: 'sort'),
      ),
    ).thenAnswer(
      (_) async => [const CommunityData(id: '', authorName: '', content: '')],
    );
    when(
      () => mockTagService.getPopularTags(
        limit: any(named: 'limit'),
        category: any(named: 'category'),
      ),
    ).thenAnswer((_) async => []);
  });

  CommunityPostViewModel buildPostViewModel({bool autoLoad = false}) {
    return CommunityPostViewModel(
      service: mockCommunityService,
      tagService: mockTagService,
      autoLoad: autoLoad,
    );
  }

  CommunityFollowingViewModel buildFollowingViewModel() {
    return CommunityFollowingViewModel(
      service: mockCommunityService,
      followService: mockFollowService,
      authService: mockAuthService,
    );
  }

  CommunityQnaViewModel buildQnaViewModel() {
    return CommunityQnaViewModel(
      service: mockCommunityService,
      curiousService: mockCuriousService,
      tagService: mockTagService,
      authService: mockAuthService,
    );
  }

  List<CommunityData> samplePosts() {
    return [
      CommunityData(
        id: 'post_1',
        authorId: 'user_1',
        authorName: '물생활러',
        authorImageUrl: '',
        content: '오늘 구피 새끼가 태어났어요! 너무 귀엽습니다.',
        imageUrl: '',
        likeCount: 15,
        commentCount: 3,
        bookmarkCount: 2,
      ),
      CommunityData(
        id: 'post_2',
        authorId: 'user_2',
        authorName: '베타마스터',
        authorImageUrl: '',
        content: '베타 어항 세팅 완료!',
        imageUrl: '',
        likeCount: 20,
        commentCount: 5,
        bookmarkCount: 3,
      ),
    ];
  }

  group('CommunityPostViewModel', () {
    group('초기화', () {
      test('초기 상태가 올바르게 설정된다', () {
        final viewModel = buildPostViewModel();

        expect(viewModel.latestPosts, isEmpty);
        expect(viewModel.isFilteringByTag, false);
        expect(viewModel.selectedTag, isNull);
      });
    });

    group('loadRecommendTab', () {
      test('추천 탭 데이터를 로드한다', () async {
        when(
          () => mockCommunityService.getPosts(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            filter: any(named: 'filter'),
            sort: any(named: 'sort'),
          ),
        ).thenAnswer((_) async => samplePosts());

        final viewModel = buildPostViewModel();
        await viewModel.loadRecommendTab();

        expect(viewModel.latestPosts.length, 2);
        expect(viewModel.latestPosts[0].authorName, '물생활러');
        expect(viewModel.latestPosts[0].tags, isEmpty);
        expect(viewModel.latestPosts[1].authorName, '베타마스터');
      });

      test('인기 랭킹이 설정된다', () async {
        when(
          () => mockCommunityService.getPosts(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            filter: any(named: 'filter'),
            sort: any(named: 'sort'),
          ),
        ).thenAnswer(
          (_) async => [
            const CommunityData(
              id: 'post_1',
              authorId: 'user_1',
              authorName: '물생활러',
              content: '오늘 구피 새끼가 태어났어요!',
              likeCount: 100,
              commentCount: 50,
              bookmarkCount: 30,
            ),
          ],
        );

        final viewModel = buildPostViewModel();
        await viewModel.loadRecommendTab();

        expect(viewModel.popularRanking, isNotNull);
        expect(viewModel.popularRanking!.rank, 1);
        expect(viewModel.popularRanking!.id, 'post_1');
      });

      test('추천 아이템이 최대 3개까지 설정된다', () async {
        final posts = List.generate(
          5,
          (i) => CommunityData(
            id: 'post_$i',
            authorId: 'user_$i',
            authorName: '사용자$i',
            content: '게시글 내용 $i',
            likeCount: 10 - i,
            commentCount: 5,
            bookmarkCount: 2,
          ),
        );

        when(
          () => mockCommunityService.getPosts(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            filter: any(named: 'filter'),
            sort: any(named: 'sort'),
          ),
        ).thenAnswer((_) async => posts);

        final viewModel = buildPostViewModel();
        await viewModel.loadRecommendTab();

        expect(viewModel.recommendationItems.length, 3);
      });

      test('캐시가 유효하면 중복 네트워크 호출을 하지 않는다', () async {
        when(
          () => mockCommunityService.getPosts(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            filter: any(named: 'filter'),
            sort: any(named: 'sort'),
          ),
        ).thenAnswer((_) async => samplePosts());

        final viewModel = buildPostViewModel();
        await viewModel.loadRecommendTab();
        await viewModel.loadRecommendTab();

        verify(
          () => mockCommunityService.getPosts(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            filter: any(named: 'filter'),
            sort: any(named: 'sort'),
          ),
        ).called(1);
      });

      test('동시에 여러 번 호출해도 in-flight 요청은 1회만 수행된다', () async {
        when(
          () => mockCommunityService.getPosts(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            filter: any(named: 'filter'),
            sort: any(named: 'sort'),
          ),
        ).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return samplePosts();
        });

        final viewModel = buildPostViewModel();
        await Future.wait([
          viewModel.loadRecommendTab(),
          viewModel.loadRecommendTab(),
          viewModel.loadRecommendTab(),
        ]);

        verify(
          () => mockCommunityService.getPosts(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            filter: any(named: 'filter'),
            sort: any(named: 'sort'),
          ),
        ).called(1);
      });
    });

    group('filterByTag', () {
      test('태그로 게시글을 필터링한다', () async {
        final filteredPosts = [
          CommunityData(
            id: 'post_1',
            authorId: 'user_1',
            authorName: '구피러버',
            content: '구피 키우기 팁 공유합니다',
            tags: ['구피', '초보'],
            likeCount: 25,
            commentCount: 8,
            bookmarkCount: 5,
          ),
        ];

        when(
          () => mockCommunityService.getPosts(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            filter: 'tags ~ "구피"',
            sort: null,
          ),
        ).thenAnswer((_) async => filteredPosts);

        final viewModel = buildPostViewModel();
        await viewModel.filterByTag('#구피');

        expect(viewModel.isFilteringByTag, true);
        expect(viewModel.selectedTag, '구피');
        expect(viewModel.filteredPosts.length, 1);
        expect(viewModel.filteredPosts[0].tags, contains('구피'));
      });

      test('# 기호를 제거하고 필터링한다', () async {
        when(
          () => mockCommunityService.getPosts(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            filter: 'tags ~ "베타"',
            sort: any(named: 'sort'),
          ),
        ).thenAnswer((_) async => []);

        final viewModel = buildPostViewModel();
        await viewModel.filterByTag('###베타');

        expect(viewModel.selectedTag, '베타');
      });

      test('빈 태그로 필터링하면 필터를 해제한다', () async {
        when(
          () => mockCommunityService.getPosts(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            filter: 'tags ~ "구피"',
            sort: any(named: 'sort'),
          ),
        ).thenAnswer((_) async => [samplePosts().first]);

        final viewModel = buildPostViewModel();
        await viewModel.filterByTag('구피');
        expect(viewModel.isFilteringByTag, true);

        await viewModel.filterByTag('');
        expect(viewModel.isFilteringByTag, false);
        expect(viewModel.selectedTag, isNull);
        expect(viewModel.filteredPosts, isEmpty);
      });
    });

    group('clearTagFilter', () {
      test('태그 필터를 해제한다', () async {
        when(
          () => mockCommunityService.getPosts(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            filter: 'tags ~ "구피"',
            sort: any(named: 'sort'),
          ),
        ).thenAnswer((_) async => [samplePosts().first]);

        final viewModel = buildPostViewModel();
        await viewModel.filterByTag('구피');

        viewModel.clearTagFilter();

        expect(viewModel.isFilteringByTag, false);
        expect(viewModel.selectedTag, isNull);
        expect(viewModel.filteredPosts, isEmpty);
      });
    });

    group('toggleLike', () {
      test('좋아요를 토글하고 로컬 상태를 업데이트한다', () async {
        when(
          () => mockCommunityService.getPosts(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            filter: any(named: 'filter'),
            sort: any(named: 'sort'),
          ),
        ).thenAnswer(
          (_) async => [
            CommunityData(
              id: 'post_1',
              authorName: '테스터',
              content: '테스트 게시글',
              likeCount: 10,
              bookmarkCount: 1,
            ),
          ],
        );

        when(
          () => mockCommunityService.toggleLike('post_1', true),
        ).thenAnswer((_) async {});

        final viewModel = buildPostViewModel();
        await viewModel.loadRecommendTab();

        final initialLikeCount = viewModel.latestPosts[0].likeCount;
        await viewModel.toggleLike('post_1', true);

        expect(viewModel.latestPosts[0].likeCount, initialLikeCount + 1);
        expect(viewModel.latestPosts[0].isLiked, true);
      });
    });

    group('toggleBookmark', () {
      test('북마크를 토글하고 로컬 상태를 업데이트한다', () async {
        when(
          () => mockCommunityService.getPosts(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            filter: any(named: 'filter'),
            sort: any(named: 'sort'),
          ),
        ).thenAnswer(
          (_) async => [
            CommunityData(
              id: 'post_1',
              authorName: '테스터',
              content: '테스트 게시글',
              likeCount: 10,
              bookmarkCount: 5,
            ),
          ],
        );

        when(
          () => mockCommunityService.toggleBookmark('post_1', true),
        ).thenAnswer((_) async {});

        final viewModel = buildPostViewModel();
        await viewModel.loadRecommendTab();

        final initialBookmarkCount = viewModel.latestPosts[0].bookmarkCount;
        await viewModel.toggleBookmark('post_1', true);

        expect(
          viewModel.latestPosts[0].bookmarkCount,
          initialBookmarkCount + 1,
        );
        expect(viewModel.latestPosts[0].isBookmarked, true);
      });
    });

    group('refreshAll', () {
      test('모든 데이터를 새로고침한다', () async {
        int callCount = 0;

        when(
          () => mockCommunityService.getPosts(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            filter: any(named: 'filter'),
            sort: any(named: 'sort'),
          ),
        ).thenAnswer((_) async {
          callCount++;
          return <CommunityData>[];
        });

        final viewModel = buildPostViewModel();
        final initialCallCount = callCount;

        await viewModel.refreshAll();
        expect(callCount, greaterThan(initialCallCount));
      });
    });

    group('tags (인기 태그)', () {
      test('인기 태그가 기본값으로 설정된다 (태그 서비스 실패 시)', () async {
        when(
          () => mockCommunityService.getPosts(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            filter: any(named: 'filter'),
            sort: any(named: 'sort'),
          ),
        ).thenAnswer((_) async => []);
        when(
          () => mockTagService.getPopularTags(
            limit: any(named: 'limit'),
            category: any(named: 'category'),
          ),
        ).thenThrow(Exception('failed to load'));

        final viewModel = buildPostViewModel();
        await viewModel.loadRecommendTab();

        expect(viewModel.tags, isNotEmpty);
        expect(viewModel.tags, contains('#베타'));
        expect(viewModel.tags, contains('#25큐브'));
        expect(viewModel.tags, contains('#초보자'));
      });
    });
  });

  group('CommunityFollowingViewModel', () {
    test('초기 상태가 올바르게 설정된다', () {
      final viewModel = buildFollowingViewModel();
      expect(viewModel.followingPosts, isEmpty);
    });
  });

  group('CommunityQnaViewModel', () {
    test('초기 상태가 올바르게 설정된다', () {
      final viewModel = buildQnaViewModel();
      expect(viewModel.popularQuestions, isEmpty);
      expect(viewModel.waitingQuestions, isEmpty);
      expect(viewModel.featuredQuestion, isNull);
    });
  });
}
