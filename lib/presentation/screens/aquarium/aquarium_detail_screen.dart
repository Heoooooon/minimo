import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/utils/app_logger.dart';
import '../../../domain/models/aquarium_data.dart';
import '../../../domain/models/creature_data.dart';
import '../../../domain/models/gallery_photo_data.dart';
import '../../../domain/models/schedule_data.dart';
import '../../../data/services/creature_service.dart';
import '../../../data/services/gallery_photo_service.dart';
import '../../../data/services/aquarium_service.dart';
import '../../../data/services/schedule_service.dart';
import '../../../data/services/notification_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_spacing.dart';
import 'tabs/aquarium_creatures_tab.dart';
import 'tabs/aquarium_schedules_tab.dart';
import 'tabs/aquarium_gallery_tab.dart';

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
  List<ScheduleData> _schedules = [];
  String? _selectedCreatureFilter; // null이면 전체
  bool _sortNewest = true; // true: 최신순, false: 오래된순

  // 탭별 독립 로딩 상태
  bool _isLoadingCreatures = true;
  bool _isLoadingSchedules = true;
  bool _isLoadingPhotos = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  /// 데이터 로딩 - 병렬 실행
  void _loadData() {
    if (_aquarium?.id == null) return;

    // 모든 로딩 상태 초기화
    setState(() {
      _isLoadingCreatures = true;
      _isLoadingSchedules = true;
      _isLoadingPhotos = true;
    });

    // 병렬로 데이터 로딩 시작
    _loadCreatures();
    _loadSchedules();
    _loadPhotos();
  }

  /// 생물 데이터 로딩
  Future<void> _loadCreatures() async {
    try {
      final creatures = await CreatureService.instance.getCreaturesByAquarium(
        _aquarium!.id!,
      );
      if (mounted) {
        setState(() {
          _creatures = creatures;
          _isLoadingCreatures = false;
        });
      }
    } catch (e) {
      AppLogger.data('Failed to load creatures: $e', isError: true);
      if (mounted) {
        setState(() => _isLoadingCreatures = false);
      }
    }
  }

  /// 알림 데이터 로딩
  Future<void> _loadSchedules() async {
    try {
      final schedules = await ScheduleService.instance.getSchedulesByAquarium(
        _aquarium!.id!,
      );
      if (mounted) {
        setState(() {
          _schedules = schedules;
          _isLoadingSchedules = false;
        });
      }
    } catch (e) {
      AppLogger.data('Failed to load schedules: $e', isError: true);
      if (mounted) {
        setState(() => _isLoadingSchedules = false);
      }
    }
  }

  /// 갤러리 사진 로딩
  Future<void> _loadPhotos() async {
    try {
      final photos = await GalleryPhotoService.instance.getPhotosByAquarium(
        _aquarium!.id!,
        newestFirst: _sortNewest,
      );
      if (mounted) {
        setState(() {
          _galleryPhotos = photos;
          _isLoadingPhotos = false;
        });
      }
    } catch (e) {
      AppLogger.data('Failed to load photos: $e', isError: true);
      if (mounted) {
        setState(() => _isLoadingPhotos = false);
      }
    }
  }

  /// 사진 추가 BottomSheet 표시
  void _showPhotoAddSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 핸들 바
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 타이틀
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: Text(
                  '사진 추가',
                  style: AppTextStyles.headlineSmall,
                ),
              ),
              // 카메라 촬영 옵션
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.chipPrimaryBg,
                    borderRadius: AppRadius.mdBorderRadius,
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: AppColors.brand,
                  ),
                ),
                title: Text(
                  '카메라로 촬영',
                  style: AppTextStyles.titleMedium,
                ),
                subtitle: Text(
                  '새 사진을 촬영합니다',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSubtle,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _takePhotoAndUpload();
                },
              ),
              // 갤러리 선택 옵션
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.chipPrimaryBg,
                    borderRadius: AppRadius.mdBorderRadius,
                  ),
                  child: const Icon(
                    Icons.photo_library_outlined,
                    color: AppColors.brand,
                  ),
                ),
                title: Text(
                  '갤러리에서 선택',
                  style: AppTextStyles.titleMedium,
                ),
                subtitle: Text(
                  '저장된 사진을 선택합니다',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSubtle,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickPhotosFromGallery();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 카메라로 사진 촬영 후 업로드
  Future<void> _takePhotoAndUpload() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null && _aquarium?.id != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('사진을 업로드하는 중...'),
              duration: Duration(seconds: 1),
            ),
          );
        }

        await GalleryPhotoService.instance.uploadPhotos(_aquarium!.id!, [
          image.path,
        ]);

        if (mounted) {
          _loadPhotos();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('사진이 추가되었습니다'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.data('Failed to take and upload photo: $e', isError: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('사진 업로드에 실패했습니다: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// 갤러리에서 사진 선택 후 업로드
  Future<void> _pickPhotosFromGallery() async {
    try {
      final picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isNotEmpty && _aquarium?.id != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${images.length}개의 사진을 업로드하는 중...'),
              duration: const Duration(seconds: 1),
            ),
          );
        }

        final filePaths = images.map((img) => img.path).toList();
        await GalleryPhotoService.instance.uploadPhotos(
          _aquarium!.id!,
          filePaths,
        );

        if (mounted) {
          _loadPhotos();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${images.length}개의 사진이 추가되었습니다'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.data('Failed to pick and upload photos: $e', isError: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('사진 업로드에 실패했습니다: $e'),
            backgroundColor: AppColors.error,
          ),
        );
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
    } else if (args is String && _aquarium?.id != args) {
      _loadAquariumById(args);
    }
  }

  Future<void> _loadAquariumById(String id) async {
    try {
      final aquarium = await AquariumService.instance.getAquarium(id);
      if (aquarium != null && mounted) {
        setState(() {
          _aquarium = aquarium;
        });
        _loadData();
      }
    } catch (e) {
      AppLogger.data('Failed to load aquarium by id: $e', isError: true);
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
        Navigator.pushNamed(
          context,
          '/creature/search',
          arguments: _aquarium,
        ).then((_) {
          if (mounted) _loadData();
        });
        break;
      case 1:
        Navigator.pushNamed(
          context,
          '/schedule/add',
          arguments: _aquarium,
        ).then((_) {
          if (mounted) _loadData();
        });
        break;
      case 2:
        _showPhotoAddSheet();
        break;
    }
  }

  /// 알림 토글 변경
  Future<void> _toggleScheduleNotification(
    ScheduleData schedule,
    bool enabled,
  ) async {
    try {
      setState(() {
        final index = _schedules.indexWhere((s) => s.id == schedule.id);
        if (index != -1) {
          _schedules[index] = schedule.copyWith(isNotificationEnabled: enabled);
        }
      });

      await ScheduleService.instance.updateSchedule(
        schedule.id,
        schedule.copyWith(isNotificationEnabled: enabled),
      );

      if (enabled) {
        await NotificationService.instance.scheduleNotification(
          id: NotificationService.instance.scheduleIdToNotificationId(
            schedule.id,
          ),
          title: schedule.title,
          body: '${_aquarium?.name ?? '어항'} - ${schedule.alarmType.label}',
          scheduledTime: schedule.date,
          repeatCycle: schedule.repeatCycle,
          payload: 'schedule:${schedule.id}:aquarium:${_aquarium?.id ?? ''}',
        );
      } else {
        await NotificationService.instance.cancelNotification(
          NotificationService.instance.scheduleIdToNotificationId(schedule.id),
        );
      }
    } catch (e) {
      AppLogger.data('Failed to toggle notification: $e', isError: true);
      if (mounted) {
        setState(() {
          final index = _schedules.indexWhere((s) => s.id == schedule.id);
          if (index != -1) {
            _schedules[index] = schedule.copyWith(
              isNotificationEnabled: !enabled,
            );
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('알림 설정 변경에 실패했습니다: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// 알림 옵션 표시 (롱프레스)
  void _showScheduleOptions(ScheduleData schedule) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('알림 삭제', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteSchedule(schedule);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 알림 삭제 확인 (Dismissible용)
  Future<bool?> _showDeleteConfirmDialog(ScheduleData schedule) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('알림 삭제'),
        content: Text('"${schedule.title}" 알림을 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  /// 알림 삭제 확인
  void _confirmDeleteSchedule(ScheduleData schedule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('알림 삭제'),
        content: Text('"${schedule.title}" 알림을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSchedule(schedule);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  /// 알림 삭제 실행
  Future<void> _deleteSchedule(ScheduleData schedule) async {
    try {
      await ScheduleService.instance.deleteSchedule(schedule.id);

      if (schedule.isNotificationEnabled) {
        final notificationId = NotificationService.instance
            .scheduleIdToNotificationId(schedule.id);
        await NotificationService.instance.cancelNotification(notificationId);
      }

      if (mounted) {
        setState(() {
          _schedules.removeWhere((s) => s.id == schedule.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('알림이 삭제되었습니다'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      AppLogger.data('Failed to delete schedule: $e', isError: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('알림 삭제에 실패했습니다: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_aquarium == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.backgroundApp,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.chevron_left, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.textHint),
              const SizedBox(height: AppSpacing.lg),
              const Text('어항 정보를 불러올 수 없습니다.'),
              const SizedBox(height: AppSpacing.lg),
              TextButton(
                onPressed: () {
                  final args = ModalRoute.of(context)?.settings.arguments;
                  if (args is String) {
                    _loadAquariumById(args);
                  }
                },
                child: Text(
                  '다시 시도',
                  style: AppTextStyles.bodyMediumMedium.copyWith(
                    color: AppColors.brand,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

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
    final screenWidth = MediaQuery.of(context).size.width;

    const baseWidth = 375.0;
    const baseHeaderHeight = 299.0;
    const baseCardTop = 215.0;

    final scale = screenWidth / baseWidth;
    final headerHeight = baseHeaderHeight * scale;
    final cardTop = baseCardTop * scale;

    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      body: Stack(
        children: [
          _buildHeaderImage(headerHeight),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildAppBar(isOverImage: true),
          ),
          Positioned(
            top: cardTop,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.backgroundApp,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppSpacing.xxl),
                  topRight: Radius.circular(AppSpacing.xxl),
                ),
              ),
              child: Column(
                children: [
                  _buildInfoSection(isTreatment, daysCount),
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: _buildTabChildren(),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
          _buildAppBar(isOverImage: false),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _buildTabChildren(),
            ),
          ),
          _buildBottomButtonInline(),
        ],
      ),
    );
  }

  /// 3개 탭 위젯 리스트 생성
  List<Widget> _buildTabChildren() {
    return [
      AquariumCreaturesTab(
        creatures: _creatures,
        isLoading: _isLoadingCreatures,
        onAddPressed: _onAddButtonPressed,
        onCreatureTap: (creature) {
          Navigator.pushNamed(context, '/creature/detail', arguments: creature);
        },
      ),
      AquariumSchedulesTab(
        schedules: _schedules,
        isLoading: _isLoadingSchedules,
        onToggleNotification: _toggleScheduleNotification,
        onDeleteSchedule: _deleteSchedule,
        onShowOptions: _showScheduleOptions,
        onShowDeleteConfirm: _showDeleteConfirmDialog,
      ),
      AquariumGalleryTab(
        galleryPhotos: _galleryPhotos,
        creatures: _creatures,
        isLoading: _isLoadingPhotos,
        sortNewest: _sortNewest,
        selectedCreatureFilter: _selectedCreatureFilter,
        onSortToggle: () {
          setState(() {
            _sortNewest = !_sortNewest;
          });
        },
        onCreatureFilterChanged: (creatureId) {
          setState(() {
            _selectedCreatureFilter = creatureId;
          });
        },
        onPhotoTap: (photo) {
          Navigator.pushNamed(
            context,
            '/gallery/photo-detail',
            arguments: photo,
          ).then((deleted) {
            if (deleted == true && mounted) {
              _loadPhotos();
            }
          });
        },
      ),
    ];
  }

  Widget _buildHeaderImage(double height) {
    return Positioned(
      top: -4,
      left: -12,
      right: -12,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.brand.withValues(alpha: 0.3),
          image: _aquarium?.photoUrl != null
              ? DecorationImage(
                  image: NetworkImage(_aquarium!.photoUrl!),
                  fit: BoxFit.cover,
                )
              : _aquarium?.photoPath != null
              ? DecorationImage(
                  image: FileImage(File(_aquarium!.photoPath!)),
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
                const Color(0xFF87B1FF).withValues(alpha: 0),
                const Color(0xFFA9C7FF).withValues(alpha: 0.3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar({required bool isOverImage}) {
    final iconColor = isOverImage ? Colors.white : AppColors.textMain;
    final textColor = isOverImage ? Colors.white : AppColors.textMain;
    final title = isOverImage ? '어항' : (_aquarium?.name ?? '어항');

    return SafeArea(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios, color: iconColor, size: 24),
          ),
          Text(
            title,
            style: AppTextStyles.headlineSmall.copyWith(color: textColor),
          ),
          IconButton(
            onPressed: _onAddButtonPressed,
            icon: Icon(Icons.add, color: iconColor, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(bool isTreatment, int daysCount) {
    final totalCreatureCount = _creatures.fold<int>(
      0,
      (sum, creature) => sum + creature.quantity,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xxl, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _aquarium?.name ?? '이름 없음',
                    style: const TextStyle(
                      fontFamily: 'WantedSans',
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMain,
                      height: 32 / 22,
                      letterSpacing: -0.25,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _buildTag(isTreatment),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  SvgPicture.asset(
                    'assets/icons/icon_fish.svg',
                    width: 16,
                    height: 16,
                    colorFilter: const ColorFilter.mode(
                      AppColors.textSubtle,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '$totalCreatureCount',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSubtle,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'D+$daysCount',
                style: AppTextStyles.titleLarge.copyWith(
                  color: isTreatment ? AppColors.orange700 : AppColors.brand,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  SvgPicture.asset(
                    'assets/icons/icon_calendar.svg',
                    width: 16,
                    height: 16,
                    colorFilter: const ColorFilter.mode(
                      AppColors.textSubtle,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    _formatDate(_aquarium?.settingDate),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSubtle,
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.xsBorderRadius,
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMedium.copyWith(color: textColor),
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      labelColor: AppColors.brand,
      unselectedLabelColor: AppColors.textSubtle,
      labelStyle: AppTextStyles.titleMedium,
      unselectedLabelStyle: AppTextStyles.titleMedium,
      indicator: const UnderlineTabIndicator(
        borderSide: BorderSide(color: AppColors.brand, width: 1.5),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: AppColors.borderLight,
      tabs: const [
        Tab(text: '생물'),
        Tab(text: '알림'),
        Tab(text: '갤러리'),
      ],
    );
  }

  /// 하단 버튼 (사진 있는 경우 - Positioned)
  Widget _buildBottomButton() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xxl, AppSpacing.lg, AppSpacing.sm,
        ),
        color: AppColors.backgroundApp,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 56,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _onAddButtonPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brand,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxxl,
                  vertical: 3,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.smBorderRadius,
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
                  return Text(text, style: AppTextStyles.bodyMediumMedium);
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
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.xxl, AppSpacing.lg, AppSpacing.sm,
      ),
      color: AppColors.backgroundApp,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _onAddButtonPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brand,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxxl,
                vertical: 3,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.smBorderRadius,
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
                return Text(text, style: AppTextStyles.bodyMediumMedium);
              },
            ),
          ),
        ),
      ),
    );
  }
}
