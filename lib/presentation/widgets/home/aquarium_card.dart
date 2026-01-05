import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// 어항 상태 열거형
enum AquariumStatus {
  healthy('양호', AppColors.chipSuccessBg, AppColors.chipSuccessText),
  treatment('치료중', AppColors.chipSecondaryBg, AppColors.chipSecondaryText),
  caution('주의', AppColors.chipErrorBg, AppColors.chipErrorText);

  const AquariumStatus(this.label, this.bgColor, this.textColor);
  final String label;
  final Color bgColor;
  final Color textColor;
}

/// 어항 데이터 모델
class AquariumData {
  final String id;
  final String name;
  final String? imageUrl;
  final AquariumStatus status;
  final double? temperature;
  final double? ph;

  const AquariumData({
    required this.id,
    required this.name,
    this.imageUrl,
    this.status = AquariumStatus.healthy,
    this.temperature,
    this.ph,
  });
}

/// 어항 카드 위젯
///
/// 나의 어항 섹션에서 가로 스크롤로 표시되는 카드
class AquariumCard extends StatelessWidget {
  const AquariumCard({super.key, required this.data, this.onTap});

  final AquariumData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 원형 이미지
            _buildImage(),
            const SizedBox(height: 12),

            // 어항 이름
            Text(
              data.name,
              style: AppTextStyles.bodyMediumMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),

            // 상태 태그
            _buildStatusTag(),
            const SizedBox(height: 10),

            // 수온/pH 정보
            _buildStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.chipPrimaryBg,
        border: Border.all(
          color: AppColors.brand.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: data.imageUrl != null
          ? ClipOval(
              child: Image.network(
                data.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholderIcon(),
              ),
            )
          : _buildPlaceholderIcon(),
    );
  }

  Widget _buildPlaceholderIcon() {
    return const Icon(Icons.water, size: 32, color: AppColors.brand);
  }

  Widget _buildStatusTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: data.status.bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        data.status.label,
        style: AppTextStyles.labelSmall.copyWith(
          color: data.status.textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (data.temperature != null) ...[
          _buildStatItem(
            icon: Icons.thermostat_outlined,
            value: '${data.temperature!.toStringAsFixed(0)}°',
          ),
          if (data.ph != null) const SizedBox(width: 12),
        ],
        if (data.ph != null)
          _buildStatItem(
            icon: Icons.science_outlined,
            value: 'pH ${data.ph!.toStringAsFixed(1)}',
          ),
      ],
    );
  }

  Widget _buildStatItem({required IconData icon, required String value}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textSubtle),
        const SizedBox(width: 2),
        Text(
          value,
          style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSubtle),
        ),
      ],
    );
  }
}

/// 어항 카드 리스트 (가로 스크롤)
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
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
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
