import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import 'app_button.dart';

/// 공용 확인 다이얼로그
///
/// 삭제/확인 등 사용자 확인이 필요한 액션에서 사용
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = '확인',
    this.cancelLabel = '취소',
    this.isDestructive = false,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;

  /// 다이얼로그를 표시하고 결과를 반환
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = '확인',
    String cancelLabel = '취소',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.backgroundSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.lgBorderRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSubtle,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: cancelLabel,
                    onPressed: () => Navigator.pop(context, false),
                    variant: AppButtonVariant.outlined,
                    size: AppButtonSize.medium,
                    shape: AppButtonShape.square,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildConfirmButton(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmButton(BuildContext context) {
    if (isDestructive) {
      return Material(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => Navigator.pop(context, true),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 40,
            alignment: Alignment.center,
            child: Text(
              confirmLabel,
              style: AppTextStyles.buttonLarge.copyWith(
                color: AppColors.textInverse,
              ),
            ),
          ),
        ),
      );
    }

    return AppButton(
      text: confirmLabel,
      onPressed: () => Navigator.pop(context, true),
      variant: AppButtonVariant.contained,
      size: AppButtonSize.medium,
      shape: AppButtonShape.square,
    );
  }
}
