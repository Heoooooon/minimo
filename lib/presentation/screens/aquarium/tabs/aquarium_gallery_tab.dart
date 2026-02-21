import 'package:flutter/material.dart';
import '../../../../domain/models/creature_data.dart';
import '../../../../domain/models/gallery_photo_data.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';
import 'package:cmore_design_system/theme/app_spacing.dart';
import 'package:cmore_design_system/widgets/skeleton_loader.dart';

/// 어항 상세 - 갤러리 탭
class AquariumGalleryTab extends StatelessWidget {
  const AquariumGalleryTab({
    super.key,
    required this.galleryPhotos,
    required this.creatures,
    required this.isLoading,
    required this.sortNewest,
    required this.selectedCreatureFilter,
    required this.onSortToggle,
    required this.onCreatureFilterChanged,
    required this.onPhotoTap,
  });

  final List<GalleryPhotoData> galleryPhotos;
  final List<CreatureData> creatures;
  final bool isLoading;
  final bool sortNewest;
  final String? selectedCreatureFilter;
  final VoidCallback onSortToggle;
  final void Function(String? creatureId) onCreatureFilterChanged;
  final void Function(GalleryPhotoData photo) onPhotoTap;

  List<GalleryPhotoData> get _filteredPhotos {
    var photos = galleryPhotos.where((photo) {
      if (selectedCreatureFilter == null) return true;
      return photo.creatureId == selectedCreatureFilter;
    }).toList();

    photos.sort(
      (a, b) => sortNewest
          ? b.photoDate.compareTo(a.photoDate)
          : a.photoDate.compareTo(b.photoDate),
    );

    return photos;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const GalleryGridSkeleton();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Column(
        key: const ValueKey('gallery_content'),
        children: [
          _buildCreatureFilterChips(),
          Container(height: 1, color: AppColors.borderLight),
          _buildGalleryHeader(),
          Expanded(
            child: _filteredPhotos.isEmpty
                ? _buildEmptyState()
                : _buildPhotoGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatureFilterChips() {
    final creatureNames = creatures
        .where((c) => c.id != null)
        .map((c) => {'id': c.id!, 'name': c.displayName})
        .toList();

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: AppSpacing.lg),
        children: [
          _buildFilterChip(null, '전체'),
          const SizedBox(width: AppSpacing.sm),
          ...creatureNames.map(
            (creature) => Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: _buildFilterChip(creature['id'], creature['name']!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String? creatureId, String label) {
    final isSelected = selectedCreatureFilter == creatureId;

    return GestureDetector(
      onTap: () => onCreatureFilterChanged(creatureId),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brand : AppColors.backgroundSurface,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
            color: isSelected ? AppColors.brand : AppColors.borderLight,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.titleSmall.copyWith(
            color: isSelected ? Colors.white : AppColors.textSubtle,
          ),
        ),
      ),
    );
  }

  Widget _buildGalleryHeader() {
    final photos = _filteredPhotos;
    if (photos.isEmpty) return const SizedBox.shrink();

    final latestDate = photos.first.photoDate;
    final yearMonth =
        '${latestDate.year}. ${latestDate.month.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            yearMonth,
            style: AppTextStyles.headlineSmall,
          ),
          GestureDetector(
            onTap: onSortToggle,
            child: Row(
              children: [
                Text(
                  sortNewest ? '최신순' : '오래된순',
                  style: AppTextStyles.titleSmall,
                ),
                const SizedBox(width: AppSpacing.xs),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: AppColors.textMain,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid() {
    final photos = _filteredPhotos;

    final Map<String, List<GalleryPhotoData>> groupedPhotos = {};
    for (final photo in photos) {
      final dateKey =
          '${photo.photoDate.year}-${photo.photoDate.month}-${photo.photoDate.day}';
      groupedPhotos.putIfAbsent(dateKey, () => []).add(photo);
    }

    final sortedKeys = groupedPhotos.keys.toList()
      ..sort((a, b) => sortNewest ? b.compareTo(a) : a.compareTo(b));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 100),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final dateKey = sortedKeys[index];
        final dayPhotos = groupedPhotos[dateKey]!;
        final date = dayPhotos.first.photoDate;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateHeader(date),
              const SizedBox(height: AppSpacing.sm),
              _buildPhotoGridForDay(dayPhotos),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateHeader(DateTime date) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[date.weekday - 1];

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '${date.day}',
            style: AppTextStyles.titleMedium,
          ),
          TextSpan(
            text: ' ($weekday)',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSubtle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGridForDay(List<GalleryPhotoData> photos) {
    final rows = <Widget>[];
    for (var i = 0; i < photos.length; i += 3) {
      final rowPhotos = photos.skip(i).take(3).toList();
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: i + 3 < photos.length ? 3 : 0),
          child: Row(
            children: [
              for (var j = 0; j < 3; j++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: j > 0 ? 3 : 0),
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

  Widget _buildPhotoThumbnail(GalleryPhotoData photo) {
    final imageUrl = photo.imageUrl;

    return GestureDetector(
      onTap: () => onPhotoTap(photo),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFD9D9D9),
            borderRadius: AppRadius.smBorderRadius,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '아직 등록된 사진이 없어요',
            style: AppTextStyles.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            '어항 사진을 기록해 성장 과정을 남겨보세요.',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textSubtle,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
