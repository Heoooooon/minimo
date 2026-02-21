import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';
import 'package:cmore_design_system/theme/app_spacing.dart';
import '../../../viewmodels/community_post_viewmodel.dart';
import '../../../widgets/community/post_card.dart';
import '../../../widgets/community/recommendation_card.dart';
import '../../../widgets/community/popular_ranking_card.dart';
import 'package:cmore_design_system/widgets/empty_state.dart';
import '../more_list_screen.dart';

/// 추천 탭 콘텐츠 (Sliver 리스트 반환)
class RecommendTab extends StatelessWidget {
  const RecommendTab({
    super.key,
    required this.onPostTap,
    required this.onTagTap,
    required this.onPostOptions,
  });

  final void Function(String postId) onPostTap;
  final void Function(String tag) onTagTap;
  final void Function(String postId) onPostOptions;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }

  /// CustomScrollView에 삽입할 Sliver 위젯 리스트 반환
  List<Widget> buildSlivers(BuildContext context) {
    final viewModel = context.watch<CommunityPostViewModel>();

    // 태그 필터링 중인 경우
    if (viewModel.isFilteringByTag) {
      return _buildFilteredPostsContent(context, viewModel);
    }

    // 데이터가 없는 경우 빈 상태 표시
    if (viewModel.latestPosts.isEmpty &&
        viewModel.recommendationItems.isEmpty &&
        !viewModel.isLoading) {
      return [
        SliverToBoxAdapter(
          child: EmptyStatePresets.noPosts(
            onAction: () => Navigator.pushNamed(context, '/post-create'),
          ),
        ),
      ];
    }

    return [
      // Popular Ranking Section
      if (viewModel.popularRanking != null)
        SliverToBoxAdapter(child: _buildPopularRankingSection(context, viewModel)),

      // Recommendation Section
      if (viewModel.recommendationItems.isNotEmpty)
        SliverToBoxAdapter(child: _buildRecommendationSection(context, viewModel)),

      // Latest Posts Section
      if (viewModel.latestPosts.isNotEmpty)
        SliverToBoxAdapter(child: _buildLatestPostsHeader(context)),

      // Post List
      if (viewModel.latestPosts.isNotEmpty)
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final post = viewModel.latestPosts[index];
            return PostCard(
              data: post,
              onTap: () => onPostTap(post.id),
              onLikeTap: () => viewModel.toggleLike(post.id, !post.isLiked),
              onCommentTap: () => onPostTap(post.id),
              onBookmarkTap: () =>
                  viewModel.toggleBookmark(post.id, !post.isBookmarked),
              onMoreTap: () => onPostOptions(post.id),
            );
          }, childCount: viewModel.latestPosts.length),
        ),
    ];
  }

  // ============================================
  // Filtered Posts Content (태그 필터링 결과)
  // ============================================
  List<Widget> _buildFilteredPostsContent(
    BuildContext context,
    CommunityPostViewModel viewModel,
  ) {
    return [
      // 필터링 헤더
      SliverToBoxAdapter(child: _buildFilteredPostsHeader(context, viewModel)),

      // 필터링된 게시글이 없는 경우
      if (viewModel.filteredPosts.isEmpty && !viewModel.isLoading)
        SliverToBoxAdapter(
          child: EmptyState(
            icon: Icons.tag,
            message: '#${viewModel.selectedTag} 태그의 게시글이 없습니다',
            subMessage: '다른 태그를 선택해보세요!',
            actionLabel: '전체보기',
            onAction: () => viewModel.clearTagFilter(),
          ),
        ),

      // 필터링된 게시글 목록
      if (viewModel.filteredPosts.isNotEmpty)
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final post = viewModel.filteredPosts[index];
            return PostCard(
              data: post,
              onTap: () => onPostTap(post.id),
              onLikeTap: () => viewModel.toggleLike(post.id, !post.isLiked),
              onCommentTap: () => onPostTap(post.id),
              onBookmarkTap: () =>
                  viewModel.toggleBookmark(post.id, !post.isBookmarked),
              onMoreTap: () => onPostOptions(post.id),
            );
          }, childCount: viewModel.filteredPosts.length),
        ),
    ];
  }

  Widget _buildFilteredPostsHeader(
    BuildContext context,
    CommunityPostViewModel viewModel,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 선택된 태그 표시
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.brand,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
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
                    const SizedBox(width: AppSpacing.xs),
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
              const SizedBox(width: AppSpacing.md),
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
          const SizedBox(height: AppSpacing.lg),
          const Divider(height: 1, color: AppColors.borderLight),
        ],
      ),
    );
  }

  // ============================================
  // Popular Ranking Section
  // ============================================
  Widget _buildPopularRankingSection(
    BuildContext context,
    CommunityPostViewModel viewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '오늘 인기글',
                style: AppTextStyles.headlineSmall,
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
                  width: AppSpacing.xxl,
                  height: AppSpacing.xxl,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSurface,
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
        const SizedBox(height: AppSpacing.lg),

        // Ranking Card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: PopularRankingCard(
            data: viewModel.popularRanking!,
            onTap: () => onPostTap(viewModel.popularRanking!.id),
          ),
        ),
        const SizedBox(height: AppSpacing.xxxl),
      ],
    );
  }

  // ============================================
  // Recommendation Section
  // ============================================
  Widget _buildRecommendationSection(
    BuildContext context,
    CommunityPostViewModel viewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            '미니모님이 좋아하실 만한 게시글',
            style: AppTextStyles.headlineSmall,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Tags
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: viewModel.tags.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final tag = viewModel.tags[index];
              final isSelected =
                  viewModel.selectedTag == tag.replaceAll('#', '');
              return GestureDetector(
                onTap: () => onTagTap(tag),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.brand
                        : AppColors.chipPrimaryBg,
                    borderRadius: AppRadius.xsBorderRadius,
                    border: isSelected
                        ? null
                        : Border.all(
                            color: AppColors.brand.withValues(alpha: 0.3),
                          ),
                  ),
                  child: Center(
                    child: Text(
                      tag,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: isSelected ? Colors.white : AppColors.brand,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Recommendation Cards
        RecommendationCardList(
          items: viewModel.recommendationItems,
          onItemTap: (item) => onPostTap(item.id),
        ),
        const SizedBox(height: AppSpacing.xxxl),
      ],
    );
  }

  // ============================================
  // Latest Posts Header
  // ============================================
  Widget _buildLatestPostsHeader(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '실시간 최신글',
                style: AppTextStyles.headlineSmall,
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
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
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
        const SizedBox(height: AppSpacing.xxl),
        Container(height: 1, color: AppColors.borderLight),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}
