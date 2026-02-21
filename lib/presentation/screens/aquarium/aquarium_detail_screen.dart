import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';
import 'package:cmore_design_system/theme/app_spacing.dart';
import 'tabs/aquarium_creatures_tab.dart';
import 'tabs/aquarium_schedules_tab.dart';
import 'tabs/aquarium_gallery_tab.dart';
import 'widgets/aquarium_detail_header.dart';
import 'widgets/aquarium_detail_bottom_button.dart';
import 'widgets/aquarium_photo_add_sheet.dart';
import 'widgets/aquarium_schedule_dialogs.dart';

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

    setState(() {
      _isLoadingCreatures = true;
      _isLoadingSchedules = true;
      _isLoadingPhotos = true;
    });

    _loadCreatures();
    _loadSchedules();
    _loadPhotos();
  }

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

  void _showPhotoAddSheet() {
    AquariumPhotoAddSheet.show(
      context,
      onCameraSelected: _takePhotoAndUpload,
      onGallerySelected: _pickPhotosFromGallery,
    );
  }

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

  void _showScheduleOptions(ScheduleData schedule) {
    showScheduleOptionsSheet(
      context,
      schedule: schedule,
      onDelete: () => _confirmDeleteSchedule(schedule),
    );
  }

  Future<bool?> _showDeleteConfirmDialog(ScheduleData schedule) {
    return showScheduleDeleteConfirmDialog(context, schedule: schedule);
  }

  void _confirmDeleteSchedule(ScheduleData schedule) {
    showScheduleConfirmDeleteDialog(
      context,
      schedule: schedule,
      onDelete: () => _deleteSchedule(schedule),
    );
  }

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
      return _buildEmptyState();
    }

    if (_hasPhoto) {
      return _buildWithPhotoLayout();
    } else {
      return _buildWithoutPhotoLayout();
    }
  }

  Widget _buildEmptyState() {
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
                style: AppTextStyles.bodyMediumBold.copyWith(
                  color: AppColors.brand,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWithPhotoLayout() {
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
          AquariumHeaderImage(
            aquarium: _aquarium!,
            height: headerHeight,
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AquariumDetailAppBar(
              isOverImage: true,
              aquariumName: _aquarium?.name,
              onBack: () => Navigator.pop(context),
              onAdd: _onAddButtonPressed,
            ),
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
                  AquariumInfoSection(
                    aquarium: _aquarium!,
                    creatures: _creatures,
                  ),
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
          AquariumDetailBottomButton(
            tabController: _tabController,
            onPressed: _onAddButtonPressed,
          ),
        ],
      ),
    );
  }

  Widget _buildWithoutPhotoLayout() {
    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      body: Column(
        children: [
          AquariumDetailAppBar(
            isOverImage: false,
            aquariumName: _aquarium?.name,
            onBack: () => Navigator.pop(context),
            onAdd: _onAddButtonPressed,
          ),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _buildTabChildren(),
            ),
          ),
          AquariumDetailBottomButtonInline(
            tabController: _tabController,
            onPressed: _onAddButtonPressed,
          ),
        ],
      ),
    );
  }

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
}
