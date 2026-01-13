import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../widgets/community/post_card.dart';
import '../../widgets/community/recommendation_card.dart';
import '../../widgets/community/popular_ranking_card.dart';
import '../../widgets/community/qna_question_card.dart';

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

  // Mock Data - Recommend Tab
  final PopularRankingData _popularRanking = const PopularRankingData(
    rank: 1,
    title: '베타를 건강하게 키우기 위한 10가지 방법',
    id: '1',
  );

  final List<String> _tags = const ['#베타', '#25큐브', '#초보자', '#구피', '#안시'];

  final List<RecommendationData> _recommendationItems = const [
    RecommendationData(
      id: '1',
      title: '이끼 어떡하면 좋나요 ㅋㅋㅋ',
      content:
          '장 다녀왔는데 어항에 이끼 실화인가욬ㅋㅋㅋㅋ청소할 생각에 어지러운데 혹시 도움 주실 수 있는 분 계신가요? 사진 올리고 싶은데 너무 창피해서...ㅋㅋㅋㅋ 정말 아마존 강 수준이에요\n비슷한 경험 있으신 분들 조언 부탁드려요!',
      authorName: '미니모',
      timeAgo: '20분 전',
      imageUrl:
          'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=400',
    ),
    RecommendationData(
      id: '2',
      title: '새 어항 세팅했는데 물이 뿌옇게 돼요',
      content:
          '이번 주말에 45큐브 새 어항 세팅했어요. 모래는 ADA 아마조니아, 여과기는 Eheim 2213 사용 중입니다. 물잡이 중인데 어제까진 맑았는데 오늘 아침 보니 갑자기 뿌옇게 변했어요. 냄새는 없고 물고기는 아직 안 넣었어요.',
      authorName: '양이',
      timeAgo: '20분 전',
      imageUrl:
          'https://images.unsplash.com/photo-1571752726703-5e7d1f6a986d?w=400',
    ),
    RecommendationData(
      id: '3',
      title: '처음으로 물생활 시작했어요!',
      content:
          '예전부터 어항 있는 집이 너무 부러웠는데, 이번에 드디어 30큐브 세트를 들였어요! 어항, 여과기, 모래, 수초, 구피 세 마리까지 세팅 완료했습니다.',
      authorName: '물초보99',
      timeAgo: '20분 전',
      imageUrl:
          'https://images.unsplash.com/photo-1520302519878-3836d1c96e8e?w=400',
    ),
  ];

  final List<PostData> _postItems = const [
    PostData(
      id: '1',
      authorName: 'User',
      timeAgo: '00시간 전',
      title: '네온테트라 군영 세팅 완료했어요!',
      content:
          '이번에 2자 어항 새로 입양해서 네온테트라 30마리 들였습니다 🥰  소일 깔고 수초도 심었더니 너무 예쁘네요!',
      imageUrls: [
        'https://images.unsplash.com/photo-1520302519878-3836d1c96e8e?w=600',
        'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=600',
      ],
      likeCount: 233,
      commentCount: 2,
      bookmarkCount: 122,
      isLiked: true,
    ),
    PostData(
      id: '2',
      authorName: 'User',
      timeAgo: '00시간 전',
      title: '어항 속 작은 마을 만들기 프로젝트',
      content:
          '한 달 동안 준비한 어항 레이아웃이 드디어 완성됐어요! 모래길을 중심으로 양쪽에 자바모스 숲을 만들고, 돌로 작은 아치형 다리도 세웠습니다.',
      imageUrls: [
        'https://images.unsplash.com/photo-1571752726703-5e7d1f6a986d?w=600',
      ],
      likeCount: 233,
      commentCount: 2,
      bookmarkCount: 122,
      isLiked: true,
      isBookmarked: true,
    ),
    PostData(
      id: '3',
      authorName: 'User',
      timeAgo: '00시간 전',
      title: '우리 어항에 봄이 온 것 같아요',
      content:
          '겨울 내내 삭았던 수초들이 요즘 갑자기 새순을 올리고 있어요. 자바모스는 덩어리가 커지고, 미크로소리움 잎도 진한 녹색으로 변했어요.',
      imageUrls: [
        'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=600',
      ],
      likeCount: 233,
      commentCount: 2,
      bookmarkCount: 122,
      isLiked: true,
    ),
  ];

  // Mock Data - Following Tab
  final List<PostData> _followingPostItems = const [
    PostData(
      id: 'f1',
      authorName: '네온이사랑',
      timeAgo: '2분 전',
      title: '네온테트라 군영 세팅 완료했어요!',
      content:
          '이번에 2자 어항 새로 입양해서 네온테트라 30마리 들였습니다 🥰  소일 깔고 수초도 심었더니 너무 예쁘네요!',
      imageUrls: [
        'https://images.unsplash.com/photo-1520302519878-3836d1c96e8e?w=600',
        'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=600',
      ],
      likeCount: 233,
      commentCount: 2,
      bookmarkCount: 122,
      isLiked: true,
    ),
    PostData(
      id: 'f2',
      authorName: '밥고기',
      timeAgo: '00시간 전',
      title: '어항 속 작은 마을 만들기 프로젝트',
      content:
          '한 달 동안 준비한 어항 레이아웃이 드디어 완성됐어요! 모래길을 중심으로 양쪽에 자바모스 숲을 만들고, 돌로 작은 아치형 다리도 세웠습니다.',
      imageUrls: [
        'https://images.unsplash.com/photo-1571752726703-5e7d1f6a986d?w=600',
      ],
      likeCount: 233,
      commentCount: 2,
      bookmarkCount: 122,
      isLiked: true,
      isBookmarked: true,
    ),
    PostData(
      id: 'f3',
      authorName: '퉁퉁퉁사후르',
      timeAgo: '00시간 전',
      title: '우리 어항에 봄이 온 것 같아요',
      content:
          '겨울 내내 삭았던 수초들이 요즘 갑자기 새순을 올리고 있어요. 자바모스는 덩어리가 커지고, 미크로소리움 잎도 진한 녹색으로 변했어요.',
      imageUrls: [
        'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=600',
      ],
      likeCount: 233,
      commentCount: 2,
      bookmarkCount: 122,
      isLiked: true,
    ),
  ];

  // Mock Data - Q&A Tab
  final List<String> _qnaTags = const ['#25큐브', '#구피초보', '#물잡이', '#이끼'];

  final List<QnaQuestionData> _popularQnaItems = const [
    QnaQuestionData(
      id: 'q1',
      rank: 1,
      title: '꼬리 지느러미가 해질게 변했어요',
      content:
          '안녕하세요. 카페에서 우연히 이 앱을 알게 되어서 질문드립니다. 가장 먼저 해야 할 일은 뭘까요? 물고기를 넣기 전에 뭔가를 체크해야 하나요?',
      answerCount: 1,
      timeAgo: '25분 전',
    ),
    QnaQuestionData(
      id: 'q2',
      rank: 2,
      title: '어항에 이끼가 너무 많이 껴요',
      content:
          '처음 어항세팅이라 정말 긴장되네요 ㅜㅜ 카페에서 우연히 이 앱을 알게 되었는데, 가장 먼저 해야 할 일은 뭘까요? 물고기를 넣기 전에 뭔가를 체크해야 하나요?',
      answerCount: 3,
      timeAgo: '25분 전',
    ),
    QnaQuestionData(
      id: 'q3',
      rank: 3,
      title: '물고기들이 자꾸 먹이를 뱉어내요',
      content:
          '네온테트라 4마리랑 구피 10마리 합사 중인데 먹이를 먹질 않아요. 가장 먼저 해야 할 일은 뭘까요? 물고기를 넣기 전에 뭔가를 체크해야 하나요?',
      answerCount: 5,
      timeAgo: '25분 전',
    ),
  ];

  final QnaQuestionData _featuredQuestion = const QnaQuestionData(
    id: 'fq1',
    title: '물고기 몸에 갑자기 하얀 반점이 생겼어요',
    content: '',
    tags: ['흰점병백터'],
  );

  final List<QnaQuestionData> _waitingAnswerItems = const [
    QnaQuestionData(
      id: 'wa1',
      title: '꼬리 지느러미가 해질게 변했어요',
      content:
          '안녕하세요. 처음 어항세팅이라 정말 긴장되네요 ㅜㅜ 카페에서 우연히 이 앱을 알게 되어서 질문드립니다. 가장 먼저 해야 할 일은 뭘까요?',
      answerCount: 25,
      timeAgo: '25분 전',
    ),
    QnaQuestionData(
      id: 'wa2',
      title: '어항에 이끼가 너무 많이 껴요!',
      content:
          '처음 어항세팅이라 정말 긴장되네요 ㅜㅜ 카페에서 우연히 이 앱을 알게 되어서 질문드립니다. 가장 먼저 해야 할 일은 뭘까요?',
      answerCount: 25,
      timeAgo: '25분 전',
    ),
    QnaQuestionData(
      id: 'wa3',
      title: '물고기가 자꾸 먹이를 뱉어내요.',
      content:
          '돌처럼 때를 안 뱉었어요? 벌써도 많이 아프셨데요 ㅜㅜ 카페에서 우연히 이 앱을 알게 되어서 질문드립니다.',
      answerCount: 25,
      timeAgo: '25분 전',
      imageUrl:
          'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=400',
    ),
  ];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Header (Fixed)
              SliverToBoxAdapter(
                child: _buildHeader(),
              ),

              // Content based on tab
              ..._buildTabContent(),

              // Bottom padding for nav bar
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
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
  }

  List<Widget> _buildTabContent() {
    switch (_currentTab) {
      case CommunityTab.recommend:
        return _buildRecommendTabContent();
      case CommunityTab.following:
        return _buildFollowingTabContent();
      case CommunityTab.qna:
        return _buildQnaTabContent();
    }
  }

  // ============================================
  // Recommend Tab Content
  // ============================================
  List<Widget> _buildRecommendTabContent() {
    return [
      // Popular Ranking Section
      SliverToBoxAdapter(
        child: _buildPopularRankingSection(),
      ),

      // Recommendation Section
      SliverToBoxAdapter(
        child: _buildRecommendationSection(),
      ),

      // Latest Posts Section
      SliverToBoxAdapter(
        child: _buildLatestPostsHeader(),
      ),

      // Post List
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return PostCard(
              data: _postItems[index],
              onTap: () {},
              onLikeTap: () {},
              onCommentTap: () {},
              onBookmarkTap: () {},
              onMoreTap: () {},
            );
          },
          childCount: _postItems.length,
        ),
      ),
    ];
  }

  // ============================================
  // Following Tab Content
  // ============================================
  List<Widget> _buildFollowingTabContent() {
    return [
      // Post List
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return PostCard(
              data: _followingPostItems[index],
              onTap: () {},
              onLikeTap: () {},
              onCommentTap: () {},
              onBookmarkTap: () {},
              onMoreTap: () {},
            );
          },
          childCount: _followingPostItems.length,
        ),
      ),
    ];
  }

  // ============================================
  // Q&A Tab Content
  // ============================================
  List<Widget> _buildQnaTabContent() {
    return [
      // Ask Question Button
      SliverToBoxAdapter(
        child: _buildAskQuestionButton(),
      ),

      // Sub Tab Selector
      SliverToBoxAdapter(
        child: _buildQnaSubTabs(),
      ),

      // Popular Tags
      SliverToBoxAdapter(
        child: _buildPopularTags(),
      ),

      // Popular Q&A Section
      SliverToBoxAdapter(
        child: _buildPopularQnaSection(),
      ),

      // Featured Question Card
      SliverToBoxAdapter(
        child: _buildFeaturedQuestionCard(),
      ),

      // Waiting Answer Section
      SliverToBoxAdapter(
        child: _buildWaitingAnswerSection(),
      ),
    ];
  }

  Widget _buildAskQuestionButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: GestureDetector(
        onTap: () {},
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

  Widget _buildPopularTags() {
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
            itemCount: _qnaTags.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              return Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.chipPrimaryBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    _qnaTags[index],
                    style: AppTextStyles.captionMedium.copyWith(
                      color: AppColors.brand,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 18 / 12,
                      letterSpacing: -0.25,
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

  Widget _buildPopularQnaSection() {
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
                onTap: () {},
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
            children: _popularQnaItems.map((item) {
              return Column(
                children: [
                  QnaPopularCard(
                    data: item,
                    onTap: () {},
                  ),
                  if (item != _popularQnaItems.last)
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

  Widget _buildFeaturedQuestionCard() {
    return Column(
      children: [
        QnaAskCard(
          userName: '미니모',
          question: _featuredQuestion,
          onCuriousTap: () {},
          onAnswerTap: () {},
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildWaitingAnswerSection() {
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
            children: _waitingAnswerItems.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: QnaWaitingCard(
                  data: item,
                  onTap: () {},
                  onCuriousTap: () {},
                  onAnswerTap: () {},
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
                        onTap: () {},
                      ),
                      _buildIconButton(
                        icon: Icons.notifications_outlined,
                        onTap: () {},
                      ),
                      _buildIconButton(
                        icon: Icons.add_box_outlined,
                        onTap: () {},
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
                        onTap: () {
                          setState(() {
                            _currentTab = tab;
                          });
                        },
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
                      child:
                          Icon(Icons.person, size: 18, color: AppColors.textHint),
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
        child: Icon(
          icon,
          size: 24,
          color: AppColors.textMain,
        ),
      ),
    );
  }

  Widget _buildPopularRankingSection() {
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
                onTap: () {},
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
            data: _popularRanking,
            onTap: () {},
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildRecommendationSection() {
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
            itemCount: _tags.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              return Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.chipPrimaryBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    _tags[index],
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.brand,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 20 / 14,
                      letterSpacing: -0.25,
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
          items: _recommendationItems,
          onItemTap: (item) {},
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
                onTap: () {},
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
        Container(
          height: 1,
          color: AppColors.borderLight,
        ),
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
}
