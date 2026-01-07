import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../widgets/home/aquarium_card.dart';
import '../widgets/home/community_card.dart';
import '../widgets/home/qna_card.dart';
import '../widgets/home/tip_card.dart';
import '../../domain/models/schedule_data.dart';
import '../../data/repositories/schedule_repository.dart';

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
/// Figma 디자인 #03-01 (Empty State) + #03-02 (With Data) 기반
class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  // 어항 데이터 (Empty State 테스트: 빈 리스트로 변경)
  final List<AquariumData> _aquariums = const [
    AquariumData(
      id: '1',
      name: '러키네',
      status: AquariumStatus.healthy,
      temperature: 27,
      ph: 7.2,
      fishCount: 12,
    ),
    AquariumData(
      id: '2',
      name: '비키네',
      status: AquariumStatus.treatment,
      temperature: 26,
      ph: 6.8,
      fishCount: 8,
    ),
  ];

  final ScheduleRepository _scheduleRepository = MockScheduleRepository();
  List<ScheduleData> _scheduleItems = [];

  // 추천 콘텐츠 페이지 인덱스
  int _contentPageIndex = 0;
  final PageController _contentPageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  @override
  void dispose() {
    _contentPageController.dispose();
    super.dispose();
  }

  Future<void> _loadSchedule() async {
    final items = await _scheduleRepository.getDailySchedule(DateTime.now());
    if (mounted) {
      setState(() {
        _scheduleItems = items;
      });
    }
  }

  bool get _hasAquariums => _aquariums.isNotEmpty;

  final List<CommunityData> _communityItems = const [
    CommunityData(
      id: '1',
      authorName: '미니모',
      content:
          '저번에 먹이 너무 많이 줘서 수질이 안좋아진 적이 있는데... 이번엔 이끼가 너무 많이 생겨서 고민이에요. 다른 분들은 어떻게 관리하세요?',
      likeCount: 24,
      commentCount: 12,
      bookmarkCount: 5,
    ),
    CommunityData(
      id: '2',
      authorName: '초보어항러',
      content: '물잡이 2주차인데 암모니아 수치가 계속 높아요. 환수 주기를 더 짧게 해야 할까요?',
      likeCount: 18,
      commentCount: 8,
      bookmarkCount: 3,
    ),
  ];

  final QnAData _qnaItem = const QnAData(
    id: '1',
    authorName: '새우키우기',
    title: '물고기 몸에 갑자기 하얀 반점이 생겼어요',
    content: '어제까지만 해도 괜찮았는데 오늘 아침에 보니까 지느러미랑 몸통에 하얀 점들이 생겼어요. 백점병인가요?',
    tags: ['하얀반점', '초보사육자'],
    viewCount: 49,
    timeAgo: '16시간 전',
    curiousCount: 8,
  );

  final List<TipData> _tips = const [
    TipData(
      id: '1',
      title: '장비는 물속 생태계의 숨은 조력자예요',
      description: '여과기, 히터, 조명의 역할 알아보기',
      icon: Icons.settings_outlined,
      iconBgColor: Color(0xFFEDF8FF),
      iconColor: Color(0xFF0066FF),
    ),
    TipData(
      id: '2',
      title: '먹이는 사랑이지만, 과하면 독이 돼요',
      description: '적정 급여량과 주기 가이드',
      icon: Icons.restaurant_outlined,
      iconBgColor: Color(0xFFFFF0F0),
      iconColor: Color(0xFFFF6B6B),
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
    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      body: Stack(
        children: [
          // Layer 1: Background Header
          _buildBackgroundHeader(),

          // Layer 2: Content Body
          _buildContentBody(),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  /// FAB - 56x56, Blue, White pencil icon
  Widget _buildFAB() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF0066FF),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0066FF).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        onPressed: () {},
        icon: const Icon(Icons.edit, color: Colors.white, size: 24),
      ),
    );
  }

  /// Layer 1: 배경 헤더 (상단 ~25%)
  Widget _buildBackgroundHeader() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.32,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF001F54), Color(0xFF003087)],
        ),
      ),
      child: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: Image.asset(
                'assets/images/main_background.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Content
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Bar: Guide & Notification
                  _buildTopBar(),
                  const SizedBox(height: 24),

                  // Greeting
                  _buildGreeting(),

                  if (_hasAquariums) ...[
                    const SizedBox(height: 16),
                    // Status Chips
                    _buildStatusChips(),
                  ] else ...[
                    const SizedBox(height: 24),
                    // Register Button
                    _buildRegisterButton(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Top Bar: 가이드 & 알림
  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Notification Icon with badge
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
                size: 22,
              ),
            ),
            // Orange badge
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF5C00),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),

        // Guide text
        GestureDetector(
          onTap: () {},
          child: Text(
            '가이드',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
      ],
    );
  }

  /// Greeting Section
  Widget _buildGreeting() {
    if (_hasAquariums) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '미니모 님,',
            style: AppTextStyles.headlineMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '오늘도 덕분에 잘 지내고 있어요!',
            style: AppTextStyles.headlineLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '미니모 님, 반가워요!',
            style: AppTextStyles.headlineMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '첫 어항을 등록해보세요 🐠',
            style: AppTextStyles.headlineLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }
  }

  /// Status Chips (With Data State)
  Widget _buildStatusChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildStatusChip('오늘 챙김 3건', Icons.check_circle_outline),
        _buildStatusChip('물잡이 2일차', Icons.water_drop_outlined),
        _buildStatusChip('약욕중', Icons.medical_services_outlined),
      ],
    );
  }

  Widget _buildStatusChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.captionMedium.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  /// Register Button (Empty State)
  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pushNamed(context, '/aquarium/register');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0066FF),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          '어항 등록하기',
          style: AppTextStyles.bodyMediumMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Layer 2: Content Body (White container with rounded top corners)
  Widget _buildContentBody() {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.72,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 20),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Timeline Section
                _buildTimelineSection(),

                const SizedBox(height: 32),

                // My Aquarium Section (only show if has aquariums)
                if (_hasAquariums) ...[
                  _buildSectionHeader('나의 어항'),
                  const SizedBox(height: 12),
                  AquariumCardList(
                    aquariums: _aquariums,
                    onAquariumTap: (aquarium) {},
                  ),
                  const SizedBox(height: 40),
                ],

                // Recommended Content Section
                _buildSectionHeader('추천 콘텐츠'),
                const SizedBox(height: 12),
                _buildContentCarousel(),
                const SizedBox(height: 40),

                // Q&A Section
                _buildSectionHeader('답변을 기다리고 있어요'),
                const SizedBox(height: 12),
                QnACard(
                  data: _qnaItem,
                  onTap: () {},
                  onCuriousTap: () {},
                  onAnswerTap: () {
                    Navigator.pushNamed(context, '/community-question');
                  },
                ),
                const SizedBox(height: 40),

                // Tips Section
                _buildSectionHeader('오늘의 사육 꿀팁'),
                const SizedBox(height: 12),
                TipList(tips: _tips, onTipTap: (tip) {}),

                const SizedBox(height: 100),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Section Header with "더보기 >" link
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Row(
              children: [
                Text(
                  '더보기',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: const Color(0xFF0066FF),
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: Color(0xFF0066FF),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Timeline Section
  Widget _buildTimelineSection() {
    final now = DateTime.now();
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[now.weekday - 1];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Header
          Text(
            '${now.day}일 ($weekday)',
            style: AppTextStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 20),

          // Timeline Items or Empty State
          if (_scheduleItems.isEmpty || !_hasAquariums)
            _buildEmptyTimeline()
          else
            ..._scheduleItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == _scheduleItems.length - 1;
              return _buildTimelineItem(item, isLast);
            }),
        ],
      ),
    );
  }

  /// Empty Timeline State
  Widget _buildEmptyTimeline() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Text(
            '오늘 할 일이 비어있어요',
            style: AppTextStyles.bodyMedium.copyWith(
              color: const Color(0xFF999999),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '어항을 등록한 후 할 일을 추가해 보세요',
            style: AppTextStyles.bodySmall.copyWith(
              color: const Color(0xFFBDBDBD),
            ),
          ),
        ],
      ),
    );
  }

  /// Timeline Item
  Widget _buildTimelineItem(ScheduleData item, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time Column
          SizedBox(
            width: 60,
            child: Text(
              item.time,
              style: AppTextStyles.captionMedium.copyWith(
                color: const Color(0xFF999999),
              ),
            ),
          ),

          // Timeline Indicator
          SizedBox(
            width: 24,
            child: Column(
              children: [
                // Circle
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: item.isCompleted
                        ? const Color(0xFF0066FF)
                        : Colors.white,
                    border: Border.all(
                      color: item.isCompleted
                          ? const Color(0xFF0066FF)
                          : const Color(0xFFDDDDDD),
                      width: 2,
                    ),
                  ),
                ),
                // Dashed Line
                if (!isLast)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: CustomPaint(
                        painter: _DashedLinePainter(
                          color: const Color(0xFFE0E0E0),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Task Card
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF0F0F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: AppTextStyles.bodyMediumMedium.copyWith(
                            decoration: item.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: item.isCompleted
                                ? const Color(0xFF999999)
                                : const Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.aquariumName,
                          style: AppTextStyles.captionRegular.copyWith(
                            color: const Color(0xFF999999),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Checkbox
                  GestureDetector(
                    onTap: () => _toggleTimeline(item.id, !item.isCompleted),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: item.isCompleted
                            ? const Color(0xFF0066FF)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: item.isCompleted
                              ? const Color(0xFF0066FF)
                              : const Color(0xFFDDDDDD),
                          width: 1.5,
                        ),
                      ),
                      child: item.isCompleted
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
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

  /// Content Carousel with Pagination Dots
  Widget _buildContentCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _contentPageController,
            onPageChanged: (index) {
              setState(() {
                _contentPageIndex = index;
              });
            },
            itemCount: _communityItems.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildContentCard(_communityItems[index]),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        // Pagination Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_communityItems.length, (index) {
            final isActive = index == _contentPageIndex;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 8 : 6,
              height: isActive ? 8 : 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? const Color(0xFF0066FF)
                    : const Color(0xFFE0E0E0),
              ),
            );
          }),
        ),
      ],
    );
  }

  /// Content Card (for carousel)
  Widget _buildContentCard(CommunityData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Row
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEDF8FF),
                ),
                child: const Icon(
                  Icons.person,
                  size: 20,
                  color: Color(0xFF0066FF),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                data.authorName,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '00시간 전',
                style: AppTextStyles.captionRegular.copyWith(
                  color: const Color(0xFF999999),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Content
          Text(
            data.content,
            style: AppTextStyles.bodySmall.copyWith(
              color: const Color(0xFF444444),
              height: 1.6,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          const Spacer(),

          // Interaction Row
          Row(
            children: [
              _buildInteractionIcon(Icons.favorite_border, data.likeCount),
              const SizedBox(width: 16),
              _buildInteractionIcon(
                Icons.chat_bubble_outline,
                data.commentCount,
              ),
              const Spacer(),
              Icon(
                Icons.bookmark_border,
                size: 20,
                color: const Color(0xFF999999),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionIcon(IconData icon, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF999999)),
        const SizedBox(width: 4),
        Text(
          count.toString(),
          style: AppTextStyles.captionRegular.copyWith(
            color: const Color(0xFF999999),
          ),
        ),
      ],
    );
  }
}

/// Dashed Line Painter for Timeline
class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    const dashHeight = 4.0;
    const dashSpace = 4.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
