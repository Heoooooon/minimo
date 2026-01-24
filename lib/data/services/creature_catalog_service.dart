import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:pocketbase/pocketbase.dart';

import '../../core/utils/app_logger.dart';
import '../../domain/models/creature_catalog_data.dart';
import '../../domain/utils/creature_catalog_text.dart';
import 'auth_service.dart';
import 'pocketbase_service.dart';

class CreatureCatalogService {
  CreatureCatalogService._();

  static CreatureCatalogService? _instance;
  static CreatureCatalogService get instance =>
      _instance ??= CreatureCatalogService._();

  PocketBase get _pb => PocketBaseService.instance.client;
  String get _baseUrl => PocketBaseService.serverUrl;

  static const String _collection = 'creature_catalog';
  static const String _reportsCollection = 'creature_catalog_reports';

  Future<List<CreatureCatalogData>> getSuggested({int limit = 10}) async {
    try {
      final result = await _pb
          .collection(_collection)
          .getList(
            page: 1,
            perPage: limit,
            filter: "status = 'public' && report_count < 5",
            sort: '-created',
          );

      return result.items
          .map(
            (r) => CreatureCatalogData.fromJson(r.toJson(), baseUrl: _baseUrl),
          )
          .toList();
    } catch (e) {
      AppLogger.data(
        'Failed to get suggested catalog creatures: $e',
        isError: true,
      );
      rethrow;
    }
  }

  Future<List<CreatureCatalogData>> search(
    String query, {
    int limit = 50,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    try {
      final escaped = _escapeFilterValue(trimmed);
      final filter =
          "status = 'public' && report_count < 5 && (name ~ \"$escaped\" || category ~ \"$escaped\")";

      final result = await _pb
          .collection(_collection)
          .getList(
            page: 1,
            perPage: limit,
            filter: filter,
            sort: 'category,name',
          );

      return result.items
          .map(
            (r) => CreatureCatalogData.fromJson(r.toJson(), baseUrl: _baseUrl),
          )
          .toList();
    } catch (e) {
      AppLogger.data('Failed to search catalog creatures: $e', isError: true);
      rethrow;
    }
  }

  Future<CreatureCatalogData> createCatalogCreature(
    String category,
    String name, {
    String? imageFilePath,
  }) async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw StateError('Login required');
    }

    final trimmedCategory = category.trim();
    final trimmedName = name.trim();

    if (trimmedCategory.isEmpty || trimmedName.isEmpty) {
      throw ArgumentError('Category and name are required');
    }

    if (trimmedCategory.length > CreatureCatalogText.maxCategoryLength) {
      throw ArgumentError('Category is too long');
    }

    if (trimmedName.length > CreatureCatalogText.maxNameLength) {
      throw ArgumentError('Name is too long');
    }

    if (CreatureCatalogText.containsBannedSubstring(trimmedCategory) ||
        CreatureCatalogText.containsBannedSubstring(trimmedName)) {
      throw ArgumentError('Contains banned words');
    }

    final normalizedKey = CreatureCatalogText.buildNormalizedKey(
      category: trimmedCategory,
      name: trimmedName,
    );

    try {
      final body = {
        'category': trimmedCategory,
        'name': trimmedName,
        'normalized_key': normalizedKey,
        'created_by': userId,
        'status': 'public',
        'report_count': 0,
      };

      final files = <http.MultipartFile>[];
      if (imageFilePath != null && imageFilePath.trim().isNotEmpty) {
        final f = File(imageFilePath);
        if (await f.exists()) {
          files.add(await http.MultipartFile.fromPath('image', imageFilePath));
        }
      }

      final RecordModel record;
      if (files.isNotEmpty) {
        record = await _pb
            .collection(_collection)
            .create(body: body, files: files);
      } else {
        record = await _pb.collection(_collection).create(body: body);
      }

      return CreatureCatalogData.fromJson(record.toJson(), baseUrl: _baseUrl);
    } catch (e) {
      AppLogger.data('Failed to create catalog creature: $e', isError: true);
      rethrow;
    }
  }

  Future<void> reportCatalogCreature({
    required String catalogId,
    String? reason,
  }) async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw StateError('Login required');
    }

    try {
      await _pb
          .collection(_reportsCollection)
          .create(
            body: {
              'catalog_id': catalogId,
              'reporter_id': userId,
              'reason': reason?.trim(),
            },
          );

      final current = await _pb.collection(_collection).getOne(catalogId);
      final currentCount = current.getIntValue('report_count');
      await _pb
          .collection(_collection)
          .update(catalogId, body: {'report_count': currentCount + 1});
    } catch (e) {
      AppLogger.data('Failed to report catalog creature: $e', isError: true);
      rethrow;
    }
  }

  String _escapeFilterValue(String input) {
    return input.replaceAll('\\', r'\\').replaceAll('"', r'\"');
  }
}
