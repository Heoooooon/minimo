class CreatureCatalogText {
  static const int maxCategoryLength = 50;
  static const int maxNameLength = 100;

  static const List<String> bannedSubstrings = ['씨발', '병신', '좆', 'fuck'];

  static bool containsBannedSubstring(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return false;

    final lower = trimmed.toLowerCase();
    for (final w in bannedSubstrings) {
      if (w.isEmpty) continue;
      if (lower.contains(w.toLowerCase())) return true;
    }
    return false;
  }

  static ({String category, String name})? parseCategoryAndName(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final parts = trimmed
        .split('/')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.length >= 2) {
      final category = parts.last;
      final name = parts.sublist(0, parts.length - 1).join('/');
      return (category: category, name: name);
    }

    return (category: '미분류', name: trimmed);
  }

  static String normalizeCategory(String raw) {
    return _normalizeSegment(raw);
  }

  static String normalizeName(String raw) {
    return _normalizeSegment(raw);
  }

  static String buildNormalizedKey({
    required String category,
    required String name,
  }) {
    final c = normalizeCategory(category);
    final n = normalizeName(name);
    return '$c/$n';
  }

  static String _normalizeSegment(String raw) {
    final noSlash = raw.replaceAll('/', ' ');
    final compact = noSlash.trim().replaceAll(RegExp(r'\s+'), ' ');
    final noSpaces = compact.replaceAll(' ', '');
    final safe = noSpaces.replaceAll(RegExp(r"[^0-9A-Za-z가-힣]+"), '');
    return safe.toLowerCase();
  }
}
