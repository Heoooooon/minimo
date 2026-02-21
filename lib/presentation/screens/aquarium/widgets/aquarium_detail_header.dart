import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io';
import '../../../../domain/models/aquarium_data.dart';
import '../../../../domain/models/creature_data.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';
import 'package:cmore_design_system/theme/app_spacing.dart';

/// 어항 상세 헤더 이미지
class AquariumHeaderImage extends StatelessWidget {
  final AquariumData aquarium;
  final double height;

  const AquariumHeaderImage({
    super.key,
    required this.aquarium,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -4,
      left: -12,
      right: -12,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.brand.withValues(alpha: 0.3),
          image: aquarium.photoUrl != null
              ? DecorationImage(
                  image: NetworkImage(aquarium.photoUrl!),
                  fit: BoxFit.cover,
                )
              : aquarium.photoPath != null
              ? DecorationImage(
                  image: FileImage(File(aquarium.photoPath!)),
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
}

/// 어항 상세 AppBar
class AquariumDetailAppBar extends StatelessWidget {
  final bool isOverImage;
  final String? aquariumName;
  final VoidCallback onBack;
  final VoidCallback onAdd;

  const AquariumDetailAppBar({
    super.key,
    required this.isOverImage,
    required this.aquariumName,
    required this.onBack,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isOverImage ? Colors.white : AppColors.textMain;
    final textColor = isOverImage ? Colors.white : AppColors.textMain;
    final title = isOverImage ? '어항' : (aquariumName ?? '어항');

    return SafeArea(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(Icons.arrow_back_ios, color: iconColor, size: 24),
          ),
          Text(
            title,
            style: AppTextStyles.headlineSmall.copyWith(color: textColor),
          ),
          IconButton(
            onPressed: onAdd,
            icon: Icon(Icons.add, color: iconColor, size: 24),
          ),
        ],
      ),
    );
  }
}

/// 어항 정보 섹션 (이름, 태그, 생물 수, D+일수)
class AquariumInfoSection extends StatelessWidget {
  final AquariumData aquarium;
  final List<CreatureData> creatures;

  const AquariumInfoSection({
    super.key,
    required this.aquarium,
    required this.creatures,
  });

  int _calculateDays(DateTime? date) {
    if (date == null) return 0;
    return DateTime.now().difference(date).inDays;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isTreatment = aquarium.purpose == AquariumPurpose.fry;
    final daysCount = _calculateDays(aquarium.settingDate);
    final totalCreatureCount = creatures.fold<int>(
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
                    aquarium.name ?? '이름 없음',
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
                    _formatDate(aquarium.settingDate),
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
    } else if (aquarium.type == AquariumType.freshwater) {
      label = '담수항';
      bgColor = AppColors.blue50;
      textColor = AppColors.brand;
    } else if (aquarium.type == AquariumType.saltwater) {
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
}
