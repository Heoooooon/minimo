import 'package:flutter/material.dart';
import 'package:cmore_design_system/theme/app_colors.dart';

/// 생물 등록/수정 하단 저장 버튼
class CreatureBottomButton extends StatelessWidget {
  final bool isEnabled;
  final bool isSaving;
  final VoidCallback? onSave;

  const CreatureBottomButton({
    super.key,
    required this.isEnabled,
    required this.isSaving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = isEnabled && !isSaving;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            AppColors.backgroundApp,
            AppColors.backgroundApp.withValues(alpha: 0),
          ],
          stops: const [0.36, 1.0],
        ),
      ),
      child: SafeArea(
        child: GestureDetector(
          onTap: enabled ? onSave : null,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: enabled ? AppColors.brand : AppColors.backgroundDisabled,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: isSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    '저장하기',
                    style: TextStyle(
                      fontFamily: 'WantedSans',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: enabled
                          ? AppColors.backgroundApp
                          : AppColors.disabledText,
                      height: 24 / 16,
                      letterSpacing: -0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
