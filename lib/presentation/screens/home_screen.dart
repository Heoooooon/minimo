import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/bottom_nav_bar.dart';
import '../widgets/home/aquarium_card.dart';
import '../widgets/home/community_card.dart';
import '../widgets/home/qna_card.dart';
import '../widgets/home/tip_card.dart';

/// 홈 화면
///
/// Figma 디자인 03-02 기반
/// Stack 레이아웃으로 배경 이미지와 콘텐츠 영역 분리
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  NavTab _currentTab = NavTab.home;

  // 샘플 데이터
  final List<AquariumData> _aquariums = const [
    AquariumData(
      id: '1',
      name: '러키네',
      status: AquariumStatus.healthy,
      temperature: 27,
      ph: 7.2,
    ),
    AquariumData(
      id: '2',
      name: '호동이네',
      status: AquariumStatus.treatment,
      temperature: 26,
      ph: 6.8,
    ),
    AquariumData(
      id: '3',
      name: '베란다',
      status: AquariumStatus.healthy,
      temperature: 25,
      ph: 7.0,
    ),
  ];

  final List<_TimelineItem> _timelineItems = [
    _TimelineItem(
      id: '1',
      time: '08:00',
      title: '호동이 먹이주기',
      aquariumName: '호동이네',
      isCompleted: true,
    ),
    _TimelineItem(
      id: '2',
      time: '14:00',
      title: '러키 수질검사',
      aquariumName: '러키네',
      isCompleted: false,
    ),
    _TimelineItem(
      id: '3',
      time: '18:00',
      title: '물갈이',
      aquariumName: '러키네',
      isCompleted: false,
    ),
  ];

  final List<CommunityData> _communityItems = const [
    CommunityData(
      id: '1',
      authorName: '물생활마스터',
      content: '새로 들인 네온테트라가 적응을 잘 못하는 것 같아요. 다른 분들은 어떻게 하셨나요?',
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
    title: '체리새우가 자꾸 죽어요',
    content: '수질도 괜찮은데 매일 1-2마리씩 죽어나가네요. 원인이 뭘까요?',
    tags: ['새우', '수질', 'TDS'],
    viewCount: 156,
    timeAgo: '2시간 전',
    curiousCount: 8,
  );

  final List<TipData> _tips = const [
    TipData(
      id: '1',
      title: '여름철 수온 관리 꿀팁',
      description: '폭염에도 안전하게 어항 관리하는 방법',
      icon: Icons.thermostat,
      iconBgColor: Color(0xFFFFEAE6),
      iconColor: Color(0xFFE72A07),
    ),
    TipData(
      id: '2',
      title: '물잡이 기간 단축하기',
      description: '박테리아 활성화로 빠른 물잡이 완성',
      icon: Icons.science,
      iconBgColor: Color(0xFFEDF8FF),
      iconColor: Color(0xFF0165FE),
    ),
  ];

  void _toggleTimeline(String id, bool value) {
    setState(() {
      final index = _timelineItems.indexWhere((item) => item.id == id);
      if (index != -1) {
        _timelineItems[index] = _timelineItems[index].copyWith(
          isCompleted: value,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      body: Stack(
        children: [
          // Layer 1: Background Header with Image
          _buildBackgroundHeader(),

          // Layer 2: Foreground Body (Scrollable)
          _buildForegroundBody(),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentTab: _currentTab,
        onTabSelected: (tab) {
          setState(() {
            _currentTab = tab;
          });
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: 글쓰기 화면으로 이동
        },
        backgroundColor: AppColors.brand,
        elevation: 4,
        child: const Icon(Icons.edit, color: AppColors.textInverse),
      ),
    );
  }

  /// Layer 1: 배경 이미지 헤더 (상단 35%)
  Widget _buildBackgroundHeader() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.35,
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/main_background.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        // 그라데이션 오버레이 (텍스트 가독성)
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.3),
              Colors.black.withValues(alpha: 0.1),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단 액션 바
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        // TODO: 가이드 화면
                      },
                      child: Text(
                        '가이드',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textInverse.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // TODO: 알림 화면
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.notifications_outlined,
                          color: AppColors.textInverse,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 메인 인사말
                Text(
                  '미니모 님,',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.textInverse,
                  ),
                ),
                Text(
                  '오늘도 덕분에 잘 지내고 있어요!',
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: AppColors.textInverse,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Layer 2: 둥근 모서리 콘텐츠 영역
  Widget _buildForegroundBody() {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.72,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.backgroundApp,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 드래그 핸들
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // 타임라인 섹션
                _buildTimelineSection(),
                const SizedBox(height: 24),

                // 나의 어항 섹션
                SectionHeader(title: '나의 어항', onMoreTap: () {}),
                const SizedBox(height: 4),
                AquariumCardList(
                  aquariums: _aquariums,
                  onAquariumTap: (aquarium) {},
                ),
                const SizedBox(height: 24),

                // 추천 콘텐츠 섹션
                SectionHeader(title: '추천 콘텐츠', onMoreTap: () {}),
                const SizedBox(height: 4),
                CommunityCardList(items: _communityItems, onItemTap: (item) {}),
                const SizedBox(height: 24),

                // 답변 대기 섹션
                SectionHeader(title: '답변 대기', onMoreTap: () {}),
                const SizedBox(height: 4),
                QnACard(
                  data: _qnaItem,
                  onTap: () {},
                  onCuriousTap: () {},
                  onAnswerTap: () {
                    Navigator.pushNamed(context, '/community-question');
                  },
                ),
                const SizedBox(height: 24),

                // 사육 꿀팁 섹션
                SectionHeader(title: '사육 꿀팁', onMoreTap: () {}),
                const SizedBox(height: 4),
                TipList(tips: _tips, onTipTap: (tip) {}),
                const SizedBox(height: 100),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 타임라인 섹션 (오늘 일정)
  Widget _buildTimelineSection() {
    final now = DateTime.now();
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[now.weekday - 1];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 날짜 헤더
          Text(
            '${now.day}일 ($weekday)',
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // 타임라인 아이템들
          ...List.generate(_timelineItems.length, (index) {
            final item = _timelineItems[index];
            final isLast = index == _timelineItems.length - 1;

            return _buildTimelineRow(item, isLast);
          }),
        ],
      ),
    );
  }

  /// 타임라인 행
  Widget _buildTimelineRow(_TimelineItem item, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 시간
          SizedBox(
            width: 50,
            child: Text(
              item.time,
              style: AppTextStyles.captionMedium.copyWith(
                color: AppColors.textSubtle,
              ),
            ),
          ),

          // 점선 + 점
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: item.isCompleted
                        ? AppColors.brand
                        : AppColors.backgroundSurface,
                    border: Border.all(
                      color: item.isCompleted
                          ? AppColors.brand
                          : AppColors.border,
                      width: 2,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: CustomPaint(
                        painter: _DottedLinePainter(color: AppColors.border),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 할일 내용
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.backgroundSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
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
                                ? AppColors.textSubtle
                                : AppColors.textMain,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.water_drop_outlined,
                              size: 12,
                              color: AppColors.textHint,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.aquariumName,
                              style: AppTextStyles.captionRegular.copyWith(
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Transform.scale(
                    scale: 1.1,
                    child: Checkbox(
                      value: item.isCompleted,
                      onChanged: (value) =>
                          _toggleTimeline(item.id, value ?? false),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
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
}

/// 타임라인 아이템 모델
class _TimelineItem {
  final String id;
  final String time;
  final String title;
  final String aquariumName;
  final bool isCompleted;

  _TimelineItem({
    required this.id,
    required this.time,
    required this.title,
    required this.aquariumName,
    this.isCompleted = false,
  });

  _TimelineItem copyWith({bool? isCompleted}) {
    return _TimelineItem(
      id: id,
      time: time,
      title: title,
      aquariumName: aquariumName,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// 점선 페인터
class _DottedLinePainter extends CustomPainter {
  final Color color;

  _DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    const dashHeight = 3.0;
    const dashSpace = 3.0;
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
