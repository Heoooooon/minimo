import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';
import 'package:cmore_design_system/theme/app_spacing.dart';
import '../../../viewmodels/community_post_viewmodel.dart';
import '../../../viewmodels/community_qna_viewmodel.dart';
import '../../../widgets/community/qna_question_card.dart';
import 'package:cmore_design_system/widgets/empty_state.dart';
import '../community_screen.dart';
import '../more_list_screen.dart';

/// Q&A 탭 콘텐츠 (Sliver 리스트 반환)
class QnaTab extends StatelessWidget {
  const QnaTab({
    super.key,
    required this.qnaSubTab,
    required this.onQnaSubTabChanged,
    required this.onQuestionTap,
    required this.onCuriousTap,
    required this.onTagTap,
  });

  final QnaSubTab qnaSubTab;
  final void Function(QnaSubTab tab) onQnaSubTabChanged;
  final void Function(String questionId) onQuestionTap;
  final void Function(CommunityQnaViewModel viewModel, String questionId) onCuriousTap;
  final void Function(String tag) onTagTap;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }

  /// CustomScrollView에 삽입할 Sliver 위젯 리스트 반환
  List<Widget> buildSlivers(BuildContext context) {
    final viewModel = context.watch<CommunityQnaViewModel>();
    // selectedTag는 PostViewModel에서 읽음
    final postViewModel = context.watch<CommunityPostViewModel>();

    return [
      // Ask Question Button
      SliverToBoxAdapter(child: _buildAskQuestionButton(context)),

      // Sub Tab Selector
      SliverToBoxAdapter(child: _buildQnaSubTabs(context)),

      // Popular Tags
      if (viewModel.qnaTags.isNotEmpty)
        SliverToBoxAdapter(child: _buildPopularTags(context, viewModel, postViewModel)),

      // Popular Q&A Section
      if (viewModel.popularQuestions.isNotEmpty)
        SliverToBoxAdapter(child: _buildPopularQnaSection(context, viewModel)),

      // Featured Question Card
      if (viewModel.featuredQuestion != null)
        SliverToBoxAdapter(child: _buildFeaturedQuestionCard(context, viewModel)),

      // Waiting Answer Section
      if (viewModel.waitingQuestions.isNotEmpty)
        SliverToBoxAdapter(child: _buildWaitingAnswerSection(context, viewModel)),

      // Empty State for Q&A
      if (viewModel.popularQuestions.isEmpty &&
          viewModel.waitingQuestions.isEmpty &&
          !viewModel.isLoading)
        SliverToBoxAdapter(
          child: EmptyStatePresets.noQuestions(
            onAction: () =>
                Navigator.pushNamed(context, '/community-question'),
          ),
        ),
    ];
  }

  Widget _buildAskQuestionButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg,
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, '/community-question');
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.backgroundSurface,
            borderRadius: AppRadius.smBorderRadius,
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
              const SizedBox(width: AppSpacing.sm),
              Text(
                '질문하기',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textSubtle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQnaSubTabs(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg,
      ),
      child: Row(
        children: QnaSubTab.values.map((tab) {
          final isSelected = qnaSubTab == tab;
          return Expanded(
            child: GestureDetector(
              onTap: () => onQnaSubTabChanged(tab),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.brand : Colors.transparent,
                  borderRadius: AppRadius.smBorderRadius,
                  border: isSelected
                      ? null
                      : Border.all(color: AppColors.borderLight),
                ),
                child: Center(
                  child: Text(
                    tab.label,
                    style: AppTextStyles.titleSmall.copyWith(
                      color:
                          isSelected ? Colors.white : AppColors.textSubtle,
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

  Widget _buildPopularTags(
    BuildContext context,
    CommunityQnaViewModel viewModel,
    CommunityPostViewModel postViewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            '인기 태그',
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textMain,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 32,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: viewModel.qnaTags.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final tag = viewModel.qnaTags[index];
              final isSelected =
                  postViewModel.selectedTag == tag.replaceAll('#', '');
              return GestureDetector(
                onTap: () => onTagTap(tag),
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.brand
                        : AppColors.chipPrimaryBg,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Center(
                    child: Text(
                      tag,
                      style: AppTextStyles.captionMedium.copyWith(
                        color: isSelected ? Colors.white : AppColors.brand,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  Widget _buildPopularQnaSection(
    BuildContext context,
    CommunityQnaViewModel viewModel,
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
                '실시간 인기 Q&A',
                style: AppTextStyles.headlineSmall,
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
        const SizedBox(height: AppSpacing.sm),

        // Q&A List
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: viewModel.popularQuestions.map((item) {
              return Column(
                children: [
                  QnaPopularCard(
                    data: item,
                    onTap: () => onQuestionTap(item.id),
                  ),
                  if (item != viewModel.popularQuestions.last)
                    const Divider(height: 1, color: AppColors.borderLight),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  Widget _buildFeaturedQuestionCard(
    BuildContext context,
    CommunityQnaViewModel viewModel,
  ) {
    return Column(
      children: [
        QnaAskCard(
          userName: '미니모',
          question: viewModel.featuredQuestion!,
          onCuriousTap: () =>
              onCuriousTap(viewModel, viewModel.featuredQuestion!.id),
          onAnswerTap: () =>
              onQuestionTap(viewModel.featuredQuestion!.id),
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  Widget _buildWaitingAnswerSection(
    BuildContext context,
    CommunityQnaViewModel viewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            '답변을 기다려요',
            style: AppTextStyles.headlineSmall,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Waiting Answer List
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: viewModel.waitingQuestions.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: QnaWaitingCard(
                  data: item,
                  onTap: () => onQuestionTap(item.id),
                  onCuriousTap: () => onCuriousTap(viewModel, item.id),
                  onAnswerTap: () => onQuestionTap(item.id),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
