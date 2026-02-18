import 'package:flutter_test/flutter_test.dart';
import 'package:oomool/domain/models/record_data.dart';

void main() {
  group('RecordTag', () {
    test('fromValue returns correct tag', () {
      expect(RecordTag.fromValue('water_change'), RecordTag.waterChange);
      expect(RecordTag.fromValue('feeding'), RecordTag.feeding);
      expect(RecordTag.fromValue('cleaning'), RecordTag.cleaning);
    });

    test('fromValue returns null for invalid value', () {
      expect(RecordTag.fromValue('invalid'), isNull);
      expect(RecordTag.fromValue(null), isNull);
    });

    test('activityTags does not include medication', () {
      expect(RecordTag.activityTags, isNot(contains(RecordTag.medication)));
    });
  });

  group('RecordType', () {
    test('fromValue returns correct type', () {
      expect(RecordType.fromValue('todo'), RecordType.todo);
      expect(RecordType.fromValue('activity'), RecordType.activity);
      expect(RecordType.fromValue('diary'), RecordType.diary);
    });

    test('fromValue returns todo as default', () {
      expect(RecordType.fromValue(null), RecordType.todo);
      expect(RecordType.fromValue('unknown'), RecordType.todo);
    });
  });

  group('RecordData', () {
    test('toJson produces correct map', () {
      final record = RecordData(
        aquariumId: 'aq1',
        creatureId: 'cr1',
        recordType: RecordType.activity,
        date: DateTime(2025, 6, 15, 10, 30),
        tags: [RecordTag.waterChange, RecordTag.feeding],
        content: '물갈이 완료',
        isPublic: false,
        isCompleted: true,
      );

      final json = record.toJson();
      expect(json['aquarium'], 'aq1');
      expect(json['creature'], 'cr1');
      expect(json['record_type'], 'activity');
      expect(json['tags'], ['water_change', 'feeding']);
      expect(json['content'], '물갈이 완료');
      expect(json['is_public'], false);
      expect(json['is_completed'], true);
    });

    test('fromJson creates correct RecordData', () {
      final json = {
        'id': 'rec1',
        'owner': 'user1',
        'aquarium': 'aq1',
        'creature': 'cr1',
        'record_type': 'diary',
        'date': '2025-06-15T10:30:00.000',
        'tags': ['water_change'],
        'content': '일기 내용',
        'is_public': true,
        'is_completed': false,
        'created': '2025-06-15T10:30:00.000',
        'updated': '2025-06-15T11:00:00.000',
      };

      final record = RecordData.fromJson(json);
      expect(record.id, 'rec1');
      expect(record.ownerId, 'user1');
      expect(record.aquariumId, 'aq1');
      expect(record.creatureId, 'cr1');
      expect(record.recordType, RecordType.diary);
      expect(record.date.year, 2025);
      expect(record.date.month, 6);
      expect(record.tags.length, 1);
      expect(record.tags.first, RecordTag.waterChange);
      expect(record.content, '일기 내용');
    });

    test('fromJson handles empty creature', () {
      final json = {
        'id': 'rec1',
        'owner': 'user1',
        'aquarium': 'aq1',
        'creature': '',
        'record_type': 'todo',
        'date': '2025-06-15T10:30:00.000',
        'tags': [],
        'content': '',
        'is_public': true,
        'is_completed': false,
      };

      final record = RecordData.fromJson(json);
      expect(record.creatureId, isNull);
    });

    test('fromJson handles null tags', () {
      final json = {
        'id': 'rec1',
        'date': '2025-06-15T10:30:00.000',
        'content': 'test',
      };

      final record = RecordData.fromJson(json);
      expect(record.tags, isEmpty);
    });

    test('toJson and fromJson roundtrip', () {
      final original = RecordData(
        date: DateTime(2025, 6, 15),
        tags: [RecordTag.cleaning, RecordTag.waterTest],
        content: '테스트 기록',
        recordType: RecordType.activity,
      );

      final json = original.toJson();
      // fromJson requires id and date, simulate server response
      json['id'] = 'test_id';
      json['date'] = original.date.toIso8601String();
      final restored = RecordData.fromJson(json);

      expect(restored.content, original.content);
      expect(restored.recordType, original.recordType);
      expect(restored.tags.length, original.tags.length);
    });
  });
}
