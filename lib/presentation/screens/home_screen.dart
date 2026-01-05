import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/bottom_nav_bar.dart';
import '../widgets/home/hero_section.dart';
import '../widgets/home/aquarium_card.dart';
import '../widgets/home/schedule_item.dart';
import '../widgets/home/community_card.dart';
import '../widgets/home/qna_card.dart';
import '../widgets/home/tip_card.dart';

/// 홈 화면
///
/// Figma 디자인 03-01, 03-02 기반
/// - 03-01: 어항 미등록 상태
/// - 03-02: 어항 등록 후 상태
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  NavTab _currentTab = NavTab.home;

  // 데모용 상태 - 실제로는 Provider/Riverpod 등으로 관리
  bool _hasAquarium = true; // true: 03-02, false: 03-01

  // 샘플 데이터
  final List<AquariumData> _aquariums = const [
    AquariumData(
      id: '1',
      name: '거실 어항',
      status: AquariumStatus.healthy,
      temperature: 26,
      ph: 7.2,
    ),
    AquariumData(
      id: '2',
      name: '침실 어항',
      status: AquariumStatus.treatment,
      temperature: 25,
      ph: 6.8,
    ),
    AquariumData(
      id: '3',
      name: '베란다 어항',
      status: AquariumStatus.healthy,
      temperature: 24,
      ph: 7.0,
    ),
  ];

  List<ScheduleData> _schedules = [
    const ScheduleData(
      id: '1',
      time: '09:00',
      title: '먹이주기',
      aquariumName: '거실 어항',
      isCompleted: true,
    ),
    const ScheduleData(
      id: '2',
      time: '14:00',
      title: '수질검사',
      aquariumName: '침실 어항',
      isCompleted: false,
    ),
    const ScheduleData(
      id: '3',
      time: '18:00',
      title: '물갈이',
      aquariumName: '거실 어항',
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
    CommunityData(
      id: '3',
      authorName: '금붕어사랑',
      content: '오란다 금붕어 사육하시는 분 계신가요? 수온 관리 팁 좀 부탁드려요!',
      likeCount: 15,
      commentCount: 6,
      bookmarkCount: 2,
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

  void _toggleSchedule(ScheduleData schedule, bool value) {
    setState(() {
      _schedules = _schedules.map((s) {
        if (s.id == schedule.id) {
          return s.copyWith(isCompleted: value);
        }
        return s;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      body: _buildBody(),
      bottomNavigationBar: AppBottomNavBar(
        currentTab: _currentTab,
        onTabSelected: (tab) {
          setState(() {
            _currentTab = tab;
          });
          // TODO: 탭별 화면 전환 구현
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: 글쓰기 화면으로 이동
        },
        backgroundColor: AppColors.brand,
        child: const Icon(Icons.edit, color: AppColors.textInverse),
      ),
    );
  }

  Widget _buildBody() {
    return CustomScrollView(
      slivers: [
        // 히어로 섹션
        SliverToBoxAdapter(
          child: HeroSection(
            userName: '물생활러',
            hasAquarium: _hasAquarium,
            todayTaskCount: _schedules.where((s) => s.isCompleted).length,
            waterCycleDay: 15,
            onNotificationTap: () {
              // TODO: 알림 화면
            },
            onGuideTap: () {
              // TODO: 가이드 화면
            },
            onRegisterTap: () {
              Navigator.pushNamed(context, '/tank-register');
            },
          ),
        ),

        // 콘텐츠 영역 (둥근 모서리 배경)
        SliverToBoxAdapter(
          child: Transform.translate(
            offset: const Offset(0, -24),
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.backgroundApp,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // 어항 등록 후에만 표시되는 섹션들
                  if (_hasAquarium) ...[
                    // 나의 어항 섹션
                    SectionHeader(
                      title: '나의 어항',
                      onMoreTap: () {
                        // TODO: 어항 목록 화면
                      },
                    ),
                    const SizedBox(height: 4),
                    AquariumCardList(
                      aquariums: _aquariums,
                      onAquariumTap: (aquarium) {
                        // TODO: 어항 상세 화면
                      },
                    ),
                    const SizedBox(height: 24),

                    // 오늘 일정 섹션
                    SectionHeader(
                      title: '오늘 일정 (${DateTime.now().day}일 ${_getWeekday()})',
                      onMoreTap: () {
                        // TODO: 일정 목록 화면
                      },
                    ),
                    const SizedBox(height: 4),
                    ScheduleList(
                      schedules: _schedules,
                      onCheckChanged: _toggleSchedule,
                      onItemTap: (schedule) {
                        // TODO: 일정 상세
                      },
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 추천 콘텐츠 섹션
                  SectionHeader(
                    title: '추천 콘텐츠',
                    onMoreTap: () {
                      // TODO: 콘텐츠 목록 화면
                    },
                  ),
                  const SizedBox(height: 4),
                  CommunityCardList(
                    items: _communityItems,
                    onItemTap: (item) {
                      // TODO: 콘텐츠 상세 화면
                    },
                  ),
                  const SizedBox(height: 24),

                  // 답변 대기 섹션
                  SectionHeader(
                    title: '답변 대기',
                    onMoreTap: () {
                      // TODO: Q&A 목록 화면
                    },
                  ),
                  const SizedBox(height: 4),
                  QnACard(
                    data: _qnaItem,
                    onTap: () {
                      // TODO: Q&A 상세 화면
                    },
                    onCuriousTap: () {
                      // TODO: 궁금해요 토글
                    },
                    onAnswerTap: () {
                      Navigator.pushNamed(context, '/community-question');
                    },
                  ),
                  const SizedBox(height: 24),

                  // 사육 꿀팁 섹션
                  SectionHeader(
                    title: '사육 꿀팁',
                    onMoreTap: () {
                      // TODO: 꿀팁 목록 화면
                    },
                  ),
                  const SizedBox(height: 4),
                  TipList(
                    tips: _tips,
                    onTipTap: (tip) {
                      // TODO: 꿀팁 상세 화면
                    },
                  ),
                  const SizedBox(height: 100), // FAB 여백
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getWeekday() {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return weekdays[DateTime.now().weekday - 1];
  }
}
