import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oomool/data/services/pocketbase_service.dart';
import 'package:oomool/data/services/community_service.dart';

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
  late CommunityService communityService;

  setUpAll(() async {
    // SharedPreferences mock 설정
    SharedPreferences.setMockInitialValues({});

    // Fake 등록 (when에서 사용되는 타입들)
    registerFallbackValue(Uri());
  });

  setUp(() {
    // Mock 객체 생성
    mockPocketBase = MockPocketBase();
    mockAuthStore = MockAuthStore();
    mockRecordService = MockRecordService();
    mockFileService = MockFileService();

    // AuthStore mock 설정
    when(() => mockPocketBase.authStore).thenReturn(mockAuthStore);
    when(() => mockAuthStore.isValid).thenReturn(false);
    when(() => mockAuthStore.token).thenReturn('');
    when(() => mockAuthStore.record).thenReturn(null);

    // Collection mock 설정
    when(() => mockPocketBase.collection(any())).thenReturn(mockRecordService);

    // Files mock 설정
    when(() => mockPocketBase.files).thenReturn(mockFileService);

    // PocketBase 서비스에 mock client 주입
    PocketBaseService.instance.initializeForTesting(mockPocketBase);

    // CommunityService 인스턴스 획득
    communityService = CommunityService.instance;
  });

  tearDown(() {
    // 테스트 후 정리
    PocketBaseService.instance.resetForTesting();
  });

  group('CommunityService', () {
    group('getQuestions', () {
      test('질문 목록을 성공적으로 조회한다', () async {
        // Arrange
        final mockRecord = RecordModel({
          'id': 'question_1',
          'title': '구피 물갈이 주기 질문',
          'content': '60큐브에 구피 20마리 키우고 있는데 물갈이 주기를 어떻게 잡아야 할까요?',
          'category': 'beginner',
          'view_count': 42,
          'comment_count': 5,
          'created': '2024-01-15T10:00:00Z',
          'updated': '2024-01-15T10:00:00Z',
          'attached_records': [],
        });

        final mockResult = ResultList<RecordModel>(
          page: 1,
          perPage: 20,
          totalItems: 1,
          totalPages: 1,
          items: [mockRecord],
        );

        when(
          () => mockRecordService.getList(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            filter: any(named: 'filter'),
            sort: any(named: 'sort'),
            expand: any(named: 'expand'),
          ),
        ).thenAnswer((_) async => mockResult);

        // Act
        final questions = await communityService.getQuestions();

        // Assert
        expect(questions, isNotEmpty);
        expect(questions.length, 1);
        expect(questions.first.title, '구피 물갈이 주기 질문');
        expect(questions.first.viewCount, 42);
        expect(questions.first.commentCount, 5);
      });

      test('빈 질문 목록을 처리한다', () async {
        // Arrange
        final mockResult = ResultList<RecordModel>(
          page: 1,
          perPage: 20,
          totalItems: 0,
          totalPages: 0,
          items: [],
        );

        when(
          () => mockRecordService.getList(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            filter: any(named: 'filter'),
            sort: any(named: 'sort'),
            expand: any(named: 'expand'),
          ),
        ).thenAnswer((_) async => mockResult);

        // Act
        final questions = await communityService.getQuestions();

        // Assert
        expect(questions, isEmpty);
      });

      test('API 오류 시 예외를 던진다', () async {
        // Arrange
        when(
          () => mockRecordService.getList(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            filter: any(named: 'filter'),
            sort: any(named: 'sort'),
            expand: any(named: 'expand'),
          ),
        ).thenThrow(ClientException(statusCode: 500));

        // Act & Assert
        expect(
          () => communityService.getQuestions(),
          throwsA(isA<ClientException>()),
        );
      });
    });

    group('getQuestion', () {
      test('특정 질문을 성공적으로 조회한다', () async {
        // Arrange
        final mockRecord = RecordModel({
          'id': 'question_1',
          'title': '베타 합사 가능 물고기',
          'content': '베타랑 합사 가능한 물고기 추천해주세요.',
          'category': 'species',
          'view_count': 156,
          'comment_count': 12,
          'created': '2024-01-15T10:00:00Z',
          'updated': '2024-01-15T10:00:00Z',
          'attached_records': [],
        });

        when(
          () => mockRecordService.getOne(any(), expand: any(named: 'expand')),
        ).thenAnswer((_) async => mockRecord);

        // Act
        final question = await communityService.getQuestion('question_1');

        // Assert
        expect(question, isNotNull);
        expect(question!.title, '베타 합사 가능 물고기');
        expect(question.viewCount, 156);
      });

      test('존재하지 않는 질문 조회 시 null을 반환한다', () async {
        // Arrange
        when(
          () => mockRecordService.getOne(any(), expand: any(named: 'expand')),
        ).thenThrow(ClientException(statusCode: 404));

        // Act
        final question = await communityService.getQuestion('nonexistent');

        // Assert
        expect(question, isNull);
      });
    });

    group('getPosts', () {
      test('커뮤니티 포스트 목록을 성공적으로 조회한다', () async {
        // Arrange
        final mockRecord = RecordModel({
          'id': 'post_1',
          'author_id': 'user_1',
          'author_name': '물생활러',
          'author_image': '',
          'content': '오늘 구피 새끼가 태어났어요!',
          'image': '',
          'tags': ['구피', '번식'],
          'like_count': 15,
          'comment_count': 3,
          'bookmark_count': 2,
          'created': '2024-01-15T10:00:00Z',
          'updated': '2024-01-15T10:00:00Z',
        });

        final mockResult = ResultList<RecordModel>(
          page: 1,
          perPage: 20,
          totalItems: 1,
          totalPages: 1,
          items: [mockRecord],
        );

        when(
          () => mockRecordService.getList(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            filter: any(named: 'filter'),
            sort: any(named: 'sort'),
          ),
        ).thenAnswer((_) async => mockResult);

        // Act
        final posts = await communityService.getPosts();

        // Assert
        expect(posts, isNotEmpty);
        expect(posts.length, 1);
        expect(posts.first.authorName, '물생활러');
        expect(posts.first.content, '오늘 구피 새끼가 태어났어요!');
        expect(posts.first.tags, ['구피', '번식']);
        expect(posts.first.likeCount, 15);
      });

      test('태그 필터링이 동작한다', () async {
        // Arrange
        final mockResult = ResultList<RecordModel>(
          page: 1,
          perPage: 50,
          totalItems: 0,
          totalPages: 0,
          items: [],
        );

        when(
          () => mockRecordService.getList(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            filter: 'tags ~ "구피"',
            sort: any(named: 'sort'),
          ),
        ).thenAnswer((_) async => mockResult);

        // Act
        await communityService.getPosts(filter: 'tags ~ "구피"');

        // Assert
        verify(
          () => mockRecordService.getList(
            page: 1,
            perPage: 20,
            filter: 'tags ~ "구피"',
            sort: null,
          ),
        ).called(1);
      });
    });

    group('toggleLike', () {
      test('좋아요를 추가한다', () async {
        // Arrange
        when(
          () => mockPocketBase.send(
            any(),
            method: any(named: 'method'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async => {'liked': true, 'like_count': 11});

        // Act
        await communityService.toggleLike('post_1', true);

        // Assert
        verify(
          () => mockPocketBase.send(
            '/api/community/toggle-like',
            method: 'POST',
            body: {'target_id': 'post_1', 'target_type': 'post'},
          ),
        ).called(1);
      });

      test('좋아요를 취소한다', () async {
        // Arrange
        when(
          () => mockPocketBase.send(
            any(),
            method: any(named: 'method'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async => {'liked': false, 'like_count': 9});

        // Act
        await communityService.toggleLike('post_1', false);

        // Assert
        verify(
          () => mockPocketBase.send(
            '/api/community/toggle-like',
            method: 'POST',
            body: {'target_id': 'post_1', 'target_type': 'post'},
          ),
        ).called(1);
      });

      test('좋아요 수가 0 이하로 내려가지 않는다', () async {
        // Arrange
        when(
          () => mockPocketBase.send(
            any(),
            method: any(named: 'method'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async => {'liked': false, 'like_count': 0});

        // Act
        await communityService.toggleLike('post_1', false);

        // Assert
        verify(
          () => mockPocketBase.send(
            '/api/community/toggle-like',
            method: 'POST',
            body: {'target_id': 'post_1', 'target_type': 'post'},
          ),
        ).called(1);
      });
    });

    group('toggleBookmark', () {
      test('북마크를 추가한다', () async {
        // Arrange
        when(
          () => mockPocketBase.send(
            any(),
            method: any(named: 'method'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async => {'bookmarked': true, 'bookmark_count': 6});

        // Act
        await communityService.toggleBookmark('post_1', true);

        // Assert
        verify(
          () => mockPocketBase.send(
            '/api/community/toggle-bookmark',
            method: 'POST',
            body: {'post_id': 'post_1', 'bookmarked': true},
          ),
        ).called(1);
      });
    });

    group('incrementViewCount', () {
      test('조회수를 증가시킨다', () async {
        // Arrange
        when(
          () => mockPocketBase.send(
            any(),
            method: any(named: 'method'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async => {'success': true});

        // Act
        await communityService.incrementViewCount('question_1');

        // Assert
        verify(
          () => mockPocketBase.send(
            '/api/community/increment-view',
            method: 'POST',
            body: {'id': 'question_1', 'type': 'question'},
          ),
        ).called(1);
      });
    });

    group('deletePost', () {
      test('포스트를 성공적으로 삭제한다', () async {
        // Arrange
        when(() => mockRecordService.delete(any())).thenAnswer((_) async => {});

        // Act
        await communityService.deletePost('post_1');

        // Assert
        verify(() => mockRecordService.delete('post_1')).called(1);
      });

      test('삭제 실패 시 예외를 던진다', () async {
        // Arrange
        when(
          () => mockRecordService.delete(any()),
        ).thenThrow(ClientException(statusCode: 403));

        // Act & Assert
        expect(
          () => communityService.deletePost('post_1'),
          throwsA(isA<ClientException>()),
        );
      });
    });

    group('deleteQuestion', () {
      test('질문을 성공적으로 삭제한다', () async {
        // Arrange
        when(() => mockRecordService.delete(any())).thenAnswer((_) async => {});

        // Act
        await communityService.deleteQuestion('question_1');

        // Assert
        verify(() => mockRecordService.delete('question_1')).called(1);
      });
    });
  });
}
