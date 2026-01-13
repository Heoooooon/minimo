import 'package:flutter/material.dart';
import '../../../domain/models/aquarium_data.dart';
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
}

/// 하드코딩된 생물 데이터
class CreatureDatabase {
  static const List<CreatureSearchItem> suggestedCreatures = [
    CreatureSearchItem(id: '1', name: '하프문 베타', category: '베타'),
    CreatureSearchItem(id: '2', name: '니모', category: '해수어'),
    CreatureSearchItem(id: '3', name: '구피', category: '구피'),
    CreatureSearchItem(id: '4', name: '플라캣 베타', category: '베타'),
    CreatureSearchItem(id: '5', name: '네온테트라', category: '테트라'),
  ];

  static const List<CreatureSearchItem> allCreatures = [
    // 구피 종류
    CreatureSearchItem(id: '3', name: '구피', category: '구피'),
    CreatureSearchItem(id: '10', name: '알비노 풀레드', category: '구피'),
    CreatureSearchItem(id: '11', name: '몽키 바나나', category: '구피'),
    CreatureSearchItem(id: '12', name: '풀블랙', category: '구피'),
    CreatureSearchItem(id: '13', name: '코이 글라스벨리', category: '구피'),
    CreatureSearchItem(id: '14', name: '시크릿 바이올렛', category: '구피'),
    CreatureSearchItem(id: '15', name: '블루 모자이크', category: '구피'),
    CreatureSearchItem(id: '16', name: '레드 코브라', category: '구피'),

    // 베타 종류
    CreatureSearchItem(id: '1', name: '하프문 베타', category: '베타'),
    CreatureSearchItem(id: '4', name: '플라캣 베타', category: '베타'),
    CreatureSearchItem(id: '20', name: '크라운테일 베타', category: '베타'),
    CreatureSearchItem(id: '21', name: '덤보 베타', category: '베타'),

    // 테트라 종류
    CreatureSearchItem(id: '5', name: '네온테트라', category: '테트라'),
    CreatureSearchItem(id: '30', name: '카디날 테트라', category: '테트라'),
    CreatureSearchItem(id: '31', name: '블랙 네온 테트라', category: '테트라'),

    // 해수어
    CreatureSearchItem(id: '2', name: '니모', category: '해수어'),
    CreatureSearchItem(id: '40', name: '블루탱', category: '해수어'),
    CreatureSearchItem(id: '41', name: '옐로우탱', category: '해수어'),

    // 기타
    CreatureSearchItem(id: '50', name: '금붕어', category: '금붕어'),
    CreatureSearchItem(id: '51', name: '코리도라스', category: '코리도라스'),
    CreatureSearchItem(id: '52', name: '플레코', category: '플레코'),
  ];

  static List<CreatureSearchItem> search(String query) {
    if (query.isEmpty) return [];
    final lowerQuery = query.toLowerCase();
    return allCreatures
        .where((c) =>
            c.name.toLowerCase().contains(lowerQuery) ||
            c.category.toLowerCase().contains(lowerQuery))
        .toList();
  }
}

/// 생물 검색 화면
///
/// Figma 디자인 기반 - 생물 검색 및 선택
class CreatureSearchScreen extends StatefulWidget {
  const CreatureSearchScreen({super.key});

  @override
  State<CreatureSearchScreen> createState() => _CreatureSearchScreenState();
}

class _CreatureSearchScreenState extends State<CreatureSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<CreatureSearchItem> _searchResults = [];
  bool _isSearching = false;
  AquariumData? _aquarium;

  // 최근 검색어 목록
  final List<String> _recentSearches = ['청소 물고기', '구피', '니모', '플라캣 베타'];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
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
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    setState(() {
      _isSearching = query.isNotEmpty;
      _searchResults = CreatureDatabase.search(query);
    });
  }

  void _onSuggestionTap(CreatureSearchItem creature) {
    _addToRecentSearches(creature.name);
    _searchController.text = creature.name;
  }

  void _addToRecentSearches(String searchTerm) {
    setState(() {
      // 이미 있으면 제거 후 맨 앞에 추가
      _recentSearches.remove(searchTerm);
      _recentSearches.insert(0, searchTerm);
      // 최대 10개까지만 유지
      if (_recentSearches.length > 10) {
        _recentSearches.removeLast();
      }
    });
  }

  void _onRecentSearchTap(String searchTerm) {
    _searchController.text = searchTerm;
  }

  void _onRemoveRecentSearch(String searchTerm) {
    setState(() {
      _recentSearches.remove(searchTerm);
    });
  }

  void _onClearAllRecentSearches() {
    setState(() {
      _recentSearches.clear();
    });
  }

  void _onCreatureSelect(CreatureSearchItem creature) async {
    _addToRecentSearches(creature.name);
    // 등록 화면으로 이동
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatureRegisterScreen(
          aquariumId: _aquarium?.id,
          selectedCreature: creature,
        ),
      ),
    );
    // 등록 완료 시 이전 화면으로 돌아감
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
            // 검색 입력 필드
            _buildSearchField(),
            const SizedBox(height: 24),
            // 검색 결과 또는 기본 화면
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
                  hintText: 'Text Area',
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
              child: Icon(
                Icons.search,
                color: AppColors.textMain,
                size: 24,
              ),
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
        // 최근 검색어 섹션
        if (_recentSearches.isNotEmpty) ...[
          _buildRecentSearchSection(),
          const SizedBox(height: 32),
        ],
        // 추천 생물 섹션
        _buildSuggestions(),
      ],
    );
  }

  Widget _buildRecentSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 헤더
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
        // 최근 검색어 칩들
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
            children: CreatureDatabase.suggestedCreatures
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
            // 생물 이미지 (원형)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF3D5A80),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pets,
                color: Colors.white,
                size: 18,
              ),
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

  void _onAddCreature() async {
    // 검색어를 기반으로 새 생물 등록 화면으로 이동
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatureRegisterScreen(
          aquariumId: _aquarium?.id,
          creatureName: _searchController.text,
        ),
      ),
    );
    // 등록 완료 시 이전 화면으로 돌아감
    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Widget _buildSearchResults() {
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
          // 생물 이미지
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF3D5A80),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pets,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),

          // 생물 정보
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

          // 선택 버튼
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 24,
                  ),
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
