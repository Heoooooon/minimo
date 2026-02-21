import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';
import 'package:cmore_design_system/theme/app_spacing.dart';
import '../../viewmodels/community_post_viewmodel.dart';
import '../../viewmodels/community_following_viewmodel.dart';
import '../../viewmodels/community_qna_viewmodel.dart';
import 'package:cmore_design_system/widgets/empty_state.dart';
import 'tabs/recommend_tab.dart';
import 'tabs/following_tab.dart';
import 'tabs/qna_tab.dart';

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

  late final RecommendTab _recommendTab;
  late final FollowingTab _followingTab;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    _recommendTab = RecommendTab(
      onPostTap: _navigateToPostDetail,
      onTagTap: _onTagTap,
      onPostOptions: _showPostOptions,
    );
    _followingTab = FollowingTab(
      onPostTap: _navigateToPostDetail,
      onPostOptions: _showPostOptions,
    );
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

    switch (tab) {
      case CommunityTab.recommend:
        context.read<CommunityPostViewModel>().loadRecommendTab();
        break;
      case CommunityTab.following:
        context.read<CommunityFollowingViewModel>().loadFollowingTab();
        break;
      case CommunityTab.qna:
        context.read<CommunityQnaViewModel>().loadQnaTab();
        break;
    }
  }

  Future<void> _refreshCurrentTab() {
    switch (_currentTab) {
      case CommunityTab.recommend:
        return context.read<CommunityPostViewModel>().loadRecommendTab(forceRefresh: true);
      case CommunityTab.following:
        return context.read<CommunityFollowingViewModel>().loadFollowingTab(forceRefresh: true);
      case CommunityTab.qna:
        return context.read<CommunityQnaViewModel>().loadQnaTab(forceRefresh: true);
    }
  }

  /// 현재 탭에 해당하는 ViewModel의 로딩/에러 상태를 반환
  bool _isCurrentTabLoading() {
    switch (_currentTab) {
      case CommunityTab.recommend:
        return context.select<CommunityPostViewModel, bool>((vm) => vm.isLoading);
      case CommunityTab.following:
        return context.select<CommunityFollowingViewModel, bool>((vm) => vm.isLoading);
      case CommunityTab.qna:
        return context.select<CommunityQnaViewModel, bool>((vm) => vm.isLoading);
    }
  }

  String? _currentTabErrorMessage() {
    switch (_currentTab) {
      case CommunityTab.recommend:
        return context.select<CommunityPostViewModel, String?>((vm) => vm.errorMessage);
      case CommunityTab.following:
        return context.select<CommunityFollowingViewModel, String?>((vm) => vm.errorMessage);
      case CommunityTab.qna:
        return context.select<CommunityQnaViewModel, String?>((vm) => vm.errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    // QnaTab은 immutable이므로 qnaSubTab이 변경될 때 재생성
    final qnaTab = QnaTab(
      qnaSubTab: _qnaSubTab,
      onQnaSubTabChanged: (tab) {
        setState(() {
          _qnaSubTab = tab;
        });
      },
      onQuestionTap: _navigateToQuestionDetail,
      onCuriousTap: _onCuriousTap,
      onTagTap: _onTagTap,
    );

    final isLoading = _isCurrentTabLoading();
    final errorMessage = _currentTabErrorMessage();

    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      body: RefreshIndicator(
        onRefresh: _refreshCurrentTab,
        color: AppColors.brand,
        child: Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Header (Fixed)
                SliverToBoxAdapter(child: _buildHeader()),

                // Loading Indicator
                if (isLoading)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xxxl),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.brand,
                        ),
                      ),
                    ),
                  ),

                // Error Message
                if (errorMessage != null)
                  SliverToBoxAdapter(
                    child: EmptyStatePresets.error(
                      message: errorMessage,
                      onRetry: _refreshCurrentTab,
                    ),
                  ),

                // Content based on tab
                if (!isLoading && errorMessage == null)
                  ..._buildTabContent(qnaTab),

                // Bottom padding for nav bar
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),

            // Scroll to Top Button
            if (_showScrollToTop)
              Positioned(
                right: AppSpacing.lg,
                bottom: 108,
                child: _buildScrollToTopButton(),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTabContent(QnaTab qnaTab) {
    switch (_currentTab) {
      case CommunityTab.recommend:
        return _recommendTab.buildSlivers(context);
      case CommunityTab.following:
        return _followingTab.buildSlivers(context);
      case CommunityTab.qna:
        return qnaTab.buildSlivers(context);
    }
  }

  // ============================================
  // Header
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
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.xs, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '커뮤니티',
                    style: AppTextStyles.headlineLarge.copyWith(
                      fontSize: 22,
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
              padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.xs, AppSpacing.sm, 0),
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
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                tab.label,
                                style: AppTextStyles.titleLarge.copyWith(
                                  color: isSelected
                                      ? AppColors.brand
                                      : AppColors.textSubtle,
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
                    margin: const EdgeInsets.only(right: AppSpacing.sm),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.borderLight,
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
            const SizedBox(height: AppSpacing.lg),
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

  Widget _buildScrollToTopButton() {
    return GestureDetector(
      onTap: _scrollToTop,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.backgroundSurface,
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
    final postViewModel = context.read<CommunityPostViewModel>();
    final cleanTag = tag.replaceAll('#', '');

    // 이미 선택된 태그면 필터 해제
    if (postViewModel.selectedTag == cleanTag) {
      postViewModel.clearTagFilter();
    } else {
      postViewModel.filterByTag(tag);
    }
  }

  // ============================================
  // Navigation Helpers
  // ============================================
  void _navigateToPostDetail(String postId) {
    Navigator.pushNamed(context, '/post-detail', arguments: postId);
  }

  void _navigateToQuestionDetail(String questionId) {
    final qnaViewModel = context.read<CommunityQnaViewModel>();
    qnaViewModel.incrementViewCount(questionId);
    Navigator.pushNamed(context, '/question-detail', arguments: questionId);
  }

  Future<void> _onCuriousTap(
    CommunityQnaViewModel viewModel,
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
              const SizedBox(height: AppSpacing.lg),
              RadioGroup<String>(
                groupValue: selectedReason ?? '',
                onChanged: (value) {
                  setState(() {
                    selectedReason = value;
                  });
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: reasons
                      .map(
                        (reason) => RadioListTile<String>(
                          title: Text(reason),
                          value: reason,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      )
                      .toList(),
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
