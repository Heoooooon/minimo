import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oomool/data/services/pocketbase_service.dart';
import 'package:oomool/data/services/tag_service.dart';

// Mock 클래스 정의
class MockPocketBase extends Mock implements PocketBase {}

class MockAuthStore extends Mock implements AuthStore {}

class MockRecordService extends Mock implements RecordService {}

void main() {
  late MockPocketBase mockPocketBase;
  late MockAuthStore mockAuthStore;
  late MockRecordService mockRecordService;
  late TagService tagService;

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
    tagService = TagService.instance;
  });

  tearDown(() {
    PocketBaseService.instance.resetForTesting();
  });

  group('TagService', () {
    group('getPopularTags', () {
      test('인기 태그 목록을 조회한다', () async {
        // Arrange
        final mockRecords = [
          RecordModel({
            'id': 'tag_1',
            'name': '구피',
            'usage_count': 150,
            'category': null,
            'created': '2024-01-15T10:00:00Z',
          }),
          RecordModel({
            'id': 'tag_2',
            'name': '베타',
            'usage_count': 120,
            'category': null,
            'created': '2024-01-14T10:00:00Z',
          }),
          RecordModel({
            'id': 'tag_3',
            'name': '25큐브',
            'usage_count': 80,
            'category': null,
            'created': '2024-01-13T10:00:00Z',
          }),
        ];

        final mockResult = ResultList<RecordModel>(
          page: 1,
          perPage: 10,
          totalItems: 3,
          totalPages: 1,
          items: mockRecords,
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
        final tags = await tagService.getPopularTags(limit: 10);

        // Assert
        expect(tags, isNotEmpty);
        expect(tags.length, 3);
        expect(tags[0].name, '구피');
        expect(tags[0].usageCount, 150);
        expect(tags[1].name, '베타');
        expect(tags[2].name, '25큐브');
      });

      test('카테고리로 필터링하여 태그를 조회한다', () async {
        // Arrange
        final mockResult = ResultList<RecordModel>(
          page: 1,
          perPage: 10,
          totalItems: 0,
          totalPages: 0,
          items: [],
        );

        when(
          () => mockRecordService.getList(
            page: 1,
            perPage: 10,
            filter: 'category = "qna"',
            sort: '-usage_count',
          ),
        ).thenAnswer((_) async => mockResult);

        // Act
        await tagService.getPopularTags(limit: 10, category: 'qna');

        // Assert
        verify(
          () => mockRecordService.getList(
            page: 1,
            perPage: 10,
            filter: 'category = "qna"',
            sort: '-usage_count',
          ),
        ).called(1);
      });

      test('오류 발생 시 빈 목록을 반환한다', () async {
        // Arrange
        when(
          () => mockRecordService.getList(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            filter: any(named: 'filter'),
            sort: any(named: 'sort'),
          ),
        ).thenThrow(ClientException(statusCode: 500));

        // Act
        final tags = await tagService.getPopularTags();

        // Assert
        expect(tags, isEmpty);
      });
    });

    group('searchTags', () {
      test('태그를 검색한다', () async {
        // Arrange
        final mockRecords = [
          RecordModel({
            'id': 'tag_1',
            'name': '구피',
            'usage_count': 150,
            'category': null,
            'created': '2024-01-15T10:00:00Z',
          }),
          RecordModel({
            'id': 'tag_2',
            'name': '구피초보',
            'usage_count': 50,
            'category': null,
            'created': '2024-01-15T10:00:00Z',
          }),
        ];

        final mockResult = ResultList<RecordModel>(
          page: 1,
          perPage: 20,
          totalItems: 2,
          totalPages: 1,
          items: mockRecords,
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
        final tags = await tagService.searchTags(query: '구피');

        // Assert
        expect(tags.length, 2);
        expect(tags[0].name, '구피');
        expect(tags[1].name, '구피초보');
      });

      test('검색 결과가 없으면 빈 목록을 반환한다', () async {
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
          ),
        ).thenAnswer((_) async => mockResult);

        // Act
        final tags = await tagService.searchTags(query: '존재하지않는태그');

        // Assert
        expect(tags, isEmpty);
      });
    });

    group('getTagByName', () {
      test('이름으로 태그를 조회한다', () async {
        // Arrange
        final mockRecord = RecordModel({
          'id': 'tag_1',
          'name': '구피',
          'usage_count': 150,
          'category': null,
          'created': '2024-01-15T10:00:00Z',
        });

        final mockResult = ResultList<RecordModel>(
          page: 1,
          perPage: 1,
          totalItems: 1,
          totalPages: 1,
          items: [mockRecord],
        );

        when(
          () => mockRecordService.getList(
            page: 1,
            perPage: 1,
            filter: 'name = "구피"',
          ),
        ).thenAnswer((_) async => mockResult);

        // Act
        final tag = await tagService.getTagByName('구피');

        // Assert
        expect(tag, isNotNull);
        expect(tag!.name, '구피');
        expect(tag.usageCount, 150);
      });

      test('존재하지 않는 태그는 null을 반환한다', () async {
        // Arrange
        final mockResult = ResultList<RecordModel>(
          page: 1,
          perPage: 1,
          totalItems: 0,
          totalPages: 0,
          items: [],
        );

        when(
          () => mockRecordService.getList(
            page: 1,
            perPage: 1,
            filter: 'name = "없는태그"',
          ),
        ).thenAnswer((_) async => mockResult);

        // Act
        final tag = await tagService.getTagByName('없는태그');

        // Assert
        expect(tag, isNull);
      });
    });

    group('getOrCreateTag', () {
      test('기존 태그가 있으면 사용량을 증가시킨다', () async {
        // Arrange
        final existingTag = RecordModel({
          'id': 'tag_1',
          'name': '구피',
          'usage_count': 150,
          'category': null,
          'created': '2024-01-15T10:00:00Z',
        });

        // getTagByName mock
        when(
          () => mockRecordService.getList(
            page: 1,
            perPage: 1,
            filter: 'name = "구피"',
          ),
        ).thenAnswer(
          (_) async => ResultList<RecordModel>(
            page: 1,
            perPage: 1,
            totalItems: 1,
            totalPages: 1,
            items: [existingTag],
          ),
        );

        // getOne mock (for incrementUsageCount)
        when(
          () => mockRecordService.getOne(any()),
        ).thenAnswer((_) async => existingTag);

        // update mock
        when(
          () => mockRecordService.update(any(), body: any(named: 'body')),
        ).thenAnswer((_) async => existingTag);

        // Act
        final tag = await tagService.getOrCreateTag(name: '구피');

        // Assert
        expect(tag.name, '구피');
        expect(tag.usageCount, 151); // 150 + 1
      });

      test('새 태그를 생성한다', () async {
        // Arrange
        final newTag = RecordModel({
          'id': 'tag_new',
          'name': '새태그',
          'usage_count': 1,
          'category': 'general',
          'created': '2024-01-15T10:00:00Z',
        });

        // getTagByName mock (태그 없음)
        when(
          () => mockRecordService.getList(
            page: 1,
            perPage: 1,
            filter: 'name = "새태그"',
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

        // create mock
        when(
          () => mockRecordService.create(body: any(named: 'body')),
        ).thenAnswer((_) async => newTag);

        // Act
        final tag = await tagService.getOrCreateTag(
          name: '새태그',
          category: 'general',
        );

        // Assert
        expect(tag.name, '새태그');
        expect(tag.usageCount, 1);

        verify(
          () => mockRecordService.create(
            body: {'name': '새태그', 'usage_count': 1, 'category': 'general'},
          ),
        ).called(1);
      });
    });

    group('incrementUsageCount', () {
      test('태그 사용량을 증가시킨다', () async {
        // Arrange
        final mockRecord = RecordModel({
          'id': 'tag_1',
          'name': '구피',
          'usage_count': 100,
        });

        when(
          () => mockRecordService.getOne('tag_1'),
        ).thenAnswer((_) async => mockRecord);
        when(
          () => mockRecordService.update(any(), body: any(named: 'body')),
        ).thenAnswer((_) async => mockRecord);

        // Act
        await tagService.incrementUsageCount('tag_1');

        // Assert
        verify(
          () => mockRecordService.update('tag_1', body: {'usage_count': 101}),
        ).called(1);
      });
    });

    group('decrementUsageCount', () {
      test('태그 사용량을 감소시킨다', () async {
        // Arrange
        final mockRecord = RecordModel({
          'id': 'tag_1',
          'name': '구피',
          'usage_count': 100,
        });

        when(
          () => mockRecordService.getOne('tag_1'),
        ).thenAnswer((_) async => mockRecord);
        when(
          () => mockRecordService.update(any(), body: any(named: 'body')),
        ).thenAnswer((_) async => mockRecord);

        // Act
        await tagService.decrementUsageCount('tag_1');

        // Assert
        verify(
          () => mockRecordService.update('tag_1', body: {'usage_count': 99}),
        ).called(1);
      });

      test('사용량이 0 이하로 내려가지 않는다', () async {
        // Arrange
        final mockRecord = RecordModel({
          'id': 'tag_1',
          'name': '구피',
          'usage_count': 0,
        });

        when(
          () => mockRecordService.getOne('tag_1'),
        ).thenAnswer((_) async => mockRecord);
        when(
          () => mockRecordService.update(any(), body: any(named: 'body')),
        ).thenAnswer((_) async => mockRecord);

        // Act
        await tagService.decrementUsageCount('tag_1');

        // Assert
        verify(
          () => mockRecordService.update('tag_1', body: {'usage_count': 0}),
        ).called(1);
      });
    });

    group('getAllTags', () {
      test('모든 태그를 조회한다', () async {
        // Arrange
        final mockRecords = [
          RecordModel({
            'id': 'tag_1',
            'name': '가',
            'usage_count': 10,
            'created': '2024-01-15T10:00:00Z',
          }),
          RecordModel({
            'id': 'tag_2',
            'name': '나',
            'usage_count': 20,
            'created': '2024-01-14T10:00:00Z',
          }),
        ];

        final mockResult = ResultList<RecordModel>(
          page: 1,
          perPage: 100,
          totalItems: 2,
          totalPages: 1,
          items: mockRecords,
        );

        when(
          () => mockRecordService.getList(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
            sort: any(named: 'sort'),
          ),
        ).thenAnswer((_) async => mockResult);

        // Act
        final tags = await tagService.getAllTags();

        // Assert
        expect(tags.length, 2);
        expect(tags[0].name, '가');
        expect(tags[1].name, '나');
      });
    });
  });
}
