import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pocketbase_service.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/pb_filter.dart';

/// 데이터 백업/복원 서비스
///
/// 사용자의 PocketBase 데이터를 JSON으로 내보내기/가져오기
/// 기록 데이터를 CSV로 내보내기
class DataBackupService {
  DataBackupService._();

  static DataBackupService? _instance;
  static DataBackupService get instance => _instance ??= DataBackupService._();

  PocketBase get _pb => PocketBaseService.instance.client;
  bool get _isLoggedIn => _pb.authStore.isValid;
  String? get _currentUserId => _pb.authStore.record?.id;

  static const String _autoBackupKey = 'auto_backup_enabled';
  static const String _lastBackupKey = 'last_backup_date';

  /// 백업 대상 컬렉션과 사용자 필터 필드
  static const Map<String, String> _userCollections = {
    'aquariums': 'owner',
    'creatures': 'aquarium.owner',
    'creature_memos': 'creature.aquarium.owner',
    'records': 'aquarium.owner',
    'schedules': 'aquarium.owner',
    'gallery_photos': 'aquarium.owner',
  };

  // ============================================
  // 자동 백업 설정
  // ============================================

  /// 자동 백업 활성화 여부
  Future<bool> isAutoBackupEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoBackupKey) ?? false;
  }

  /// 자동 백업 설정 변경
  Future<void> setAutoBackup(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoBackupKey, enabled);
    AppLogger.data('Auto backup set to: $enabled');
  }

  /// 마지막 백업 일시 조회
  Future<DateTime?> getLastBackupDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString(_lastBackupKey);
    if (dateStr == null) return null;
    return DateTime.tryParse(dateStr);
  }

  /// 마지막 백업 일시 저장
  Future<void> _saveLastBackupDate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastBackupKey, DateTime.now().toIso8601String());
  }

  /// 자동 백업 실행 (앱 시작 시 호출)
  ///
  /// 자동 백업이 활성화되어 있고, 마지막 백업으로부터 24시간 이상 경과한 경우 백업 수행
  Future<void> performAutoBackupIfNeeded() async {
    if (!_isLoggedIn) return;

    final enabled = await isAutoBackupEnabled();
    if (!enabled) return;

    final lastBackup = await getLastBackupDate();
    final now = DateTime.now();

    // 마지막 백업이 없거나 24시간 이상 경과한 경우
    if (lastBackup == null || now.difference(lastBackup).inHours >= 24) {
      try {
        await backupToLocal();
        AppLogger.data('Auto backup completed');
      } catch (e) {
        AppLogger.data('Auto backup failed: $e', isError: true);
      }
    }
  }

  // ============================================
  // 데이터 백업 (JSON)
  // ============================================

  /// 사용자의 모든 데이터를 JSON으로 수집
  Future<Map<String, dynamic>> _collectUserData() async {
    final userId = _currentUserId;
    if (userId == null) {
      throw const AuthException(message: '로그인이 필요합니다.', code: 'LOGIN_REQUIRED');
    }

    final collectionsData = <String, dynamic>{};
    final exportData = <String, dynamic>{
      'exportVersion': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'userId': userId,
      'collections': collectionsData,
    };

    final tasks = _userCollections.entries.map((entry) async {
      final collectionName = entry.key;
      final ownerField = entry.value;

      try {
        final records = await _pb
            .collection(collectionName)
            .getFullList(
              filter: PbFilter.eq(ownerField, userId),
              sort: '-created',
            );

        AppLogger.data('Exported $collectionName: ${records.length} records');
        return MapEntry<String, dynamic>(
          collectionName,
          records.map((r) => r.toJson()).toList(),
        );
      } catch (e) {
        AppLogger.data('Failed to export $collectionName: $e', isError: true);
        return MapEntry<String, dynamic>(collectionName, []);
      }
    }).toList();

    final results = await Future.wait(tasks);
    for (final result in results) {
      collectionsData[result.key] = result.value;
    }

    return exportData;
  }

  /// 로컬 저장소에 백업 파일 저장
  Future<String> backupToLocal() async {
    final data = await _collectUserData();
    final jsonString = const JsonEncoder.withIndent('  ').convert(data);

    final docDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${docDir.path}/backups');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final file = File('${backupDir.path}/minimo_backup_$timestamp.json');
    await file.writeAsString(jsonString);

    await _saveLastBackupDate();
    AppLogger.data('Backup saved to: ${file.path}');

    return file.path;
  }

  /// 가장 최근 로컬 백업 파일 경로 조회
  Future<File?> getLatestBackupFile() async {
    final docDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${docDir.path}/backups');
    if (!await backupDir.exists()) return null;

    final files = await backupDir
        .list()
        .where((f) => f.path.endsWith('.json'))
        .toList();
    if (files.isEmpty) return null;

    // 수정 시간 기준 정렬
    files.sort((a, b) {
      final aStat = File(a.path).statSync();
      final bStat = File(b.path).statSync();
      return bStat.modified.compareTo(aStat.modified);
    });

    return File(files.first.path);
  }

  // ============================================
  // 데이터 복원 (JSON)
  // ============================================

  /// JSON 파일에서 데이터 복원
  Future<ImportResult> restoreFromJson(String jsonString) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw const AuthException(message: '로그인이 필요합니다.', code: 'LOGIN_REQUIRED');
    }

    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    final collections = data['collections'] as Map<String, dynamic>? ?? {};

    int imported = 0;
    int failed = 0;
    final errors = <String>[];

    // aquariums 먼저 복원 (다른 컬렉션이 참조)
    final orderedCollections = [
      'aquariums',
      'creatures',
      'creature_memos',
      'records',
      'schedules',
      'gallery_photos',
    ];

    // 기존 어항 ID → 새 어항 ID 매핑
    final idMap = <String, String>{};

    for (final collectionName in orderedCollections) {
      final records = collections[collectionName] as List? ?? [];
      for (final record in records) {
        try {
          final body = Map<String, dynamic>.from(record as Map);
          final oldId = body['id'] as String?;

          // 시스템 필드 제거
          body.remove('id');
          body.remove('created');
          body.remove('updated');
          body.remove('collectionId');
          body.remove('collectionName');
          body.remove('expand');

          // owner/관계 필드 재매핑
          switch (collectionName) {
            case 'aquariums':
              body['owner'] = userId;
              break;
            case 'creatures':
            case 'records':
            case 'schedules':
            case 'gallery_photos':
              final oldAquariumId = body['aquarium'] as String?;
              if (oldAquariumId != null && idMap.containsKey(oldAquariumId)) {
                body['aquarium'] = idMap[oldAquariumId];
              }
              break;
            case 'creature_memos':
              final oldCreatureId = body['creature'] as String?;
              if (oldCreatureId != null && idMap.containsKey(oldCreatureId)) {
                body['creature'] = idMap[oldCreatureId];
              }
              break;
          }

          final created = await _pb
              .collection(collectionName)
              .create(body: body);

          // ID 매핑 저장
          if (oldId != null) {
            idMap[oldId] = created.id;
          }

          imported++;
        } catch (e) {
          failed++;
          errors.add('$collectionName: $e');
          AppLogger.data(
            'Failed to import $collectionName record: $e',
            isError: true,
          );
        }
      }
    }

    AppLogger.data('Import complete: $imported success, $failed failed');
    return ImportResult(imported: imported, failed: failed, errors: errors);
  }

  // ============================================
  // 기록 CSV 내보내기
  // ============================================

  /// 기록 데이터를 CSV 형식으로 내보내기 (share_plus 공유)
  Future<void> exportRecordsCsv() async {
    final userId = _currentUserId;
    if (userId == null) {
      throw const AuthException(message: '로그인이 필요합니다.', code: 'LOGIN_REQUIRED');
    }

    final records = await _pb
        .collection('records')
        .getFullList(
          filter: PbFilter.eq('aquarium.owner', userId),
          sort: '-date',
        );

    // CSV 생성
    final buffer = StringBuffer();
    buffer.writeln('날짜,유형,태그,내용,공개여부,완료여부');

    for (final record in records) {
      final date = record.getStringValue('date');
      final type = record.getStringValue('type');
      final tags = record.getListValue<String>('tags').join(';');
      final content = _escapeCsv(record.getStringValue('content'));
      final isPublic = record.getBoolValue('isPublic') ? 'Y' : 'N';
      final isCompleted = record.getBoolValue('isCompleted') ? 'Y' : 'N';

      buffer.writeln('$date,$type,$tags,$content,$isPublic,$isCompleted');
    }

    // 파일 저장 후 공유
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${tempDir.path}/minimo_records_$timestamp.csv');
    await file.writeAsString(
      buffer.toString(),
      encoding: const Utf8Codec(allowMalformed: true),
    );

    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: '우물 기록 데이터'),
    );

    AppLogger.data('CSV exported: ${records.length} records');
  }

  /// CSV 특수문자 이스케이프
  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}

/// 데이터 가져오기 결과
class ImportResult {
  const ImportResult({
    required this.imported,
    required this.failed,
    required this.errors,
  });

  /// 성공 건수
  final int imported;

  /// 실패 건수
  final int failed;

  /// 에러 상세
  final List<String> errors;

  /// 전체 성공 여부
  bool get isSuccess => failed == 0;
}
