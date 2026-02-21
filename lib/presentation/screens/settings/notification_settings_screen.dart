import 'package:flutter/material.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';

/// 알림 설정 화면
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _pushEnabled = true;
  bool _scheduleAlarm = true;
  bool _communityReply = true;
  bool _communityLike = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSurface,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text('알림 설정', style: AppTextStyles.bodyMediumBold),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('푸시 알림'),
          _buildSwitchRow(
            title: '푸시 알림 허용',
            subtitle: '모든 알림을 켜거나 끕니다',
            value: _pushEnabled,
            onChanged: (v) => setState(() => _pushEnabled = v),
          ),
          const Divider(height: 1, indent: 20, endIndent: 20, color: AppColors.borderLight),

          _buildSectionHeader('알림 항목'),
          _buildSwitchRow(
            title: '일정 알림',
            subtitle: '등록한 일정 알림을 받습니다',
            value: _scheduleAlarm,
            enabled: _pushEnabled,
            onChanged: (v) => setState(() => _scheduleAlarm = v),
          ),
          const Divider(height: 1, indent: 20, endIndent: 20, color: AppColors.borderLight),
          _buildSwitchRow(
            title: '커뮤니티 댓글',
            subtitle: '내 글에 댓글이 달리면 알림을 받습니다',
            value: _communityReply,
            enabled: _pushEnabled,
            onChanged: (v) => setState(() => _communityReply = v),
          ),
          const Divider(height: 1, indent: 20, endIndent: 20, color: AppColors.borderLight),
          _buildSwitchRow(
            title: '커뮤니티 좋아요',
            subtitle: '내 글에 좋아요가 달리면 알림을 받습니다',
            value: _communityLike,
            enabled: _pushEnabled,
            onChanged: (v) => setState(() => _communityLike = v),
          ),

          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '알림 설정은 현재 기기에만 적용됩니다.\n시스템 설정에서 앱 알림을 끄면 모든 알림이 차단됩니다.',
              style: AppTextStyles.captionRegular.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 28, bottom: 8),
      child: Text(
        title,
        style: AppTextStyles.captionMedium.copyWith(
          color: AppColors.textSubtle,
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: enabled ? AppColors.textMain : AppColors.textHint,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.captionRegular.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value && enabled,
            onChanged: enabled ? onChanged : null,
            activeTrackColor: AppColors.brand,
          ),
        ],
      ),
    );
  }
}
