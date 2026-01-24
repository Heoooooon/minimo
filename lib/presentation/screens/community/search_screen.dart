import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../viewmodels/community_viewmodel.dart';
import '../../widgets/community/post_card.dart';
import '../../widgets/community/qna_question_card.dart';

/// 커뮤니티 검색 화면
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late TabController _tabController;

  // 검색 결과 상태
  List<PostData> _postResults = [];
  List<QnaQuestionData> _questionResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  // 최근 검색어
  final List<String> _recentSearches = [];

  // 인기 검색어 (예시 데이터)
  final List<String> _popularSearches = [
    '구피',
    '베타',
    '물갈이',
    '여과기',
    '수초',
    '합사',
    '질병',
    '초보',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // 화면 진입 시 검색창에 포커스
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    final viewModel = context.read<CommunityViewModel>();

    try {
      // 검색어를 최근 검색어에 추가
      _addToRecentSearches(query);

      // 게시글 검색 (content에서 검색)
      await viewModel.filterByTag(query);
      _postResults = viewModel.filteredPosts;

      // Q&A 검색은 별도 필터 필요 (현재 간단히 처리)
      // 실제 구현시 CommunityService에 searchQuestions 메서드 추가 필요
      _questionResults = viewModel.popularQuestions
          .where(
            (q) =>
                q.title.toLowerCase().contains(query.toLowerCase()) ||
                q.content.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _addToRecentSearches(String query) {
    // 중복 제거 후 맨 앞에 추가
    _recentSearches.remove(query);
    _recentSearches.insert(0, query);
    // 최대 10개 유지
    if (_recentSearches.length > 10) {
      _recentSearches.removeLast();
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _postResults = [];
      _questionResults = [];
      _hasSearched = false;
    });
    _focusNode.requestFocus();
  }

  void _onSearchSubmitted(String value) {
    if (value.trim().isNotEmpty) {
      _performSearch(value.trim());
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchHeader(),
            Expanded(
              child: _hasSearched ? _buildSearchResults() : _buildInitialView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      color: AppColors.backgroundSurface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // 뒤로가기 버튼
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.arrow_back_ios,
                size: 20,
                color: AppColors.textMain,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 검색 입력창
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.backgroundApp,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                onSubmitted: _onSearchSubmitted,
                textInputAction: TextInputAction.search,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textMain,
                ),
                decoration: InputDecoration(
                  hintText: '검색어를 입력하세요',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textHint,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.textHint,
                    size: 20,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? GestureDetector(
                          onTap: _clearSearch,
                          child: const Icon(
                            Icons.close,
                            color: AppColors.textHint,
                            size: 20,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  setState(() {}); // 클리어 버튼 표시/숨김 업데이트
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 최근 검색어
          if (_recentSearches.isNotEmpty) ...[
            _buildSectionHeader(
              title: '최근 검색어',
              onClear: () {
                setState(() {
                  _recentSearches.clear();
                });
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentSearches.map((search) {
                return _buildSearchChip(
                  search,
                  onTap: () {
                    _searchController.text = search;
                    _performSearch(search);
                  },
                  onDelete: () {
                    setState(() {
                      _recentSearches.remove(search);
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // 인기 검색어
          _buildSectionHeader(title: '인기 검색어'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _popularSearches.asMap().entries.map((entry) {
              final index = entry.key;
              final search = entry.value;
              return _buildRankedSearchChip(
                rank: index + 1,
                text: search,
                onTap: () {
                  _searchController.text = search;
                  _performSearch(search);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required String title, VoidCallback? onClear}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.textMain,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (onClear != null)
          GestureDetector(
            onTap: onClear,
            child: Text(
              '전체 삭제',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSubtle,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchChip(
    String text, {
    required VoidCallback onTap,
    VoidCallback? onDelete,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.backgroundSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMain,
              ),
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRankedSearchChip({
    required int rank,
    required String text,
    required VoidCallback onTap,
  }) {
    final isTop3 = rank <= 3;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isTop3 ? AppColors.chipPrimaryBg : AppColors.backgroundSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isTop3
                ? AppColors.brand.withValues(alpha: 0.3)
                : AppColors.borderLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$rank',
              style: AppTextStyles.captionMedium.copyWith(
                color: isTop3 ? AppColors.brand : AppColors.textSubtle,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: isTop3 ? AppColors.brand : AppColors.textMain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Column(
      children: [
        // 탭 바
        Container(
          color: AppColors.backgroundSurface,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.brand,
            unselectedLabelColor: AppColors.textSubtle,
            indicatorColor: AppColors.brand,
            indicatorWeight: 2,
            labelStyle: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: AppTextStyles.titleSmall,
            tabs: [
              Tab(text: '게시글 (${_postResults.length})'),
              Tab(text: 'Q&A (${_questionResults.length})'),
            ],
          ),
        ),

        // 탭 뷰
        Expanded(
          child: _isSearching
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.brand),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPostResultsList(),
                    _buildQuestionResultsList(),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildPostResultsList() {
    if (_postResults.isEmpty) {
      return _buildEmptyResult('게시글');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _postResults.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final post = _postResults[index];
        return PostCard(
          data: post,
          onTap: () {
            Navigator.pushNamed(context, '/post-detail', arguments: post.id);
          },
        );
      },
    );
  }

  Widget _buildQuestionResultsList() {
    if (_questionResults.isEmpty) {
      return _buildEmptyResult('Q&A');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _questionResults.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final question = _questionResults[index];
        return QnaPopularCard(
          data: question,
          onTap: () {
            Navigator.pushNamed(
              context,
              '/question-detail',
              arguments: question.id,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyResult(String type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.textHint.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '검색 결과가 없습니다',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textSubtle,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '다른 검색어로 $type을 찾아보세요',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}
