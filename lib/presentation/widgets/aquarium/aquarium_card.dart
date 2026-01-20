import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../domain/models/aquarium_data.dart';
import '../../../theme/app_colors.dart';

/// 어항 카드 위젯
///
/// Figma 디자인 기반 - 어항 목록에서 사용
class AquariumCard extends StatelessWidget {
  const AquariumCard({
    super.key,
    required this.aquarium,
    required this.onTap,
    this.onLongPress,
    this.creatureCount = 0,
  });

  final AquariumData aquarium;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final int creatureCount;

  @override
  Widget build(BuildContext context) {
    final isTreatment = aquarium.purpose == AquariumPurpose.fry;
    final daysCount = _calculateDays(aquarium.settingDate);

    return Container(
      height: 102,
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFF),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D846EFF),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Stack(
            children: [
              // 배경 이미지 또는 어항 아이콘
              if (aquarium.photoUrl != null && aquarium.photoUrl!.isNotEmpty)
                // 사진이 있는 경우 - 배경 이미지 표시
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: 180,
                  child: Opacity(
                    opacity: 0.3,
                    child: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return const LinearGradient(
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                          colors: [Colors.white, Colors.transparent],
                          stops: [0.3, 1.0],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: Image.network(
                        aquarium.photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                )
              else
                // 사진이 없는 경우 - 어항 아이콘 표시
                Positioned(
                  right: 0,
                  top: -10,
                  child: Opacity(
                    opacity: 0.3,
                    child: SvgPicture.asset(
                      'assets/icons/icon_aquarium.svg',
                      width: 124,
                      height: 124,
                      colorFilter: ColorFilter.mode(
                        isTreatment
                            ? AppColors.orange500.withValues(alpha: 0.5)
                            : AppColors.brand.withValues(alpha: 0.5),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),

              // 콘텐츠
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 왼쪽: 이름 + 태그 + 생물 수
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 이름 + 태그
                        Row(
                          children: [
                            Text(
                              aquarium.name ?? '이름 없음',
                              style: const TextStyle(
                                fontFamily: 'WantedSans',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF212529),
                                height: 26 / 18,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildTag(aquarium, isTreatment),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // 생물 수
                        Row(
                          children: [
                            SvgPicture.asset(
                              'assets/icons/icon_fish.svg',
                              width: 20,
                              height: 20,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF666E78),
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$creatureCount',
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

                    // 오른쪽: D+ 카운트 + 날짜
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // D+ 카운트
                        Text(
                          'D+$daysCount',
                          style: TextStyle(
                            fontFamily: 'WantedSans',
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: isTreatment
                                ? AppColors.orange700
                                : AppColors.brand,
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
                              _formatDate(aquarium.settingDate),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(AquariumData aquarium, bool isTreatment) {
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

  int _calculateDays(DateTime? date) {
    if (date == null) return 0;
    return DateTime.now().difference(date).inDays;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}
