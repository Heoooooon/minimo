import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/app_logger.dart';
import '../../core/di/app_dependencies.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';
import '../widgets/home/aquarium_card.dart';
import '../widgets/home/qna_card.dart';
import '../widgets/home/tip_card.dart';
import '../widgets/home/community_card.dart';
import 'package:cmore_design_system/widgets/skeleton_loader.dart';
import '../../domain/models/schedule_data.dart';
import '../../domain/models/record_data.dart';
import '../../domain/models/question_data.dart';
import '../../data/repositories/schedule_repository.dart';
import '../../data/repositories/record_repository.dart';
import '../../data/repositories/aquarium_repository.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/community_service.dart';
import '../../data/services/creature_service.dart';
import '../../domain/models/aquarium_data.dart' as domain;
import '../widgets/home/home_sticky_top_bar.dart';
import '../widgets/home/home_hero_section.dart';
import '../widgets/home/home_schedule_section.dart';
import '../widgets/home/home_section_header.dart';
import '../widgets/home/home_content_carousel.dart';
import '../widgets/home/home_guide_section.dart';

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

  late final AppDependencies _dependencies;
  late final ScheduleRepository _scheduleRepository;
  late final RecordRepository _recordRepository;
  late final AquariumRepository _aquariumRepository;
  late final AuthService _authService;
  late final CommunityService _communityService;
  List<ScheduleData> _scheduleItems = [];
  List<RecordData> _recordItems = [];

  // 사용자 닉네임
  String _userName = '미니모';

  // 스크롤 컨트롤러 (sticky header용)
  final ScrollController _scrollController = ScrollController();
  // 가이드 섹션 스크롤 키
  final GlobalKey _guideKey = GlobalKey();
  double _scrollOffset = 0;

  // Hero 섹션 높이 (흰색 배경 전환점)
  static const double _heroHeight = 266;

  bool _isLoadingSchedule = true;
  bool _isLoadingRecords = true;
  bool _isLoadingAquariums = true;
  bool _isLoadingCommunity = true;
  bool _isTimelineExpanded = false;
  bool _hasAquariumError = false;

  DateTime? _lastAquariumFetchTime;
  DateTime? _lastScheduleFetchTime;
  DateTime? _lastRecordFetchTime;
  DateTime? _lastCommunityFetchTime;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  // 커뮤니티 데이터
  List<CommunityData> _communityItems = [];
  QnAData? _qnaItem;
  bool _isDependenciesReady = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isDependenciesReady) return;

    _dependencies = context.read<AppDependencies>();
    _scheduleRepository = _dependencies.scheduleRepository;
    _recordRepository = _dependencies.recordRepository;
    _aquariumRepository = _dependencies.aquariumRepository;
    _authService = _dependencies.authService;
    _communityService = _dependencies.communityService;
    _isDependenciesReady = true;

    _loadUserInfo();
    _loadSchedule();
    _loadRecords();
    _loadAquariums();
    _loadCommunityData();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void refreshData() {
    setState(() {
      _hasAquariumError = false;
    });
    _loadAquariums(forceRefresh: true);
    _loadSchedule(forceRefresh: true);
    _loadRecords(forceRefresh: true);
    _loadCommunityData(forceRefresh: true);
  }

  void _onScroll() {
    final newOffset = _scrollController.offset;
    // 의미있는 변화가 있을 때만 리빌드 (5px 이상 차이)
    if ((newOffset - _scrollOffset).abs() > 5) {
      setState(() {
        _scrollOffset = newOffset;
      });
    }
  }

  void _loadUserInfo() {
    final user = _authService.currentUser;
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
            _cacheValidDuration;
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

      // 각 어항별 생물 수 로드
      final creatureService = CreatureService.instance;
      final Map<String, int> creatureCounts = {};
      for (final a in domainAquariums) {
        if (a.id != null) {
          try {
            final creatures = await creatureService.getCreaturesByAquarium(a.id!);
            creatureCounts[a.id!] = creatures.fold<int>(
              0, (sum, c) => sum + c.quantity,
            );
          } catch (_) {
            creatureCounts[a.id!] = 0;
          }
        }
      }

      if (mounted) {
        setState(() {
          _domainAquariums = domainAquariums;
          _aquariums = domainAquariums
              .map(
                (a) => AquariumData(
                  id: a.id ?? '',
                  name: a.name ?? '이름 없음',
                  imageUrl: a.photoUrl,
                  fishCount: creatureCounts[a.id] ?? 0,
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
          _hasAquariumError = true;
        });
      }
    }
  }

  bool _isScheduleCacheValid() {
    return _lastScheduleFetchTime != null &&
        DateTime.now().difference(_lastScheduleFetchTime!) <
            _cacheValidDuration;
  }

  bool _isRecordCacheValid() {
    return _lastRecordFetchTime != null &&
        DateTime.now().difference(_lastRecordFetchTime!) < _cacheValidDuration;
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

  bool _isCommunityCacheValid() {
    return _lastCommunityFetchTime != null &&
        DateTime.now().difference(_lastCommunityFetchTime!) <
            _cacheValidDuration &&
        (_communityItems.isNotEmpty || _qnaItem != null);
  }

  Future<void> _loadCommunityData({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCommunityCacheValid()) {
      if (mounted && _isLoadingCommunity) {
        setState(() {
          _isLoadingCommunity = false;
        });
      }
      return;
    }

    try {
      // 커뮤니티 게시글 로드 (최신순 3개)
      final posts = await _communityService.getPosts(
        perPage: 3,
        sort: '-created',
      );

      // Q&A 질문 로드 (답변 없는 최신 1개)
      final questions = await _communityService.getQuestions(
        perPage: 1,
        sort: '-created',
      );

      _lastCommunityFetchTime = DateTime.now();
      if (mounted) {
        setState(() {
          _communityItems = posts;
          _qnaItem = questions.isNotEmpty
              ? _questionToQnAData(questions.first)
              : null;
          _isLoadingCommunity = false;
        });
      }
    } catch (e) {
      AppLogger.data('Error loading community data: $e', isError: true);
      if (mounted) {
        setState(() {
          _isLoadingCommunity = false;
        });
      }
    }
  }

  /// QuestionData를 QnAData로 변환
  QnAData _questionToQnAData(QuestionData q) {
    // 작성 시간 계산
    String timeAgo = '방금 전';
    if (q.created != null) {
      final diff = DateTime.now().difference(q.created!);
      if (diff.inDays > 0) {
        timeAgo = '${diff.inDays}일 전';
      } else if (diff.inHours > 0) {
        timeAgo = '${diff.inHours}시간 전';
      } else if (diff.inMinutes > 0) {
        timeAgo = '${diff.inMinutes}분 전';
      }
    }

    return QnAData(
      id: q.id ?? '',
      authorName: '익명',
      title: q.title,
      content: q.content,
      tags: [],
      viewCount: q.viewCount,
      timeAgo: timeAgo,
      curiousCount: 0,
    );
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

  void _toggleTimelineExpand() {
    setState(() {
      _isTimelineExpanded = !_isTimelineExpanded;
    });
  }

  Future<void> _navigateToAquariumRegister() async {
    final result = await Navigator.pushNamed(context, '/aquarium/register');
    if (result == true && mounted) {
      _loadAquariums(forceRefresh: true);
    }
  }

  Future<void> _navigateToRecordAdd() async {
    final result = await Navigator.pushNamed(context, '/record');
    if (result == true && mounted) {
      _loadRecords(forceRefresh: true);
    }
  }

  // Tips는 아직 API가 없으므로 하드코딩 유지
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

                      // Guide Section
                      HomeSectionHeader(
                        key: _guideKey,
                        title: '사육 가이드',
                        showMore: false,
                      ),
                      const SizedBox(height: 11),
                      HomeGuideSection(
                        onStepTap: (step) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${step.title} - 상세 가이드 준비 중'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),

                      // My Aquarium Section
                      _buildAquariumSection(),

                      // Recommended Content Section
                      if (_communityItems.isNotEmpty) ...[
                        HomeSectionHeader(
                          title: '추천 컨텐츠',
                          showMore: true,
                          onMoreTap: () {
                            Navigator.pushNamed(
                              context,
                              '/more-list',
                              arguments: {'type': 'posts', 'title': '추천 컨텐츠'},
                            );
                          },
                        ),
                        const SizedBox(height: 11),
                        HomeContentCarousel(
                          items: _communityItems,
                          onItemTap: (item) {
                            Navigator.pushNamed(
                              context,
                              '/post-detail',
                              arguments: item.id,
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                      ],

                      // Q&A Section
                      if (_qnaItem != null) ...[
                        HomeSectionHeader(
                          title: '답변을 기다리고 있어요',
                          showMore: true,
                          onMoreTap: () {
                            Navigator.pushNamed(
                              context,
                              '/more-list',
                              arguments: {
                                'type': 'questions',
                                'title': '답변을 기다리고 있어요',
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 11),
                        QnACard(
                          data: _qnaItem!,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/question-detail',
                              arguments: _qnaItem!.id,
                            );
                          },
                          onCuriousTap: () {
                            Navigator.pushNamed(
                              context,
                              '/question-detail',
                              arguments: _qnaItem!.id,
                            );
                          },
                          onAnswerTap: () {
                            Navigator.pushNamed(context, '/community-question');
                          },
                        ),
                        const SizedBox(height: 32),
                      ],

                      // Tips Section
                      HomeSectionHeader(title: '오늘의 사육 꿀팁', showMore: false),
                      const SizedBox(height: 11),
                      TipList(
                        tips: _tips,
                        onTipTap: (tip) {
                          // 팁은 현재 정적 데이터이므로 SnackBar로 안내
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${tip.title.replaceAll('\n', ' ')} - 상세 기능 준비 중',
                              ),
                            ),
                          );
                        },
                      ),

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
              onNotificationTap: () {
                Navigator.pushNamed(context, '/notifications');
              },
              onGuideTap: () {
                final guideContext = _guideKey.currentContext;
                if (guideContext != null) {
                  Scrollable.ensureVisible(
                    guideContext,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                }
              },
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
          isExpanded: _isTimelineExpanded,
          onAddRecordTap: _navigateToRecordAdd,
          onExpandTap: _toggleTimelineExpand,
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

    if (_hasAquariumError) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeSectionHeader(title: '나의 어항', showMore: false),
          const SizedBox(height: 16),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(Icons.wifi_off, size: 32, color: AppColors.textHint),
                  const SizedBox(height: 8),
                  Text(
                    '데이터를 불러오지 못했습니다',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSubtle,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() => _hasAquariumError = false);
                      _aquariumRetryCount = 0;
                      _loadAquariums(forceRefresh: true);
                    },
                    child: Text(
                      '다시 시도',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.brand,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
