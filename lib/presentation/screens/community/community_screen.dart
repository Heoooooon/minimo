import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../viewmodels/community_viewmodel.dart';
import '../../widgets/community/post_card.dart';
import '../../widgets/community/recommendation_card.dart';
import '../../widgets/community/popular_ranking_card.dart';
import '../../widgets/community/qna_question_card.dart';
import 'more_list_screen.dart';

/// 커뮤니티 탭 열거형
enum CommunityTab {
  recommend('추천'),
  following('팔로잉'),
  qna('Q&A');

  const CommunityTab(this.label);
  final String label;
}

/// Q&A 서브 탭 열거형
enum QnaSubTab {
  myQuestion('내 질문'),
  myAnswer('내 답변');

  const QnaSubTab(this.label);
  final String label;
}

/// 커뮤니티 화면 - Figma design 138:5253
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  CommunityTab _currentTab = CommunityTab.recommend;
  QnaSubTab _qnaSubTab = QnaSubTab.myQuestion;
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final showButton = _scrollController.offset > 200;
    if (showButton != _showScrollToTop) {
      setState(() {
        _showScrollToTop = showButton;
      });
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _onTabChanged(CommunityTab tab) {
    setState(() {
      _currentTab = tab;
    });

    final viewModel = context.read<CommunityViewModel>();

    switch (tab) {
      case CommunityTab.recommend:
        viewModel.loadRecommendTab();
        break;
      case CommunityTab.following:
        viewModel.loadFollowingTab();
        break;
      case CommunityTab.qna:
        viewModel.loadQnaTab();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      body: Consumer<CommunityViewModel>(
        builder: (context, viewModel, child) {
          return RefreshIndicator(
            onRefresh: () => viewModel.refreshAll(),
            color: AppColors.brand,
            child: Stack(
              children: [
                CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // Header (Fixed)
                    SliverToBoxAdapter(child: _buildHeader()),

                    // Loading Indicator
                    if (viewModel.isLoading)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.brand,
                            ),
                          ),
                        ),
                      ),

                    // Error Message
                    if (viewModel.errorMessage != null)
                      SliverToBoxAdapter(
                        child: _buildErrorWidget(viewModel.errorMessage!),
                      ),

                    // Content based on tab
                    if (!viewModel.isLoading && viewModel.errorMessage == null)
                      ..._buildTabContent(viewModel),

                    // Bottom padding for nav bar
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),

                // Scroll to Top Button
                if (_showScrollToTop)
                  Positioned(
                    right: 16,
                    bottom: 108,
                    child: _buildScrollToTopButton(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSubtle,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              context.read<CommunityViewModel>().refreshAll();
            },
            child: Text(
              '다시 시도',
              style: AppTextStyles.bodyMediumMedium.copyWith(
                color: AppColors.brand,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTabContent(CommunityViewModel viewModel) {
    switch (_currentTab) {
      case CommunityTab.recommend:
        return _buildRecommendTabContent(viewModel);
      case CommunityTab.following:
        return _buildFollowingTabContent(viewModel);
      case CommunityTab.qna:
        return _buildQnaTabContent(viewModel);
    }
  }

  // ============================================
  // Recommend Tab Content
  // ============================================
  List<Widget> _buildRecommendTabContent(CommunityViewModel viewModel) {
    // 태그 필터링 중인 경우
    if (viewModel.isFilteringByTag) {
      return _buildFilteredPostsContent(viewModel);
    }

    // 데이터가 없는 경우 빈 상태 표시
    if (viewModel.latestPosts.isEmpty &&
        viewModel.recommendationItems.isEmpty &&
        !viewModel.isLoading) {
      return [
        SliverToBoxAdapter(
          child: _buildEmptyState('아직 게시글이 없습니다.\n첫 번째 게시글을 작성해보세요!'),
        ),
      ];
    }

    return [
      // Popular Ranking Section
      if (viewModel.popularRanking != null)
        SliverToBoxAdapter(child: _buildPopularRankingSection(viewModel)),

      // Recommendation Section
      if (viewModel.recommendationItems.isNotEmpty)
        SliverToBoxAdapter(child: _buildRecommendationSection(viewModel)),

      // Latest Posts Section
      if (viewModel.latestPosts.isNotEmpty)
        SliverToBoxAdapter(child: _buildLatestPostsHeader()),

      // Post List
      if (viewModel.latestPosts.isNotEmpty)
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final post = viewModel.latestPosts[index];
            return PostCard(
              data: post,
              onTap: () => _navigateToPostDetail(post.id),
              onLikeTap: () => viewModel.toggleLike(post.id, !post.isLiked),
              onCommentTap: () => _navigateToPostDetail(post.id),
              onBookmarkTap: () =>
                  viewModel.toggleBookmark(post.id, !post.isBookmarked),
              onMoreTap: () => _showPostOptions(post.id),
            );
          }, childCount: viewModel.latestPosts.length),
        ),
    ];
  }

  // ============================================
  // Filtered Posts Content (태그 필터링 결과)
  // ============================================
  List<Widget> _buildFilteredPostsContent(CommunityViewModel viewModel) {
    return [
      // 필터링 헤더
      SliverToBoxAdapter(child: _buildFilteredPostsHeader(viewModel)),

      // 필터링된 게시글이 없는 경우
      if (viewModel.filteredPosts.isEmpty && !viewModel.isLoading)
        SliverToBoxAdapter(
          child: _buildEmptyState(
            '#${viewModel.selectedTag} 태그의 게시글이 없습니다.\n다른 태그를 선택해보세요!',
          ),
        ),

      // 필터링된 게시글 목록
      if (viewModel.filteredPosts.isNotEmpty)
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final post = viewModel.filteredPosts[index];
            return PostCard(
              data: post,
              onTap: () => _navigateToPostDetail(post.id),
              onLikeTap: () => viewModel.toggleLike(post.id, !post.isLiked),
              onCommentTap: () => _navigateToPostDetail(post.id),
              onBookmarkTap: () =>
                  viewModel.toggleBookmark(post.id, !post.isBookmarked),
              onMoreTap: () => _showPostOptions(post.id),
            );
          }, childCount: viewModel.filteredPosts.length),
        ),
    ];
  }

  Widget _buildFilteredPostsHeader(CommunityViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 선택된 태그 표시
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.brand,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '#${viewModel.selectedTag}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => viewModel.clearTagFilter(),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${viewModel.filteredPosts.length}개의 게시글',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSubtle,
                ),
              ),
              const Spacer(),
              // 필터 해제 버튼
              GestureDetector(
                onTap: () => viewModel.clearTagFilter(),
                child: Text(
                  '전체보기',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.brand,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.borderLight),
        ],
      ),
    );
  }

  // ============================================
  // Following Tab Content
  // ============================================
  List<Widget> _buildFollowingTabContent(CommunityViewModel viewModel) {
    if (viewModel.followingPosts.isEmpty && !viewModel.isLoading) {
      return [
        SliverToBoxAdapter(
          child: _buildEmptyState('팔로우한 사용자의 게시글이 없습니다.\n관심있는 사용자를 팔로우해보세요!'),
        ),
      ];
    }

    return [
      // Post List
      SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final post = viewModel.followingPosts[index];
          return PostCard(
            data: post,
            onTap: () => _navigateToPostDetail(post.id),
            onLikeTap: () => viewModel.toggleLike(post.id, !post.isLiked),
            onCommentTap: () => _navigateToPostDetail(post.id),
            onBookmarkTap: () =>
                viewModel.toggleBookmark(post.id, !post.isBookmarked),
            onMoreTap: () => _showPostOptions(post.id),
          );
        }, childCount: viewModel.followingPosts.length),
      ),
    ];
  }

  // ============================================
  // Q&A Tab Content
  // ============================================
  List<Widget> _buildQnaTabContent(CommunityViewModel viewModel) {
    return [
      // Ask Question Button
      SliverToBoxAdapter(child: _buildAskQuestionButton()),

      // Sub Tab Selector
      SliverToBoxAdapter(child: _buildQnaSubTabs()),

      // Popular Tags
      if (viewModel.qnaTags.isNotEmpty)
        SliverToBoxAdapter(child: _buildPopularTags(viewModel)),

      // Popular Q&A Section
      if (viewModel.popularQuestions.isNotEmpty)
        SliverToBoxAdapter(child: _buildPopularQnaSection(viewModel)),

      // Featured Question Card
      if (viewModel.featuredQuestion != null)
        SliverToBoxAdapter(child: _buildFeaturedQuestionCard(viewModel)),

      // Waiting Answer Section
      if (viewModel.waitingQuestions.isNotEmpty)
        SliverToBoxAdapter(child: _buildWaitingAnswerSection(viewModel)),

      // Empty State for Q&A
      if (viewModel.popularQuestions.isEmpty &&
          viewModel.waitingQuestions.isEmpty &&
          !viewModel.isLoading)
        SliverToBoxAdapter(
          child: _buildEmptyState('아직 질문이 없습니다.\n첫 번째 질문을 작성해보세요!'),
        ),
    ];
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSubtle,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAskQuestionButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, '/community-question');
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFFDFDFF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.edit_outlined,
                size: 20,
                color: AppColors.textSubtle,
              ),
              const SizedBox(width: 8),
              Text(
                '질문하기',
                style: AppTextStyles.bodyMediumMedium.copyWith(
                  color: AppColors.textSubtle,
                  fontSize: 16,
                  height: 24 / 16,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQnaSubTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: QnaSubTab.values.map((tab) {
          final isSelected = _qnaSubTab == tab;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _qnaSubTab = tab;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.brand : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected
                      ? null
                      : Border.all(color: AppColors.borderLight),
                ),
                child: Center(
                  child: Text(
                    tab.label,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isSelected ? Colors.white : AppColors.textSubtle,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 20 / 14,
                      letterSpacing: -0.25,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPopularTags(CommunityViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '인기 태그',
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textMain,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 20 / 14,
              letterSpacing: -0.25,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 32,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: viewModel.qnaTags.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final tag = viewModel.qnaTags[index];
              final isSelected =
                  viewModel.selectedTag == tag.replaceAll('#', '');
              return GestureDetector(
                onTap: () => _onTagTap(tag),
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.brand
                        : AppColors.chipPrimaryBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      tag,
                      style: AppTextStyles.captionMedium.copyWith(
                        color: isSelected ? Colors.white : AppColors.brand,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 18 / 12,
                        letterSpacing: -0.25,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPopularQnaSection(CommunityViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '실시간 인기 Q&A',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.textMain,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 26 / 18,
                  letterSpacing: -0.5,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/more-list',
                    arguments: MoreListType.popular,
                  );
                },
                child: Row(
                  children: [
                    Text(
                      '더보기',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.brand,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 20 / 14,
                        letterSpacing: -0.25,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: AppColors.brand,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Q&A List
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: viewModel.popularQuestions.map((item) {
              return Column(
                children: [
                  QnaPopularCard(
                    data: item,
                    onTap: () => _navigateToQuestionDetail(item.id),
                  ),
                  if (item != viewModel.popularQuestions.last)
                    const Divider(height: 1, color: AppColors.borderLight),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFeaturedQuestionCard(CommunityViewModel viewModel) {
    return Column(
      children: [
        QnaAskCard(
          userName: '미니모',
          question: viewModel.featuredQuestion!,
          onCuriousTap: () =>
              _onCuriousTap(viewModel, viewModel.featuredQuestion!.id),
          onAnswerTap: () =>
              _navigateToQuestionDetail(viewModel.featuredQuestion!.id),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildWaitingAnswerSection(CommunityViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '답변을 기다려요',
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textMain,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 26 / 18,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Waiting Answer List
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: viewModel.waitingQuestions.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: QnaWaitingCard(
                  data: item,
                  onTap: () => _navigateToQuestionDetail(item.id),
                  onCuriousTap: () => _onCuriousTap(viewModel, item.id),
                  onAnswerTap: () => _navigateToQuestionDetail(item.id),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ============================================
  // Common Widgets
  // ============================================
  Widget _buildHeader() {
    return Container(
      color: AppColors.backgroundApp,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 4, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '커뮤니티',
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: AppColors.textMain,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      height: 32 / 22,
                      letterSpacing: -0.25,
                    ),
                  ),
                  Row(
                    children: [
                      _buildIconButton(
                        icon: Icons.search,
                        onTap: () {
                          Navigator.pushNamed(context, '/search');
                        },
                      ),
                      _buildIconButton(
                        icon: Icons.notifications_outlined,
                        onTap: () {
                          Navigator.pushNamed(context, '/notifications');
                        },
                      ),
                      _buildIconButton(
                        icon: Icons.add_box_outlined,
                        onTap: () {
                          Navigator.pushNamed(context, '/post-create');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Tab Row
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Tabs
                  Row(
                    children: CommunityTab.values.map((tab) {
                      final isSelected = _currentTab == tab;
                      return GestureDetector(
                        onTap: () => _onTabChanged(tab),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                tab.label,
                                style: AppTextStyles.titleLarge.copyWith(
                                  color: isSelected
                                      ? AppColors.brand
                                      : AppColors.textSubtle,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  height: 26 / 18,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Container(
                                height: 1.5,
                                width: tab.label.length * 12.0,
                                color: isSelected
                                    ? AppColors.brand
                                    : Colors.transparent,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  // Profile Avatar
                  Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE8EBF0),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.person,
                        size: 18,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        child: Icon(icon, size: 24, color: AppColors.textMain),
      ),
    );
  }

  Widget _buildPopularRankingSection(CommunityViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '오늘 인기글',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.textMain,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 26 / 18,
                  letterSpacing: -0.5,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/more-list',
                    arguments: MoreListType.posts,
                  );
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDFDFF),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: AppColors.brand,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Ranking Card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: PopularRankingCard(
            data: viewModel.popularRanking!,
            onTap: () => _navigateToPostDetail(viewModel.popularRanking!.id),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildRecommendationSection(CommunityViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '미니모님이 좋아하실 만한 게시글',
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textMain,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 26 / 18,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Tags
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: viewModel.tags.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final tag = viewModel.tags[index];
              final isSelected =
                  viewModel.selectedTag == tag.replaceAll('#', '');
              return GestureDetector(
                onTap: () => _onTagTap(tag),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.brand
                        : AppColors.chipPrimaryBg,
                    borderRadius: BorderRadius.circular(4),
                    border: isSelected
                        ? null
                        : Border.all(
                            color: AppColors.brand.withValues(alpha: 0.3),
                          ),
                  ),
                  child: Center(
                    child: Text(
                      tag,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isSelected ? Colors.white : AppColors.brand,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 20 / 14,
                        letterSpacing: -0.25,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Recommendation Cards
        RecommendationCardList(
          items: viewModel.recommendationItems,
          onItemTap: (item) => _navigateToPostDetail(item.id),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildLatestPostsHeader() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '실시간 최신글',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.textMain,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 26 / 18,
                  letterSpacing: -0.5,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/more-list',
                    arguments: MoreListType.posts,
                  );
                },
                child: Row(
                  children: [
                    Text(
                      '더보기',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.brand,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 20 / 14,
                        letterSpacing: -0.25,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: AppColors.brand,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(height: 1, color: AppColors.borderLight),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildScrollToTopButton() {
    return GestureDetector(
      onTap: _scrollToTop,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFFDFDFF),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Transform.rotate(
            angle: -1.5708, // -90 degrees (pointing up)
            child: const Icon(
              Icons.chevron_right,
              size: 24,
              color: AppColors.textHint,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================
  // Tag Filtering
  // ============================================
  void _onTagTap(String tag) {
    final viewModel = context.read<CommunityViewModel>();
    final cleanTag = tag.replaceAll('#', '');

    // 이미 선택된 태그면 필터 해제
    if (viewModel.selectedTag == cleanTag) {
      viewModel.clearTagFilter();
    } else {
      viewModel.filterByTag(tag);
    }
  }

  // ============================================
  // Navigation Helpers
  // ============================================
  void _navigateToPostDetail(String postId) {
    Navigator.pushNamed(context, '/post-detail', arguments: postId);
  }

  void _navigateToQuestionDetail(String questionId) {
    final viewModel = context.read<CommunityViewModel>();
    viewModel.incrementViewCount(questionId);
    Navigator.pushNamed(context, '/question-detail', arguments: questionId);
  }

  Future<void> _onCuriousTap(
    CommunityViewModel viewModel,
    String questionId,
  ) async {
    final isCurious = await viewModel.toggleCurious(questionId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isCurious ? '궁금해요를 눌렀습니다' : '궁금해요를 취소했습니다'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _showPostOptions(String postId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('신고하기'),
              onTap: () {
                Navigator.pop(context);
                _showReportDialog(postId, '게시글');
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('공유하기'),
              onTap: () {
                Navigator.pop(context);
                _sharePost(postId);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(String itemId, String itemType) {
    final reasons = ['스팸/광고', '욕설/비하', '음란물', '허위정보', '저작권 침해', '기타'];
    String? selectedReason;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('$itemType 신고'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '신고 사유를 선택해주세요.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSubtle,
                ),
              ),
              const SizedBox(height: 16),
              ...reasons.map(
                (reason) => RadioListTile<String>(
                  title: Text(reason),
                  value: reason,
                  groupValue: selectedReason,
                  onChanged: (value) {
                    setState(() {
                      selectedReason = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('취소', style: TextStyle(color: AppColors.textSubtle)),
            ),
            ElevatedButton(
              onPressed: selectedReason == null
                  ? null
                  : () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('신고가 접수되었습니다.'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('신고', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _sharePost(String postId) {
    // 딥링크 또는 앱 링크 생성 (실제 구현 시 share_plus 패키지 사용)
    final shareUrl = 'minimo://post/$postId';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('링크가 복사되었습니다: $shareUrl'),
        backgroundColor: AppColors.success,
        action: SnackBarAction(
          label: '확인',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
}
