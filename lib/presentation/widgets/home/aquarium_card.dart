import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';
import 'package:cmore_design_system/theme/app_spacing.dart';

enum AquariumStatus {
  healthy('양호', AppColors.chipSuccessBg, Color(0xFF00B356)),
  treatment('치료중', AppColors.orange50, AppColors.orange500),
  caution('주의', AppColors.chipErrorBg, AppColors.error);

  const AquariumStatus(this.label, this.bgColor, this.textColor);
  final String label;
  final Color bgColor;
  final Color textColor;
}

class AquariumData {
  final String id;
  final String name;
  final String? imageUrl;
  final AquariumStatus status;
  final double? temperature;
  final double? ph;
  final int fishCount;

  const AquariumData({
    required this.id,
    required this.name,
    this.imageUrl,
    this.status = AquariumStatus.healthy,
    this.temperature,
    this.ph,
    this.fishCount = 0,
  });
}

/// Aquarium Card Widget - Figma design 10:681
class AquariumCard extends StatelessWidget {
  const AquariumCard({super.key, required this.data, this.onTap});

  final AquariumData data;
  final VoidCallback? onTap;

  static const double _cardWidth = 212.0;
  static const double _imageSize = 94.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: _cardWidth,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Card Body
            Container(
              margin: const EdgeInsets.only(top: AppSpacing.xxxl),
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.backgroundSurface,
                borderRadius: AppRadius.lgBorderRadius,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Fish count (top right)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [_buildFishCount()],
                  ),

                  // Space for overlapping image
                  const SizedBox(height: 34),

                  // Name + Status + Stats
                  _buildContent(),
                ],
              ),
            ),

            // Overlapping circular image
            Positioned(top: 0, left: 16, child: _buildImage()),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Container(
      width: _imageSize,
      height: _imageSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.backgroundApp,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: data.imageUrl != null
            ? Image.network(
                data.imageUrl!,
                fit: BoxFit.cover,
                width: _imageSize,
                height: _imageSize,
                errorBuilder: (context, error, stackTrace) =>
                    _buildPlaceholderIcon(),
              )
            : _buildPlaceholderIcon(),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      color: AppColors.blue50,
      child: Center(
        child: Image.asset(
          'assets/images/aquarium_placeholder.png',
          width: _imageSize,
          height: _imageSize,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.water, size: 40, color: AppColors.brand),
        ),
      ),
    );
  }

  Widget _buildFishCount() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          'assets/icons/icon_fish.svg',
          width: 20,
          height: 20,
          colorFilter: ColorFilter.mode(AppColors.textSubtle, BlendMode.srcIn),
        ),
        const SizedBox(width: 4),
        Text(
          data.fishCount.toString().padLeft(2, '0'),
          style: AppTextStyles.captionMedium.copyWith(
            color: AppColors.textSubtle,
            fontSize: 12,
            height: 18 / 12,
            letterSpacing: -0.25,
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name + Status Tag Row
        Row(
          children: [
            Text(
              data.name,
              style: AppTextStyles.bodyMediumBold.copyWith(
                color: AppColors.textMain,
                fontSize: 16,
                height: 24 / 16,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 8),
            _buildStatusTag(),
          ],
        ),
        const SizedBox(height: 8),

        // Stats Row
        _buildStats(),
      ],
    );
  }

  Widget _buildStatusTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: data.status.bgColor,
        borderRadius: AppRadius.xsBorderRadius,
      ),
      child: Text(
        data.status.label,
        style: AppTextStyles.captionMedium.copyWith(
          color: data.status.textColor,
          fontSize: 12,
          height: 18 / 12,
          letterSpacing: -0.25,
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        if (data.temperature != null) ...[
          Text(
            '수온',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSubtle,
              fontSize: 14,
              height: 20 / 14,
              letterSpacing: -0.25,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${data.temperature!.toStringAsFixed(0)}˚C',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMain,
              fontSize: 14,
              height: 20 / 14,
              letterSpacing: -0.25,
            ),
          ),
        ],
        if (data.temperature != null && data.ph != null)
          const SizedBox(width: 16),
        if (data.ph != null) ...[
          Text(
            'pH',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSubtle,
              fontSize: 14,
              height: 20 / 14,
              letterSpacing: -0.25,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            data.ph!.toStringAsFixed(1),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMain,
              fontSize: 14,
              height: 20 / 14,
              letterSpacing: -0.25,
            ),
          ),
        ],
      ],
    );
  }
}

/// Horizontal scrollable list of Aquarium Cards
class AquariumCardList extends StatelessWidget {
  const AquariumCardList({
    super.key,
    required this.aquariums,
    this.onAquariumTap,
  });

  final List<AquariumData> aquariums;
  final void Function(AquariumData)? onAquariumTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        clipBehavior: Clip.none,
        itemCount: aquariums.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final aquarium = aquariums[index];
          return AquariumCard(
            data: aquarium,
            onTap: () => onAquariumTap?.call(aquarium),
          );
        },
      ),
    );
  }
}
