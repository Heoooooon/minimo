import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io';
import '../../../../domain/models/creature_data.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../theme/app_spacing.dart';
import '../../../widgets/common/skeleton_loader.dart';

/// 어항 상세 - 생물 탭
class AquariumCreaturesTab extends StatelessWidget {
  const AquariumCreaturesTab({
    super.key,
    required this.creatures,
    required this.isLoading,
    required this.onAddPressed,
    required this.onCreatureTap,
  });

  final List<CreatureData> creatures;
  final bool isLoading;
  final VoidCallback onAddPressed;
  final void Function(CreatureData creature) onCreatureTap;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const CreatureGridSkeleton();
    }

    if (creatures.isEmpty) {
      return _buildEmptyState();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Column(
        key: const ValueKey('creature_content'),
        children: [
          _buildToolbar(),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, 100,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 13,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 165 / 150,
              ),
              itemCount: creatures.length,
              itemBuilder: (context, index) {
                return _buildCreatureCard(creatures[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildViewToggleButton(Icons.grid_view, true),
          GestureDetector(
            onTap: onAddPressed,
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.backgroundSurface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.brand, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, size: 16, color: AppColors.brand),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '생물 추가',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.brand,
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

  Widget _buildViewToggleButton(IconData icon, bool isSelected) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: 24,
        color: isSelected ? AppColors.textMain : AppColors.textHint,
      ),
    );
  }

  Widget _buildCreatureCard(CreatureData creature) {
    final hasPhoto = creature.photoUrls.isNotEmpty;

    return GestureDetector(
      onTap: () => onCreatureTap(creature),
      child: Container(
        decoration: BoxDecoration(
          color: hasPhoto ? null : AppColors.backgroundDisabled,
          borderRadius: AppRadius.smBorderRadius,
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
            if (hasPhoto)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.smBorderRadius,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.textMain.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
              ),
            Positioned(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.md,
              top: hasPhoto ? null : 50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!hasPhoto)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 28),
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/icons/icon_fish.svg',
                          width: 32,
                          height: 32,
                          colorFilter: const ColorFilter.mode(
                            AppColors.textHint,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          creature.displayName,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: hasPhoto
                                ? AppColors.backgroundApp
                                : AppColors.textMain,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            'assets/icons/icon_fish.svg',
                            width: 16,
                            height: 16,
                            colorFilter: ColorFilter.mode(
                              hasPhoto
                                  ? AppColors.backgroundApp
                                  : AppColors.textMain,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            creature.quantity.toString().padLeft(2, '0'),
                            style: AppTextStyles.titleSmall.copyWith(
                              color: hasPhoto
                                  ? AppColors.backgroundApp
                                  : AppColors.textMain,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '아직 등록된 생물이 없어요',
            style: AppTextStyles.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            '내 어항 속 생물을 등록해 손쉽게 관리해 보세요.',
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
