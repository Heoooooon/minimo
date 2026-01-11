import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io';
import '../../../domain/models/aquarium_data.dart';
import '../../../domain/models/creature_data.dart';
import '../../../domain/models/gallery_photo_data.dart';
import '../../../data/services/creature_service.dart';
import '../../../data/services/gallery_photo_service.dart';
import '../../../theme/app_colors.dart';

/// 어항 상세 화면
///
/// Figma 디자인 기반 - 어항 상세 정보 표시
/// 사진 유무에 따라 레이아웃이 달라짐
class AquariumDetailScreen extends StatefulWidget {
  const AquariumDetailScreen({super.key});

  @override
  State<AquariumDetailScreen> createState() => _AquariumDetailScreenState();
}

class _AquariumDetailScreenState extends State<AquariumDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AquariumData? _aquarium;
  List<CreatureData> _creatures = [];
  List<GalleryPhotoData> _galleryPhotos = [];
  String? _selectedCreatureFilter; // null이면 전체
  bool _sortNewest = true; // true: 최신순, false: 오래된순
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  Future<void> _loadData() async {
    if (_aquarium?.id == null) return;

    setState(() => _isLoading = true);

    try {
      final creatures = await CreatureService.instance.getCreaturesByAquarium(_aquarium!.id!);
      final photos = await GalleryPhotoService.instance.getPhotosByAquarium(
        _aquarium!.id!,
        newestFirst: _sortNewest,
      );

      if (mounted) {
        setState(() {
          _creatures = creatures;
          _galleryPhotos = photos;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is AquariumData && _aquarium?.id != args.id) {
      _aquarium = args;
      _loadData();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _hasPhoto =>
      _aquarium?.photoUrl != null || _aquarium?.photoPath != null;

  int _calculateDays(DateTime? date) {
    if (date == null) return 0;
    return DateTime.now().difference(date).inDays;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  void _onAddButtonPressed() {
    switch (_tabController.index) {
      case 0:
        // 생물 추가하기 -> 생물 검색 화면으로 이동
        Navigator.pushNamed(
          context,
          '/creature/search',
          arguments: _aquarium,
        );
        break;
      case 1:
        // TODO: 알림 추가 기능
        break;
      case 2:
        // TODO: 사진 추가 기능
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_aquarium == null) {
      return Scaffold(
        body: Center(child: Text('어항 정보를 불러올 수 없습니다.')),
      );
    }

    // 사진 유무에 따라 다른 레이아웃
    if (_hasPhoto) {
      return _buildWithPhotoLayout();
    } else {
      return _buildWithoutPhotoLayout();
    }
  }

  /// 사진이 있는 경우 레이아웃
  Widget _buildWithPhotoLayout() {
    final isTreatment = _aquarium!.purpose == AquariumPurpose.fry;
    final daysCount = _calculateDays(_aquarium!.settingDate);

    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      body: Stack(
        children: [
          // 상단 이미지 영역
          _buildHeaderImage(),

          // 콘텐츠
          Column(
            children: [
              // 상단 앱바 (흰색 아이콘)
              _buildAppBar(isOverImage: true),

              const SizedBox(height: 135),

              // 메인 콘텐츠 (흰색 카드)
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.backgroundApp,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildInfoSection(isTreatment, daysCount),
                      _buildTabBar(),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildCreatureTab(),
                            _buildEmptyState('알림'),
                            _buildGalleryTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 하단 버튼
          _buildBottomButton(),
        ],
      ),
    );
  }

  /// 사진이 없는 경우 레이아웃 (확장형)
  Widget _buildWithoutPhotoLayout() {
    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      body: Column(
        children: [
          // 상단 앱바 (검은색 아이콘, 어항 이름 표시)
          _buildAppBar(isOverImage: false),

          // 탭 바
          _buildTabBar(),

          // 탭 콘텐츠
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCreatureTab(),
                _buildEmptyState('알림'),
                _buildGalleryTab(),
              ],
            ),
          ),

          // 하단 버튼
          _buildBottomButtonInline(),
        ],
      ),
    );
  }

  Widget _buildHeaderImage() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 299,
        decoration: BoxDecoration(
          color: AppColors.brand.withValues(alpha: 0.3),
          image: _aquarium?.photoUrl != null
              ? DecorationImage(
                  image: NetworkImage(_aquarium!.photoUrl!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                const Color(0xFFA9C7FF).withValues(alpha: 0.3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar({required bool isOverImage}) {
    final iconColor = isOverImage ? Colors.white : const Color(0xFF212529);
    final textColor = isOverImage ? Colors.white : const Color(0xFF212529);
    final title = isOverImage ? '어항' : (_aquarium?.name ?? '어항');

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 뒤로가기 버튼
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back_ios,
                color: iconColor,
                size: 24,
              ),
            ),

            // 타이틀
            Text(
              title,
              style: TextStyle(
                fontFamily: 'WantedSans',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
                height: 26 / 18,
                letterSpacing: -0.5,
              ),
            ),

            // 편집 버튼
            IconButton(
              onPressed: () {
                // TODO: 어항 편집 기능
              },
              icon: Icon(
                Icons.edit_outlined,
                color: iconColor,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(bool isTreatment, int daysCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 왼쪽: 이름 + 태그 + 생물 수
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 이름 + 태그
              Row(
                children: [
                  Text(
                    _aquarium?.name ?? '이름 없음',
                    style: const TextStyle(
                      fontFamily: 'WantedSans',
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF212529),
                      height: 32 / 22,
                      letterSpacing: -0.25,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildTag(isTreatment),
                ],
              ),
              const SizedBox(height: 4),
              // 생물 수
              Row(
                children: [
                  SvgPicture.asset(
                    'assets/icons/icon_fish.svg',
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF666E78),
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '0', // TODO: 실제 생물 수
                    style: TextStyle(
                      fontFamily: 'WantedSans',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF666E78),
                      height: 20 / 14,
                      letterSpacing: -0.25,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 오른쪽: D+ 카운트 + 날짜
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // D+ 카운트
              Text(
                'D+$daysCount',
                style: TextStyle(
                  fontFamily: 'WantedSans',
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: isTreatment ? AppColors.orange700 : AppColors.brand,
                  height: 26 / 18,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              // 날짜
              Row(
                children: [
                  SvgPicture.asset(
                    'assets/icons/icon_calendar.svg',
                    width: 16,
                    height: 16,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF666E78),
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(_aquarium?.settingDate),
                    style: const TextStyle(
                      fontFamily: 'WantedSans',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF666E78),
                      height: 20 / 14,
                      letterSpacing: -0.25,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(bool isTreatment) {
    final String label;
    final Color bgColor;
    final Color textColor;

    if (isTreatment) {
      label = '치료항';
      bgColor = AppColors.orange50;
      textColor = AppColors.orange500;
    } else if (_aquarium?.type == AquariumType.freshwater) {
      label = '담수항';
      bgColor = AppColors.blue50;
      textColor = AppColors.brand;
    } else if (_aquarium?.type == AquariumType.saltwater) {
      label = '해수항';
      bgColor = AppColors.chipPrimaryBg;
      textColor = AppColors.brand;
    } else {
      label = '일반';
      bgColor = AppColors.backgroundDisabled;
      textColor = AppColors.textSubtle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'WantedSans',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
          height: 18 / 12,
          letterSpacing: -0.25,
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      labelColor: AppColors.brand,
      unselectedLabelColor: const Color(0xFF666E78),
      labelStyle: const TextStyle(
        fontFamily: 'WantedSans',
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 24 / 16,
        letterSpacing: -0.5,
      ),
      unselectedLabelStyle: const TextStyle(
        fontFamily: 'WantedSans',
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 24 / 16,
        letterSpacing: -0.5,
      ),
      indicator: const UnderlineTabIndicator(
        borderSide: BorderSide(
          color: AppColors.brand,
          width: 1.5,
        ),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: const Color(0xFFE8EBF0),
      tabs: const [
        Tab(text: '생물'),
        Tab(text: '알림'),
        Tab(text: '갤러리'),
      ],
    );
  }

/// 생물 탭 콘텐츠
  Widget _buildCreatureTab() {
    return Column(
      children: [
        // 상단 툴바 (뷰 전환 + 생물 추가 버튼)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 그리드/리스트 뷰 전환 버튼
              Row(
                children: [
                  _buildViewToggleButton(Icons.grid_view, true),
                  _buildViewToggleButton(Icons.format_list_bulleted, false),
                ],
              ),
              // 생물 추가 버튼
              GestureDetector(
                onTap: _onAddButtonPressed,
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.brand, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 16, color: AppColors.brand),
                      const SizedBox(width: 8),
                      Text(
                        '생물 추가',
                        style: TextStyle(
                          fontFamily: 'WantedSans',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.brand,
                          height: 20 / 14,
                          letterSpacing: -0.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // 생물 그리드
        Expanded(
          child: _creatures.isEmpty
              ? _buildEmptyState('생물')
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 13,
                    mainAxisSpacing: 12,
                    childAspectRatio: 165 / 150,
                  ),
                  itemCount: _creatures.length,
                  itemBuilder: (context, index) {
                    return _buildCreatureCard(_creatures[index]);
                  },
                ),
        ),
      ],
    );
  }

  /// 뷰 전환 버튼
  Widget _buildViewToggleButton(IconData icon, bool isSelected) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: 24,
        color: isSelected ? const Color(0xFF212529) : const Color(0xFF9CA5AE),
      ),
    );
  }

  /// 생물 카드 위젯 (그리드 스타일)
  Widget _buildCreatureCard(CreatureData creature) {
    final hasPhoto = creature.photoUrls.isNotEmpty;

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/creature/detail',
          arguments: creature,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: hasPhoto ? null : AppColors.backgroundDisabled,
          borderRadius: BorderRadius.circular(8),
          image: hasPhoto
              ? DecorationImage(
                  image: creature.photoUrls.first.startsWith('/')
                      ? FileImage(File(creature.photoUrls.first))
                      : NetworkImage(creature.photoUrls.first) as ImageProvider,
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: Stack(
          children: [
            // 그라데이션 오버레이 (이미지 있을 때만)
            if (hasPhoto)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        const Color(0xFF212529).withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
              ),
            // 콘텐츠
            Positioned(
              left: 16,
              right: 16,
              bottom: hasPhoto ? 16 : 16,
              top: hasPhoto ? null : 50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 빈 상태일 때 물고기 아이콘
                  if (!hasPhoto)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 28),
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/icons/icon_fish.svg',
                          width: 32,
                          height: 32,
                          colorFilter: const ColorFilter.mode(
                            Color(0xFF9CA5AE),
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  // 이름과 마릿수
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 이름
                      Expanded(
                        child: Text(
                          creature.displayName,
                          style: TextStyle(
                            fontFamily: 'WantedSans',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: hasPhoto
                                ? const Color(0xFFF9FAFC)
                                : const Color(0xFF212529),
                            height: 24 / 16,
                            letterSpacing: -0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 물고기 아이콘 + 마릿수
                      Row(
                        children: [
                          SvgPicture.asset(
                            'assets/icons/icon_fish.svg',
                            width: 16,
                            height: 16,
                            colorFilter: ColorFilter.mode(
                              hasPhoto
                                  ? const Color(0xFFF9FAFC)
                                  : const Color(0xFF212529),
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            creature.quantity.toString().padLeft(2, '0'),
                            style: TextStyle(
                              fontFamily: 'WantedSans',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: hasPhoto
                                  ? const Color(0xFFF9FAFC)
                                  : const Color(0xFF212529),
                              height: 20 / 14,
                              letterSpacing: -0.25,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

/// 갤러리 탭 콘텐츠
  Widget _buildGalleryTab() {
    return Column(
      children: [
        // 생물 필터 칩
        _buildCreatureFilterChips(),
        // 구분선
        Container(
          height: 8,
          color: AppColors.borderLight,
        ),
        // 월별 헤더 + 정렬
        _buildGalleryHeader(),
        // 날짜별 사진 그리드
        Expanded(
          child: _filteredPhotos.isEmpty
              ? _buildEmptyState('갤러리')
              : _buildPhotoGrid(),
        ),
      ],
    );
  }

  /// 필터된 사진 목록
  List<GalleryPhotoData> get _filteredPhotos {
    var photos = _galleryPhotos.where((photo) {
      if (_selectedCreatureFilter == null) return true;
      return photo.creatureId == _selectedCreatureFilter;
    }).toList();

    // 정렬
    photos.sort((a, b) => _sortNewest
        ? b.photoDate.compareTo(a.photoDate)
        : a.photoDate.compareTo(b.photoDate));

    return photos;
  }

  /// 생물 필터 칩 목록
  Widget _buildCreatureFilterChips() {
    // 생물 이름 목록 추출
    final creatureNames = _creatures
        .where((c) => c.id != null)
        .map((c) => {'id': c.id!, 'name': c.displayName})
        .toList();

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16),
        children: [
          // 전체 필터
          _buildFilterChip(null, '전체'),
          const SizedBox(width: 8),
          // 생물별 필터
          ...creatureNames.map((creature) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildFilterChip(creature['id'], creature['name']!),
              )),
        ],
      ),
    );
  }

  /// 개별 필터 칩
  Widget _buildFilterChip(String? creatureId, String label) {
    final isSelected = _selectedCreatureFilter == creatureId;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCreatureFilter = creatureId;
        });
      },
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.blue50 : Colors.white,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
            color: isSelected ? AppColors.brand : AppColors.borderLight,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'WantedSans',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? AppColors.brand : const Color(0xFF666E78),
            height: 20 / 14,
            letterSpacing: -0.25,
          ),
        ),
      ),
    );
  }

  /// 갤러리 헤더 (년월 + 정렬)
  Widget _buildGalleryHeader() {
    final photos = _filteredPhotos;
    if (photos.isEmpty) return const SizedBox.shrink();

    // 가장 최근 사진의 년월
    final latestDate = photos.first.photoDate;
    final yearMonth = '${latestDate.year}. ${latestDate.month.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            yearMonth,
            style: const TextStyle(
              fontFamily: 'WantedSans',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212529),
              height: 26 / 18,
              letterSpacing: -0.5,
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _sortNewest = !_sortNewest;
              });
            },
            child: Row(
              children: [
                Text(
                  _sortNewest ? '최신순' : '오래된순',
                  style: const TextStyle(
                    fontFamily: 'WantedSans',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF212529),
                    height: 20 / 14,
                    letterSpacing: -0.25,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: Color(0xFF212529),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 날짜별 그룹화된 사진 그리드
  Widget _buildPhotoGrid() {
    final photos = _filteredPhotos;

    // 날짜별로 그룹화
    final Map<String, List<GalleryPhotoData>> groupedPhotos = {};
    for (final photo in photos) {
      final dateKey = '${photo.photoDate.year}-${photo.photoDate.month}-${photo.photoDate.day}';
      groupedPhotos.putIfAbsent(dateKey, () => []).add(photo);
    }

    final sortedKeys = groupedPhotos.keys.toList()
      ..sort((a, b) => _sortNewest ? b.compareTo(a) : a.compareTo(b));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final dateKey = sortedKeys[index];
        final dayPhotos = groupedPhotos[dateKey]!;
        final date = dayPhotos.first.photoDate;

        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 날짜 헤더
              _buildDateHeader(date),
              const SizedBox(height: 8),
              // 3열 그리드
              _buildPhotoGridForDay(dayPhotos),
            ],
          ),
        );
      },
    );
  }

  /// 날짜 헤더 (예: "16 (월)")
  Widget _buildDateHeader(DateTime date) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[date.weekday - 1];

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '${date.day}',
            style: const TextStyle(
              fontFamily: 'WantedSans',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF212529),
              height: 24 / 16,
              letterSpacing: -0.5,
            ),
          ),
          TextSpan(
            text: ' ($weekday)',
            style: const TextStyle(
              fontFamily: 'WantedSans',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF666E78),
              height: 20 / 14,
              letterSpacing: -0.25,
            ),
          ),
        ],
      ),
    );
  }

  /// 날짜별 사진 그리드 (3열)
  Widget _buildPhotoGridForDay(List<GalleryPhotoData> photos) {
    final rows = <Widget>[];
    for (var i = 0; i < photos.length; i += 3) {
      final rowPhotos = photos.skip(i).take(3).toList();
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: i + 3 < photos.length ? 8 : 0),
          child: Row(
            children: [
              for (var j = 0; j < 3; j++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: j > 0 ? 8 : 0,
                    ),
                    child: j < rowPhotos.length
                        ? _buildPhotoThumbnail(rowPhotos[j])
                        : const SizedBox.shrink(),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  /// 사진 썸네일
  Widget _buildPhotoThumbnail(GalleryPhotoData photo) {
    final imageUrl = photo.imageUrl;

    return GestureDetector(
      onTap: () {
        // TODO: 사진 상세 보기
      },
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFD9D9D9),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: imageUrl != null
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFFD9D9D9),
                    child: const Icon(Icons.image, color: Colors.white54),
                  ),
                )
              : Container(
                  color: const Color(0xFFD9D9D9),
                  child: const Icon(Icons.image, color: Colors.white54),
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String tabName) {
    String title;
    String description;

    switch (tabName) {
      case '생물':
        title = '아직 등록된 생물이 없어요';
        description = '내 어항 속 생물을 등록해 손쉽게 관리해 보세요.';
        break;
      case '알림':
        title = '아직 등록된 알림이 없어요';
        description = '일정 알림을 등록해 관리 시기를 놓치지 마세요.';
        break;
      case '갤러리':
        title = '아직 등록된 사진이 없어요';
        description = '어항 사진을 기록해 성장 과정을 남겨보세요.';
        break;
      default:
        title = '';
        description = '';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'WantedSans',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212529),
              height: 26 / 18,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            description,
            style: const TextStyle(
              fontFamily: 'WantedSans',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF666E78),
              height: 24 / 16,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 하단 버튼 (사진 있는 경우 - Positioned)
  Widget _buildBottomButton() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        decoration: BoxDecoration(
          color: AppColors.backgroundApp,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _onAddButtonPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brand,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: AnimatedBuilder(
                animation: _tabController,
                builder: (context, child) {
                  String text;
                  switch (_tabController.index) {
                    case 0:
                      text = '생물 추가하기';
                      break;
                    case 1:
                      text = '알림 추가하기';
                      break;
                    case 2:
                      text = '사진 추가하기';
                      break;
                    default:
                      text = '추가하기';
                  }
                  return Text(
                    text,
                    style: const TextStyle(
                      fontFamily: 'WantedSans',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 24 / 16,
                      letterSpacing: -0.5,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 하단 버튼 (사진 없는 경우 - 인라인)
  Widget _buildBottomButtonInline() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundApp,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _onAddButtonPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brand,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: AnimatedBuilder(
              animation: _tabController,
              builder: (context, child) {
                String text;
                switch (_tabController.index) {
                  case 0:
                    text = '생물 추가하기';
                    break;
                  case 1:
                    text = '알림 추가하기';
                    break;
                  case 2:
                    text = '사진 추가하기';
                    break;
                  default:
                    text = '추가하기';
                }
                return Text(
                  text,
                  style: const TextStyle(
                    fontFamily: 'WantedSans',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 24 / 16,
                    letterSpacing: -0.5,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
