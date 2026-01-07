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

  static const double _imageSize = 94.0;
  static const double _imageOverlap = 47.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 212,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              margin: const EdgeInsets.only(top: _imageOverlap),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundSurface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 12,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: _imageSize,
                        height: _imageSize - _imageOverlap,
                      ),
                      _buildFishCount(),
                    ],
                  ),
                  const SizedBox(height: 34),
                  _buildContent(),
                ],
              ),
            ),
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
    return SizedBox(
      width: 125,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  data.name,
                  style: AppTextStyles.bodyMediumMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    height: 1.5,
                    letterSpacing: -0.5,
                    color: const Color(0xFF212529),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusTag(),
            ],
          ),
          const SizedBox(height: 8),
          _buildStats(),
        ],
      ),
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
    final statsStyle = AppTextStyles.bodySmall.copyWith(
      color: AppColors.textSubtle,
      letterSpacing: -0.25,
    );

    return Row(
      children: [
        if (data.temperature != null) ...[
          Text('수온 ', style: statsStyle),
          Text('${data.temperature!.toStringAsFixed(0)}°', style: statsStyle),
        ],
        if (data.temperature != null && data.ph != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              width: 1,
              height: 12,
              color: AppColors.borderLight,
            ),
          ),
        if (data.ph != null) ...[
          Text('pH ', style: statsStyle),
          Text(data.ph!.toStringAsFixed(1), style: statsStyle),
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
      height: 280,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 50, 20, 8),
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
