import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

enum AquariumStatus {
  healthy('양호', Color(0xFFE7F9F3), Color(0xFF00B386)),
  treatment('치료중', Color(0xFFFFF2E7), Color(0xFFFF8C00)),
  caution('주의', Color(0xFFFFEAE6), Color(0xFFE72A07));

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

class AquariumCard extends StatelessWidget {
  const AquariumCard({super.key, required this.data, this.onTap});

  final AquariumData data;
  final VoidCallback? onTap;

  static const double _imageSize = 110.0;
  static const double _imageOverlap = 55.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 160,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              margin: const EdgeInsets.only(top: _imageOverlap),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              decoration: BoxDecoration(
                color: AppColors.backgroundSurface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Space for overlapping image + fish count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [_buildFishCount()],
                  ),
                  SizedBox(height: _imageSize - _imageOverlap - 8),
                  _buildContent(),
                ],
              ),
            ),
            // Centered image
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(child: _buildImage()),
            ),
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
        color: AppColors.border,
        border: Border.all(color: AppColors.borderLight, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: data.imageUrl != null
          ? ClipOval(
              child: Image.network(
                data.imageUrl!,
                fit: BoxFit.cover,
                width: _imageSize,
                height: _imageSize,
                errorBuilder: (_, __, ___) => _buildPlaceholderIcon(),
              ),
            )
          : _buildPlaceholderIcon(),
    );
  }

  Widget _buildPlaceholderIcon() {
    return const Icon(Icons.water, size: 40, color: AppColors.brand);
  }

  Widget _buildFishCount() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset('assets/icons/icon_fish.svg', width: 18, height: 10),
        const SizedBox(width: 4),
        Text(
          '${data.fishCount}',
          style: AppTextStyles.captionMedium.copyWith(
            color: AppColors.textSubtle,
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Name + Status Tag
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                data.name,
                style: AppTextStyles.bodyMediumMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  height: 1.3,
                  letterSpacing: -0.3,
                  color: const Color(0xFF212529),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            _buildStatusTag(),
          ],
        ),
        const SizedBox(height: 6),
        _buildStats(),
      ],
    );
  }

  Widget _buildStatusTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: data.status.bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        data.status.label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: data.status.textColor,
          fontSize: 12,
          fontFamily: 'Wanted Sans',
          fontWeight: FontWeight.w500,
          height: 1.5,
          letterSpacing: -0.25,
        ),
      ),
    );
  }

  Widget _buildStats() {
    final statsStyle = AppTextStyles.captionRegular.copyWith(
      color: AppColors.textSubtle,
      fontSize: 12,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (data.temperature != null) ...[
          Text(
            '수온 ${data.temperature!.toStringAsFixed(0)}°',
            style: statsStyle,
          ),
        ],
        if (data.temperature != null && data.ph != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Container(
              width: 1,
              height: 10,
              color: AppColors.borderLight,
            ),
          ),
        if (data.ph != null) ...[
          Text('pH ${data.ph!.toStringAsFixed(1)}', style: statsStyle),
        ],
      ],
    );
  }
}

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
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 56, 20, 8),
        clipBehavior: Clip.none,
        itemCount: aquariums.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
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
