import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/services/creature_catalog_service.dart';
import '../../../domain/models/aquarium_data.dart';
import '../../../domain/models/creature_catalog_data.dart';
import '../../../theme/app_colors.dart';
import 'creature_register_screen.dart';

/// 생물 검색 결과 아이템 모델
class CreatureSearchItem {
  final String id;
  final String name;
  final String category;
  final String? imageUrl;

  const CreatureSearchItem({
    required this.id,
    required this.name,
    required this.category,
    this.imageUrl,
  });

  factory CreatureSearchItem.fromCatalog(CreatureCatalogData catalog) {
    return CreatureSearchItem(
      id: catalog.id ?? '',
      name: catalog.name,
      category: catalog.category,
      imageUrl: catalog.imageUrl,
    );
  }
}

/// 생물 검색 화면
///
/// creature_catalog API를 사용하여 생물을 검색하고 선택합니다.
class CreatureSearchScreen extends StatefulWidget {
  const CreatureSearchScreen({super.key});

  @override
  State<CreatureSearchScreen> createState() => _CreatureSearchScreenState();
}

class _CreatureSearchScreenState extends State<CreatureSearchScreen> {
  static const String _recentSearchesKey = 'creature_recent_searches';

  final TextEditingController _searchController = TextEditingController();
  final _catalogService = CreatureCatalogService.instance;

  List<CreatureSearchItem> _searchResults = [];
  List<CreatureSearchItem> _suggestions = [];
  List<String> _recentSearches = [];
  bool _isSearching = false;
  bool _isLoading = false;
  AquariumData? _aquarium;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadRecentSearches();
    _loadSuggestions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is AquariumData) {
      _aquarium = args;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final searches = prefs.getStringList(_recentSearchesKey) ?? [];
    if (mounted) {
      setState(() => _recentSearches = searches);
    }
  }

  Future<void> _saveRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentSearchesKey, _recentSearches);
  }

  Future<void> _loadSuggestions() async {
    try {
      final catalogs = await _catalogService.getSuggested(limit: 5);
      if (mounted) {
        setState(() {
          _suggestions = catalogs
              .map((c) => CreatureSearchItem.fromCatalog(c))
              .toList();
        });
      }
    } catch (_) {
      // 추천 로딩 실패 시 무시
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    setState(() => _isSearching = query.isNotEmpty);

    _debounce?.cancel();
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);
    try {
      final catalogs = await _catalogService.search(query);
      if (mounted) {
        setState(() {
          _searchResults = catalogs
              .map((c) => CreatureSearchItem.fromCatalog(c))
              .toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSuggestionTap(CreatureSearchItem creature) {
    _addToRecentSearches(creature.name);
    _searchController.text = creature.name;
  }

  void _addToRecentSearches(String searchTerm) {
    setState(() {
      _recentSearches.remove(searchTerm);
      _recentSearches.insert(0, searchTerm);
      if (_recentSearches.length > 10) {
        _recentSearches.removeLast();
      }
    });
    _saveRecentSearches();
  }

  void _onRecentSearchTap(String searchTerm) {
    _searchController.text = searchTerm;
  }

  void _onRemoveRecentSearch(String searchTerm) {
    setState(() => _recentSearches.remove(searchTerm));
    _saveRecentSearches();
  }

  void _onClearAllRecentSearches() {
    setState(() => _recentSearches.clear());
    _saveRecentSearches();
  }

  void _onCreatureSelect(CreatureSearchItem creature) {
    _addToRecentSearches(creature.name);
    Navigator.pop(context, creature);
  }

  void _onAddCreature() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatureRegisterScreen(
          aquariumId: _aquarium?.id,
          creatureName: _searchController.text,
        ),
      ),
    );
    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            _buildSearchField(),
            const SizedBox(height: 24),
            if (_isSearching)
              _buildSearchResults()
            else
              _buildDefaultContent(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(
          Icons.arrow_back_ios,
          color: AppColors.textMain,
          size: 24,
        ),
      ),
      title: const Text(
        '생물 검색',
        style: TextStyle(
          fontFamily: 'WantedSans',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textMain,
          height: 26 / 18,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.backgroundDisabled,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: '생물 이름을 검색하세요',
                  hintStyle: TextStyle(
                    fontFamily: 'WantedSans',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textHint,
                    height: 24 / 16,
                    letterSpacing: -0.5,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: const TextStyle(
                  fontFamily: 'WantedSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textMain,
                  height: 24 / 16,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search, color: AppColors.textMain, size: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_recentSearches.isNotEmpty) ...[
          _buildRecentSearchSection(),
          const SizedBox(height: 32),
        ],
        if (_suggestions.isNotEmpty) _buildSuggestions(),
      ],
    );
  }

  Widget _buildRecentSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '최근 검색어',
                style: TextStyle(
                  fontFamily: 'WantedSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                  height: 24 / 16,
                  letterSpacing: -0.5,
                ),
              ),
              GestureDetector(
                onTap: _onClearAllRecentSearches,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Text(
                    '전체 삭제',
                    style: TextStyle(
                      fontFamily: 'WantedSans',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.disabledText,
                      height: 20 / 14,
                      letterSpacing: -0.25,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recentSearches
                .map((search) => _buildRecentSearchChip(search))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentSearchChip(String searchTerm) {
    return GestureDetector(
      onTap: () => _onRecentSearchTap(searchTerm),
      child: Container(
        padding: const EdgeInsets.only(left: 16, right: 8),
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              searchTerm,
              style: const TextStyle(
                fontFamily: 'WantedSans',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textMain,
                height: 20 / 14,
                letterSpacing: -0.25,
              ),
            ),
            GestureDetector(
              onTap: () => _onRemoveRecentSearch(searchTerm),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: AppColors.textMain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '이런 생물을 찾으시나요?',
            style: TextStyle(
              fontFamily: 'WantedSans',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textMain,
              height: 26 / 18,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions
                .map((creature) => _buildSuggestionChip(creature))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(CreatureSearchItem creature) {
    return GestureDetector(
      onTap: () => _onSuggestionTap(creature),
      child: Container(
        padding: const EdgeInsets.only(left: 8, right: 16, top: 4, bottom: 4),
        decoration: BoxDecoration(
          color: AppColors.backgroundDisabled,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF3D5A80),
                shape: BoxShape.circle,
              ),
              child: creature.imageUrl != null
                  ? ClipOval(
                      child: Image.network(
                        creature.imageUrl!,
                        fit: BoxFit.cover,
                        width: 32,
                        height: 32,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.pets,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    )
                  : const Icon(Icons.pets, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            Text(
              creature.name,
              style: const TextStyle(
                fontFamily: 'WantedSans',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textMain,
                height: 20 / 14,
                letterSpacing: -0.25,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading && _searchResults.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return _buildEmptySearchResult();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => const Divider(
        height: 1,
        color: AppColors.borderLight,
      ),
      itemBuilder: (context, index) {
        final creature = _searchResults[index];
        return _buildSearchResultItem(creature);
      },
    );
  }

  Widget _buildSearchResultItem(CreatureSearchItem creature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF3D5A80),
              shape: BoxShape.circle,
            ),
            child: creature.imageUrl != null
                ? ClipOval(
                    child: Image.network(
                      creature.imageUrl!,
                      fit: BoxFit.cover,
                      width: 48,
                      height: 48,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.pets,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  )
                : const Icon(Icons.pets, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Text(
                  creature.name,
                  style: const TextStyle(
                    fontFamily: 'WantedSans',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMain,
                    height: 24 / 16,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  creature.category,
                  style: const TextStyle(
                    fontFamily: 'WantedSans',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSubtle,
                    height: 20 / 14,
                    letterSpacing: -0.25,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _onCreatureSelect(creature),
            child: Text(
              '선택',
              style: TextStyle(
                fontFamily: 'WantedSans',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.brand,
                height: 20 / 14,
                letterSpacing: -0.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearchResult() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 176),
          const Text(
            '찾으시는 생물이 없나요?',
            style: TextStyle(
              fontFamily: 'WantedSans',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textMain,
              height: 26 / 18,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          GestureDetector(
            onTap: _onAddCreature,
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.brand,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: Colors.white, size: 24),
                  SizedBox(width: 8),
                  Text(
                    '생물 추가하기',
                    style: TextStyle(
                      fontFamily: 'WantedSans',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.backgroundApp,
                      height: 24 / 16,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
