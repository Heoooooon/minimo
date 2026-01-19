import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../widgets/home/aquarium_card.dart';
import '../widgets/home/community_card.dart';
import '../widgets/home/qna_card.dart';
import '../widgets/home/tip_card.dart';
import '../widgets/common/skeleton_loader.dart';
import '../../domain/models/schedule_data.dart';
import '../../data/repositories/schedule_repository.dart';
import '../../data/repositories/aquarium_repository.dart';
import '../../data/services/auth_service.dart';
import '../../domain/models/aquarium_data.dart' as domain;

/// 홈 화면 (MainShell에서 사용)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeContent();
  }
}

/// 홈 콘텐츠 위젯
///
/// Figma 디자인 10:649 기반 - 새로운 홈 화면
class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  // 어항 데이터 (Mock Repository에서 로드)
  List<AquariumData> _aquariums = [];
  List<domain.AquariumData> _domainAquariums = [];

  final ScheduleRepository _scheduleRepository = PocketBaseScheduleRepository.instance;
  final AquariumRepository _aquariumRepository = PocketBaseAquariumRepository.instance;
  List<ScheduleData> _scheduleItems = [];

  // 사용자 닉네임
  String _userName = '미니모';

  // 추천 콘텐츠 페이지 인덱스
  int _contentPageIndex = 0;
  final PageController _contentPageController = PageController(
    viewportFraction: 0.85,
  );

  // 스크롤 컨트롤러 (sticky header용)
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

  // Hero 섹션 높이 (흰색 배경 전환점)
  static const double _heroHeight = 266;

  // 로딩 상태
  bool _isLoadingSchedule = true;
  bool _isLoadingAquariums = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadSchedule();
    _loadAquariums();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  void _loadUserInfo() {
    final user = AuthService.instance.currentUser;
    if (user != null) {
      final name = user.getStringValue('name');
      if (name.isNotEmpty && mounted) {
        setState(() {
          _userName = name;
        });
      }
    }
  }

  int _aquariumRetryCount = 0;
  static const int _maxRetries = 3;

  Future<void> _loadAquariums() async {
    try {
      final domainAquariums = await _aquariumRepository.getAquariums();
      _aquariumRetryCount = 0; // 성공 시 리셋
      if (mounted) {
        setState(() {
          _domainAquariums = domainAquariums;
          // domain.AquariumData를 UI용 AquariumData로 변환
          _aquariums = domainAquariums.map((a) => AquariumData(
            id: a.id ?? '',
            name: a.name ?? '이름 없음',
            imageUrl: a.photoUrl,
            status: AquariumStatus.healthy,
            temperature: 27,
            ph: 7.2,
            fishCount: 0,
          )).toList();
          _isLoadingAquariums = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading aquariums: $e');
      // 서버 Cold Start 시 재시도 (최대 3회)
      if (mounted && _aquariumRetryCount < _maxRetries) {
        _aquariumRetryCount++;
        debugPrint('Retrying... ($_aquariumRetryCount/$_maxRetries)');
        await Future.delayed(const Duration(seconds: 2));
        _loadAquariums();
      } else if (mounted) {
        setState(() {
          _isLoadingAquariums = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _contentPageController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSchedule() async {
    try {
      final items = await _scheduleRepository.getDailySchedule(DateTime.now());
      if (mounted) {
        setState(() {
          _scheduleItems = items;
          _isLoadingSchedule = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading schedule: $e');
      if (mounted) {
        setState(() {
          _isLoadingSchedule = false;
        });
      }
    }
  }

  bool get _hasAquariums => _aquariums.isNotEmpty;

  final List<CommunityData> _communityItems = const [
    CommunityData(
      id: '1',
      authorName: 'User',
      authorImageUrl: null,
      timeAgo: '00시간 전',
      content:
          '출장 다녀왔는데 어항에 이끼 실화인가욬ㅋㅋㅋㅋ청소할 생각에 어지러운데 혹시 도움 주실 수 있는 분 계신가요? 사진 올리고 싶은데 너무 창피해서...ㅋㅋㅋㅋ 정말 아마존 강 수준이에요\n비슷한 경험 있으신 분들 조언 부탁드려요! 특히 이끼 제거하면서 물고기 스트레스 최소화하는 방법 있으면 알려주세요ㅠㅠ  아 그리고 다음 출장 때는 어떻게 대비해야 할지도...',
      imageUrl: null,
      likeCount: 12,
      commentCount: 2,
      bookmarkCount: 1,
    ),
    CommunityData(
      id: '2',
      authorName: 'User',
      authorImageUrl: null,
      timeAgo: '00시간 전',
      content:
          '출장 다녀왔는데 어항에 이끼 실화인가욬ㅋㅋㅋㅋ청소할 생각에 어지러운데 혹시...',
      imageUrl: 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=400',
      likeCount: 12,
      commentCount: 2,
      bookmarkCount: 1,
    ),
    CommunityData(
      id: '3',
      authorName: 'User',
      authorImageUrl: null,
      timeAgo: '00시간 전',
      content:
          '출장 다녀왔는데 어항에 이끼 실화인가욬ㅋㅋㅋㅋ청소할 생각에 어지러운데 혹시... 더보기',
      imageUrl: null,
      likeCount: 12,
      commentCount: 2,
      bookmarkCount: 1,
    ),
  ];

  final QnAData _qnaItem = const QnAData(
    id: '1',
    authorName: '미니모',
    title: '물고기 몸에 갑자기 하얀 반점이 생겼어요',
    content:
        '안녕하세요 초보 반려어 사육자입니다.\n오전까지만 해도 괜찮았는데.... 퇴근하고 오니까 갑자기 물고기 몸에 하얀 반점이 생겼어요 ㅠㅠㅠㅠㅠ\n해결 방법 아시는 고수님들 도와주세요...!',
    tags: ['하얀반점', '초보사육자'],
    viewCount: 49,
    timeAgo: '16시간 전',
    curiousCount: 0,
  );

  final List<TipData> _tips = const [
    TipData(
      id: '1',
      title: '장비는 물속 생태계의\n숨은 조력자예요',
      description: '히터, 여과기, 냉각기 등 각 장비가 어떤 역할을 하는지,\n어떻게 안정적인 수질을 유지할 수 있는지 알아봐요.',
      illustrationType: TipIllustrationType.equipment,
    ),
    TipData(
      id: '2',
      title: '먹이는 사랑이지만,\n과하면 독이 돼요',
      description: '하루 급여량과 빈도, 사료 종류, 남은 먹이 관리까지.\n수질과 건강을 함께 지키는 먹이 관리 습관을 만들어보세요.',
      illustrationType: TipIllustrationType.feeding,
    ),
  ];

  void _toggleTimeline(String id, bool value) async {
    setState(() {
      final index = _scheduleItems.indexWhere((item) => item.id == id);
      if (index != -1) {
        _scheduleItems[index] = _scheduleItems[index].copyWith(
          isCompleted: value,
        );
      }
    });

    await _scheduleRepository.toggleComplete(id, value);
  }

  @override
  Widget build(BuildContext context) {
    // 상단 바 색상 계산 (스크롤 위치에 따라)
    final isScrolledPastHero = _scrollOffset > _heroHeight - 100;
    final topBarBackgroundOpacity = isScrolledPastHero
        ? ((_scrollOffset - (_heroHeight - 100)) / 50).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      body: Stack(
        children: [
          // 스크롤 가능한 콘텐츠
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                // Hero + Schedule Section (with overlap using negative margin approach)
                _buildHeroWithSchedule(),

                // Main Content Area
                Container(
                  color: AppColors.backgroundApp,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),

                      // My Aquarium Section
                      if (_isLoadingAquariums) ...[
                        _buildSectionHeader('나의 어항', showMore: false),
                        const SizedBox(height: 16),
                        const AquariumCardSkeleton(),
                        const SizedBox(height: 32),
                      ] else if (_hasAquariums) ...[
                        _buildSectionHeader('나의 어항', showMore: false),
                        const SizedBox(height: 16),
                        AquariumCardList(
                          aquariums: _aquariums,
                          onAquariumTap: (aquarium) {
                            Navigator.pushNamed(
                              context,
                              '/aquarium/detail',
                              arguments: aquarium.id,
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                      ],

                      // Recommended Content Section
                      _buildSectionHeader('추천 컨텐츠', showMore: true),
                      const SizedBox(height: 11),
                      _buildContentCarousel(),
                      const SizedBox(height: 32),

                      // Q&A Section
                      _buildSectionHeader('답변을 기다리고 있어요', showMore: true),
                      const SizedBox(height: 11),
                      QnACard(
                        data: _qnaItem,
                        onTap: () {},
                        onCuriousTap: () {},
                        onAnswerTap: () {
                          Navigator.pushNamed(context, '/community-question');
                        },
                      ),
                      const SizedBox(height: 32),

                      // Tips Section
                      _buildSectionHeader('오늘의 사육 꿀팁', showMore: true),
                      const SizedBox(height: 11),
                      TipList(tips: _tips, onTipTap: (tip) {}),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sticky Top Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildStickyTopBar(
              isScrolledPastHero: isScrolledPastHero,
              backgroundOpacity: topBarBackgroundOpacity,
            ),
          ),
        ],
      ),
    );
  }

  /// Sticky Top Bar - 스크롤 위치에 따라 배경색/아이콘색 변경
  Widget _buildStickyTopBar({
    required bool isScrolledPastHero,
    required double backgroundOpacity,
  }) {
    // 아이콘 색상 (흰 배경에서는 어두운 색, 어두운 배경에서는 흰색)
    final iconColor = isScrolledPastHero
        ? Color.lerp(Colors.white, AppColors.textMain, backgroundOpacity)!
        : Colors.white;
    final textColor = isScrolledPastHero
        ? Color.lerp(Colors.white, AppColors.textMain, backgroundOpacity)!
        : Colors.white;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Notification Icon with badge (40x40 컨테이너, 24x24 아이콘)
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: 40,
                  height: 40,
                  padding: const EdgeInsets.all(8),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        Icons.notifications_outlined,
                        color: iconColor,
                        size: 24,
                      ),
                      // Orange badge (4x4, positioned at right:4, top:-3 from icon)
                      Positioned(
                        right: -4,
                        top: -3,
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFE8A24),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Guide Button
              GestureDetector(
                onTap: () {},
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  child: Center(
                    child: Text(
                      '가이드',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        height: 20 / 14,
                        letterSpacing: -0.25,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Hero + Schedule combined widget for proper overlap
  Widget _buildHeroWithSchedule() {
    return Column(
      children: [
        // Hero Section with extra padding at bottom for overlap effect
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Hero background (shorter to allow overlap)
            Container(
              width: double.infinity,
              height: 352 - 86, // Original hero height minus overlap
              decoration: const BoxDecoration(
                color: Color(0xFF7E4A4A),
              ),
              child: Stack(
                children: [
                  // Background gradient
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.brand, AppColors.brand],
                        ),
                      ),
                    ),
                  ),
                  // Aquarium image overlay
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.7,
                      child: Container(
                        color: Colors.white,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Image.asset(
                                'assets/images/main_background.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          AppColors.brand.withValues(alpha: 0.8),
                                          const Color(0xFF00183C).withValues(alpha: 0.8),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Colors.transparent,
                                      const Color(0xFF00183C).withValues(alpha: 0.8),
                                    ],
                                    stops: const [0.3447, 1.0],
                                  ),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: Container(
                                color: Colors.black.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Content (상단 바 공간 확보를 위해 상단 패딩 추가)
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 48, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 18),
                          _buildGreeting(),
                          const SizedBox(height: 16),
                          if (_hasAquariums)
                            _buildStatusTags()
                          else
                            _buildRegisterAquariumButton(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        // Schedule Section (follows immediately, creating overlap effect visually)
        _buildScheduleSection(),
      ],
    );
  }

  /// Greeting Text - 어항 유무에 따라 다른 인사말
  Widget _buildGreeting() {
    final textStyle = AppTextStyles.headlineLarge.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      fontSize: 24,
      height: 36 / 24,
      letterSpacing: -0.25,
    );

    if (_hasAquariums) {
      // 어항이 있는 경우
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$_userName 님, 오늘도 덕분에', style: textStyle),
          Text('잘 지내고 있어요! 🐠', style: textStyle),
        ],
      );
    } else {
      // 어항이 없는 경우
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$_userName 님, 반가워요!', style: textStyle),
          Text('첫 어항을 등록해보세요 🐠', style: textStyle),
        ],
      );
    }
  }

  /// Status Tags (glass effect) - 동적 D-day 계산
  Widget _buildStatusTags() {
    final tags = <String>[];

    // 오늘 할 일 수 (미완료)
    final todoCount = _scheduleItems.where((s) => !s.isCompleted).length;
    if (todoCount > 0) {
      tags.add('오늘 해야 $todoCount건');
    }

    // 물잡이 D-day 계산 (첫 번째 어항의 세팅일 기준)
    if (_domainAquariums.isNotEmpty) {
      final firstAquarium = _domainAquariums.first;
      if (firstAquarium.settingDate != null) {
        final days = DateTime.now().difference(firstAquarium.settingDate!).inDays + 1;
        tags.add('물잡이 $days일차');
      }
    }

    // 태그가 없으면 기본 태그 표시
    if (tags.isEmpty) {
      tags.add('어항 관리 중');
    }

    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: tags.map((tag) => _buildStatusTag(tag)).toList(),
    );
  }

  Widget _buildStatusTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 14,
          height: 20 / 14,
          letterSpacing: -0.25,
        ),
      ),
    );
  }

  /// 어항 등록하기 버튼 (어항이 없을 때만 표시)
  Widget _buildRegisterAquariumButton() {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pushNamed(context, '/aquarium/register');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
        ),
        child: Text(
          '어항 등록하기',
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 14,
            height: 20 / 14,
            letterSpacing: -0.25,
          ),
        ),
      ),
    );
  }

  /// Schedule Section (White card with rounded top corners, overlapping hero)
  Widget _buildScheduleSection() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.backgroundApp,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 4, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Header
            _buildDateHeader(),
            const SizedBox(height: 17),

            // Timeline Items
            if (_isLoadingSchedule)
              const ScheduleSkeleton()
            else if (_scheduleItems.isEmpty || !_hasAquariums)
              _buildEmptyTimeline()
            else
              _buildTimelineItems(),

            // Expand Button
            _buildExpandButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader() {
    final now = DateTime.now();
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[now.weekday - 1];

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${now.day}일 ($weekday)',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              height: 26 / 18,
              letterSpacing: -0.5,
              color: AppColors.textMain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTimeline() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Text(
            '오늘 할 일이 비어있어요',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '어항을 등록한 후 할 일을 추가해 보세요',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItems() {
    return Column(
      children: _scheduleItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isLast = index == _scheduleItems.length - 1;
        return _buildTimelineItem(item, isLast, index == 0);
      }).toList(),
    );
  }

  /// Timeline Item - Figma layout
  Widget _buildTimelineItem(ScheduleData item, bool isLast, bool isFirst) {
    final amPm = item.time.contains('오전') ? '오전' : '오전';
    final time = item.time.replaceAll('오전 ', '').replaceAll('오후 ', '');

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 17),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline Indicator (Circle + Line)
            SizedBox(
              width: 12,
              child: Column(
                children: [
                  const SizedBox(height: 4),
                  // Circle
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFB6E4FF),
                      border: Border.all(
                        color: const Color(0xFFD6EEFF),
                        width: 1,
                      ),
                    ),
                  ),
                  // Vertical Line
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 1,
                        margin: const EdgeInsets.only(top: 4),
                        color: const Color(0xFFD6EEFF),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Time
            SizedBox(
              width: 60,
              child: Row(
                children: [
                  Text(
                    amPm,
                    style: AppTextStyles.captionRegular.copyWith(
                      color: AppColors.textSubtle,
                      fontSize: 12,
                      height: 18 / 12,
                      letterSpacing: -0.25,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    time,
                    style: AppTextStyles.captionRegular.copyWith(
                      color: AppColors.textSubtle,
                      fontSize: 12,
                      height: 18 / 12,
                      letterSpacing: -0.25,
                    ),
                  ),
                ],
              ),
            ),

            // Task Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTextStyles.bodyMediumMedium.copyWith(
                      color: AppColors.textMain,
                      fontSize: 16,
                      height: 24 / 16,
                      letterSpacing: -0.5,
                      decoration:
                          item.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.aquariumName,
                    style: AppTextStyles.captionRegular.copyWith(
                      color: AppColors.textHint,
                      fontSize: 12,
                      height: 18 / 12,
                      letterSpacing: -0.25,
                    ),
                  ),
                ],
              ),
            ),

            // Checkbox
            GestureDetector(
              onTap: () => _toggleTimeline(item.id, !item.isCompleted),
              child: Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(8),
                child: Container(
                  width: 19,
                  height: 19,
                  decoration: BoxDecoration(
                    color: item.isCompleted ? AppColors.brand : Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: item.isCompleted
                          ? AppColors.brand
                          : AppColors.border,
                      width: 1,
                    ),
                  ),
                  child: item.isCompleted
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandButton() {
    return Center(
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
        child: const Icon(
          Icons.keyboard_arrow_down,
          color: AppColors.textHint,
          size: 24,
        ),
      ),
    );
  }

  /// Section Header with optional "더보기 >" link
  Widget _buildSectionHeader(String title, {bool showMore = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              height: 26 / 18,
              letterSpacing: -0.5,
              color: AppColors.textMain,
            ),
          ),
          if (showMore)
            GestureDetector(
              onTap: () {},
              child: Row(
                children: [
                  Text(
                    '더보기',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.brand,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      height: 20 / 14,
                      letterSpacing: -0.25,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Transform.rotate(
                    angle: 3.14159, // 180 degrees
                    child: const Icon(
                      Icons.keyboard_arrow_left,
                      size: 16,
                      color: AppColors.brand,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Content Carousel with Pagination Dots
  Widget _buildContentCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 340,
          child: PageView.builder(
            controller: _contentPageController,
            padEnds: false,
            onPageChanged: (index) {
              setState(() {
                _contentPageIndex = index;
              });
            },
            itemCount: _communityItems.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 16 : 6,
                  right: 6,
                ),
                child: CommunityCard(
                  data: _communityItems[index],
                  onTap: () {},
                  isActive: index == _contentPageIndex,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Pagination Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_communityItems.length, (index) {
            final isActive = index == _contentPageIndex;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: isActive ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: isActive ? AppColors.brand : const Color(0xFFE8EBF0),
              ),
            );
          }),
        ),
      ],
    );
  }
}
