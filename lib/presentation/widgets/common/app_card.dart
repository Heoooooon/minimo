import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';

/// 통일된 카드 위젯
///
/// 앱 전체에서 일관된 카드 스타일을 제공
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding,
    this.margin,
    this.borderRadius,
    this.color,
    this.shadow,
    this.border,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? color;
  final List<BoxShadow>? shadow;
  final Border? border;

  @override
  Widget build(BuildContext context) {
    final cardRadius = borderRadius ?? AppRadius.mdBorderRadius;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? AppColors.backgroundSurface,
        borderRadius: cardRadius,
        boxShadow: shadow ?? AppShadow.card,
        border: border,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: cardRadius,
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
            child: child,
          ),
        ),
      ),
    );
  }
}
