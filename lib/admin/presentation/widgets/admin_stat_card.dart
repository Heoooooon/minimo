import 'package:flutter/material.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_spacing.dart';

/// 관리자 대시보드 통계 카드
///
/// 아이콘, 라벨, 메인 수치, 부가 정보를 표시하는 카드 위젯
class AdminStatCard extends StatelessWidget {
  const AdminStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.subValue,
    this.iconColor,
    this.iconBgColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? subValue;
  final Color? iconColor;
  final Color? iconBgColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Row(
          children: [
            // 아이콘 컨테이너
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBgColor ?? AppColors.chipPrimaryBg,
                borderRadius: AppRadius.mdBorderRadius,
              ),
              child: Icon(icon, color: iconColor ?? AppColors.brand, size: 24),
            ),
            const SizedBox(width: AppSpacing.lg),
            // 텍스트 영역
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSubtle,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                  if (subValue != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subValue!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
