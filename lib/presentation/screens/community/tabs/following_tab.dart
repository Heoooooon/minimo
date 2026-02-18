import 'package:flutter/material.dart';
import '../../../viewmodels/community_viewmodel.dart';
import '../../../widgets/community/post_card.dart';
import '../../../widgets/common/empty_state.dart';

/// 팔로잉 탭 콘텐츠 (Sliver 리스트 반환)
class FollowingTab extends StatelessWidget {
  const FollowingTab({
    super.key,
    required this.onPostTap,
    required this.onPostOptions,
  });

  final void Function(String postId) onPostTap;
  final void Function(String postId) onPostOptions;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }

  /// CustomScrollView에 삽입할 Sliver 위젯 리스트 반환
  List<Widget> buildSlivers(BuildContext context, CommunityViewModel viewModel) {
    if (viewModel.followingPosts.isEmpty && !viewModel.isLoading) {
      return [
        const SliverToBoxAdapter(child: EmptyStatePresets.noFollowingPosts),
      ];
    }

    return [
      // Post List
      SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final post = viewModel.followingPosts[index];
          return PostCard(
            data: post,
            onTap: () => onPostTap(post.id),
            onLikeTap: () => viewModel.toggleLike(post.id, !post.isLiked),
            onCommentTap: () => onPostTap(post.id),
            onBookmarkTap: () =>
                viewModel.toggleBookmark(post.id, !post.isBookmarked),
            onMoreTap: () => onPostOptions(post.id),
          );
        }, childCount: viewModel.followingPosts.length),
      ),
    ];
  }
}
