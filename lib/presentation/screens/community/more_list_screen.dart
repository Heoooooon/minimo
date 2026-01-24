import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../viewmodels/community_viewmodel.dart';
import '../../widgets/community/post_card.dart';
import '../../widgets/community/qna_question_card.dart';
import '../../widgets/community/recommendation_card.dart';

/// 더보기 화면 타입
enum MoreListType {
  posts, // 최신 게시글
  popular, // 인기 질문
  waiting, // 답변 대기 질문
  recommend, // 추천 게시글
}

/// 더보기 화면
class MoreListScreen extends StatefulWidget {
  const MoreListScreen({super.key});

  @override
  State<MoreListScreen> createState() => _MoreListScreenState();
}

class _MoreListScreenState extends State<MoreListScreen> {
  late MoreListType _listType;
  String _title = '';
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initFromArguments();
  }

  void _initFromArguments() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is MoreListType) {
      _listType = args;
      _title = _getTitleForType(_listType);
      _loadData();
    } else {
      // 기본값
      _listType = MoreListType.posts;
      _title = '게시글';
      _loadData();
    }
  }

  String _getTitleForType(MoreListType type) {
    switch (type) {
      case MoreListType.posts:
        return '최신 게시글';
      case MoreListType.popular:
        return '인기 질문';
      case MoreListType.waiting:
        return '답변 대기 질문';
      case MoreListType.recommend:
        return '추천 게시글';
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final viewModel = context.read<CommunityViewModel>();

    try {
      switch (_listType) {
        case MoreListType.posts:
        case MoreListType.recommend:
          await viewModel.loadRecommendTab();
          break;
        case MoreListType.popular:
        case MoreListType.waiting:
          await viewModel.loadQnaTab();
          break;
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.brand),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.brand,
              child: _buildList(),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.backgroundSurface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        _title,
        style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textMain),
      ),
    );
  }

  Widget _buildList() {
    final viewModel = context.watch<CommunityViewModel>();

    switch (_listType) {
      case MoreListType.posts:
        return _buildPostsList(viewModel.latestPosts);
      case MoreListType.recommend:
        return _buildRecommendList(viewModel.recommendationItems);
      case MoreListType.popular:
        return _buildQuestionsList(viewModel.popularQuestions);
      case MoreListType.waiting:
        return _buildWaitingList(viewModel.waitingQuestions);
    }
  }

  Widget _buildPostsList(List<PostData> posts) {
    if (posts.isEmpty) {
      return _buildEmptyState('게시글이 없습니다');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: posts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final post = posts[index];
        return PostCard(
          data: post,
          onTap: () {
            Navigator.pushNamed(context, '/post-detail', arguments: post.id);
          },
        );
      },
    );
  }

  Widget _buildRecommendList(List<RecommendationData> items) {
    if (items.isEmpty) {
      return _buildEmptyState('추천 게시글이 없습니다');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return RecommendationCard(
          data: item,
          onTap: () {
            Navigator.pushNamed(context, '/post-detail', arguments: item.id);
          },
        );
      },
    );
  }

  Widget _buildQuestionsList(List<QnaQuestionData> questions) {
    if (questions.isEmpty) {
      return _buildEmptyState('질문이 없습니다');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: questions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final question = questions[index];
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

  Widget _buildWaitingList(List<QnaQuestionData> questions) {
    if (questions.isEmpty) {
      return _buildEmptyState('답변 대기 중인 질문이 없습니다');
    }

    final viewModel = context.read<CommunityViewModel>();

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: questions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final question = questions[index];
        return QnaWaitingCard(
          data: question,
          onTap: () {
            Navigator.pushNamed(
              context,
              '/question-detail',
              arguments: question.id,
            );
          },
          onCuriousTap: () async {
            final isCurious = await viewModel.toggleCurious(question.id);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isCurious ? '궁금해요를 눌렀습니다' : '궁금해요를 취소했습니다'),
                  duration: const Duration(seconds: 1),
                ),
              );
            }
          },
          onAnswerTap: () {
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

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: AppColors.textHint.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textSubtle,
            ),
          ),
        ],
      ),
    );
  }
}
