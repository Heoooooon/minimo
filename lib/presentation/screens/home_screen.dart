import 'package:flutter/material.dart';
import '../../core/utils/app_logger.dart';
import '../../theme/app_colors.dart';
import '../widgets/home/aquarium_card.dart';
import '../widgets/home/qna_card.dart';
import '../widgets/home/tip_card.dart';
import '../widgets/home/community_card.dart';
import '../widgets/common/skeleton_loader.dart';
import '../../domain/models/schedule_data.dart';
import '../../domain/models/record_data.dart';
import '../../data/repositories/schedule_repository.dart';
import '../../data/repositories/record_repository.dart';
import '../../data/repositories/aquarium_repository.dart';
import '../../data/services/auth_service.dart';
import '../../domain/models/aquarium_data.dart' as domain;
import '../widgets/home/home_sticky_top_bar.dart';
import '../widgets/home/home_hero_section.dart';
import '../widgets/home/home_schedule_section.dart';
import '../widgets/home/home_section_header.dart';
import '../widgets/home/home_content_carousel.dart';

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
  HomeContentState createState() => HomeContentState();
}

class HomeContentState extends State<HomeContent> {
  // 어항 데이터 (Mock Repository에서 로드)
  List<AquariumData> _aquariums = [];
  List<domain.AquariumData> _domainAquariums = [];

  final ScheduleRepository _scheduleRepository =
      PocketBaseScheduleRepository.instance;
  final RecordRepository _recordRepository =
      PocketBaseRecordRepository.instance;
  final AquariumRepository _aquariumRepository =
      PocketBaseAquariumRepository.instance;
  List<ScheduleData> _scheduleItems = [];
  List<RecordData> _recordItems = [];

  // 사용자 닉네임
  String _userName = '미니모';

  // 스크롤 컨트롤러 (sticky header용)
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

  // Hero 섹션 높이 (흰색 배경 전환점)
  static const double _heroHeight = 266;

  bool _isLoadingSchedule = true;
  bool _isLoadingRecords = true;
  bool _isLoadingAquariums = true;

  DateTime? _lastAquariumFetchTime;
  DateTime? _lastScheduleFetchTime;
  DateTime? _lastRecordFetchTime;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadSchedule();
    _loadRecords();
    _loadAquariums();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void refreshData() {
    _loadAquariums(forceRefresh: true);
    _loadSchedule(forceRefresh: true);
    _loadRecords(forceRefresh: true);
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

  /// 어항 캐시가 유효한지 확인
  bool _isAquariumCacheValid() {
    return _lastAquariumFetchTime != null &&
        DateTime.now().difference(_lastAquariumFetchTime!) <
            _cacheValidDuration &&
        _domainAquariums.isNotEmpty;
  }

  Future<void> _loadAquariums({bool forceRefresh = false}) async {
    // 캐시가 유효하고 강제 새로고침이 아니면 스킵
    if (!forceRefresh && _isAquariumCacheValid()) {
      if (mounted && _isLoadingAquariums) {
        setState(() {
          _isLoadingAquariums = false;
        });
      }
      return;
    }

    try {
      final domainAquariums = await _aquariumRepository.getAquariums();
      _aquariumRetryCount = 0; // 성공 시 리셋
      _lastAquariumFetchTime = DateTime.now();
      if (mounted) {
        setState(() {
          _domainAquariums = domainAquariums;
          // domain.AquariumData를 UI용 AquariumData로 변환
          _aquariums = domainAquariums
              .map(
                (a) => AquariumData(
                  id: a.id ?? '',
                  name: a.name ?? '이름 없음',
                  imageUrl: a.photoUrl,
                  status: AquariumStatus.healthy,
                  temperature: 27,
                  ph: 7.2,
                  fishCount: 0,
                ),
              )
              .toList();
          _isLoadingAquariums = false;
        });
      }
    } catch (e) {
      AppLogger.data('Error loading aquariums: $e', isError: true);
      // 서버 Cold Start 시 재시도 (최대 3회)
      if (mounted && _aquariumRetryCount < _maxRetries) {
        _aquariumRetryCount++;
        AppLogger.data('Retrying... ($_aquariumRetryCount/$_maxRetries)');
        await Future.delayed(const Duration(seconds: 2));
        _loadAquariums();
      } else if (mounted) {
        setState(() {
          _isLoadingAquariums = false;
        });
      }
    }
  }

  bool _isScheduleCacheValid() {
    return _lastScheduleFetchTime != null &&
        DateTime.now().difference(_lastScheduleFetchTime!) <
            _cacheValidDuration &&
        _scheduleItems.isNotEmpty;
  }

  bool _isRecordCacheValid() {
    return _lastRecordFetchTime != null &&
        DateTime.now().difference(_lastRecordFetchTime!) <
            _cacheValidDuration &&
        _recordItems.isNotEmpty;
  }

  Future<void> _loadRecords({bool forceRefresh = false}) async {
    if (!forceRefresh && _isRecordCacheValid()) {
      if (mounted && _isLoadingRecords) {
        setState(() {
          _isLoadingRecords = false;
        });
      }
      return;
    }

    try {
      final items = await _recordRepository.getRecordsByDate(DateTime.now());
      _lastRecordFetchTime = DateTime.now();
      if (mounted) {
        setState(() {
          _recordItems = items;
          _isLoadingRecords = false;
        });
      }
    } catch (e) {
      AppLogger.data('Error loading records: $e', isError: true);
      if (mounted) {
        setState(() {
          _isLoadingRecords = false;
        });
      }
    }
  }

  Future<void> _loadSchedule({bool forceRefresh = false}) async {
    // 캐시가 유효하고 강제 새로고침이 아니면 스킵
    if (!forceRefresh && _isScheduleCacheValid()) {
      if (mounted && _isLoadingSchedule) {
        setState(() {
          _isLoadingSchedule = false;
        });
      }
      return;
    }

    try {
      final items = await _scheduleRepository.getDailySchedule(DateTime.now());
      _lastScheduleFetchTime = DateTime.now();
      if (mounted) {
        setState(() {
          _scheduleItems = items;
          _isLoadingSchedule = false;
        });
      }
    } catch (e) {
      AppLogger.data('Error loading schedule: $e', isError: true);
      if (mounted) {
        setState(() {
          _isLoadingSchedule = false;
        });
      }
    }
  }

  bool get _hasAquariums => _aquariums.isNotEmpty;

  /// 상태 태그 계산 (오늘 할 일 수, 물잡이 D-day 등)
  List<String> _buildStatusTags() {
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
        final days =
            DateTime.now().difference(firstAquarium.settingDate!).inDays + 1;
        tags.add('물잡이 $days일차');
      }
    }

    return tags;
  }

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

  Future<void> _navigateToScheduleAdd() async {
    final result = await Navigator.pushNamed(context, '/schedule/add');
    if (result == true && mounted) {
      _loadSchedule(forceRefresh: true);
    }
  }

  Future<void> _navigateToAquariumRegister() async {
    final result = await Navigator.pushNamed(context, '/aquarium/register');
    if (result == true && mounted) {
      _loadAquariums(forceRefresh: true);
    }
  }

  Future<void> _navigateToRecordAdd() async {
    final result = await Navigator.pushNamed(context, '/record/add');
    if (result == true && mounted) {
      _loadRecords(forceRefresh: true);
    }
  }

  // Mock 데이터 (추후 실제 데이터로 교체)
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
      content: '출장 다녀왔는데 어항에 이끼 실화인가욬ㅋㅋㅋㅋ청소할 생각에 어지러운데 혹시...',
      imageUrl:
          'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=400',
      likeCount: 12,
      commentCount: 2,
      bookmarkCount: 1,
    ),
    CommunityData(
      id: '3',
      authorName: 'User',
      authorImageUrl: null,
      timeAgo: '00시간 전',
      content: '출장 다녀왔는데 어항에 이끼 실화인가욬ㅋㅋㅋㅋ청소할 생각에 어지러운데 혹시... 더보기',
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
      description:
          '히터, 여과기, 냉각기 등 각 장비가 어떤 역할을 하는지,\n어떻게 안정적인 수질을 유지할 수 있는지 알아봐요.',
      illustrationType: TipIllustrationType.equipment,
    ),
    TipData(
      id: '2',
      title: '먹이는 사랑이지만,\n과하면 독이 돼요',
      description:
          '하루 급여량과 빈도, 사료 종류, 남은 먹이 관리까지.\n수질과 건강을 함께 지키는 먹이 관리 습관을 만들어보세요.',
      illustrationType: TipIllustrationType.feeding,
    ),
  ];

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
                // Hero + Schedule Section
                _buildHeroWithSchedule(),

                // Main Content Area
                Container(
                  color: AppColors.backgroundApp,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),

                      // My Aquarium Section
                      _buildAquariumSection(),

                      // Recommended Content Section
                      HomeSectionHeader(
                        title: '추천 컨텐츠',
                        showMore: true,
                        onMoreTap: () {},
                      ),
                      const SizedBox(height: 11),
                      HomeContentCarousel(
                        items: _communityItems,
                        onItemTap: (_) {},
                      ),
                      const SizedBox(height: 32),

                      // Q&A Section
                      HomeSectionHeader(
                        title: '답변을 기다리고 있어요',
                        showMore: true,
                        onMoreTap: () {},
                      ),
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
                      HomeSectionHeader(
                        title: '오늘의 사육 꿀팁',
                        showMore: true,
                        onMoreTap: () {},
                      ),
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
            child: HomeStickyTopBar(
              isScrolledPastHero: isScrolledPastHero,
              backgroundOpacity: topBarBackgroundOpacity,
              onNotificationTap: () {},
              onGuideTap: () {},
            ),
          ),
        ],
      ),
    );
  }

  /// Hero + Schedule combined widget for proper overlap
  Widget _buildHeroWithSchedule() {
    return Column(
      children: [
        // Hero Section
        Stack(
          clipBehavior: Clip.none,
          children: [
            HomeHeroSection(
              userName: _userName,
              hasAquariums: _hasAquariums,
              statusTags: _buildStatusTags(),
              onRegisterTap: _navigateToAquariumRegister,
            ),
          ],
        ),
        HomeScheduleSection(
          recordItems: _recordItems,
          hasAquariums: _hasAquariums,
          isLoading: _isLoadingRecords,
          onAddRecordTap: _navigateToRecordAdd,
          onExpandTap: () {},
        ),
      ],
    );
  }

  /// 어항 섹션 빌드
  Widget _buildAquariumSection() {
    if (_isLoadingAquariums) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeSectionHeader(title: '나의 어항', showMore: false),
          const SizedBox(height: 16),
          const AquariumCardSkeleton(),
          const SizedBox(height: 32),
        ],
      );
    }

    if (!_hasAquariums) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(title: '나의 어항', showMore: false),
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
    );
  }
}
