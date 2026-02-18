import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../data/services/data_backup_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/settings_row.dart';

/// 데이터 백업 화면
///
/// 자동 백업 토글, 즉시 백업, 기록 CSV 내보내기, 데이터 복원
class DataBackupScreen extends StatefulWidget {
  const DataBackupScreen({super.key});

  @override
  State<DataBackupScreen> createState() => _DataBackupScreenState();
}

class _DataBackupScreenState extends State<DataBackupScreen> {
  final _backupService = DataBackupService.instance;

  bool _autoBackup = false;
  DateTime? _lastBackupDate;
  bool _isBackingUp = false;
  bool _isExportingCsv = false;
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final autoBackup = await _backupService.isAutoBackupEnabled();
    final lastDate = await _backupService.getLastBackupDate();
    if (!mounted) return;
    setState(() {
      _autoBackup = autoBackup;
      _lastBackupDate = lastDate;
    });
  }

  // ── 백업 ──

  Future<void> _handleBackup() async {
    setState(() => _isBackingUp = true);

    try {
      await _backupService.backupToLocal();
      await _loadSettings(); // 마지막 백업 일시 갱신

      if (!mounted) return;
      _showSuccessToast('백업이 완료되었어요!');
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('백업에 실패했습니다: $e');
    } finally {
      if (mounted) {
        setState(() => _isBackingUp = false);
      }
    }
  }

  // ── CSV 내보내기 ──

  Future<void> _handleExportCsv() async {
    setState(() => _isExportingCsv = true);

    try {
      await _backupService.exportRecordsCsv();
      if (!mounted) return;
      // share_plus가 공유 시트를 열어주므로 별도 토스트 불필요
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('CSV 내보내기에 실패했습니다: $e');
    } finally {
      if (mounted) {
        setState(() => _isExportingCsv = false);
      }
    }
  }

  // ── 데이터 복원 ──

  Future<void> _handleRestore() async {
    // 백업 파일 선택
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return;

    final filePath = result.files.single.path!;

    if (!mounted) return;

    // 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundSurface,
        title: Text('데이터 복원', style: AppTextStyles.titleMedium),
        content: Text(
          '선택한 백업 파일로 데이터를 복원합니다.\n기존 데이터와 중복될 수 있습니다.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSubtle),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              '취소',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSubtle,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              '복원',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.brand),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isRestoring = true);

    try {
      final jsonString = await File(filePath).readAsString();
      final importResult = await _backupService.restoreFromJson(jsonString);

      if (!mounted) return;

      if (importResult.isSuccess) {
        _showSuccessToast('복원 완료! ${importResult.imported}건의 데이터를 가져왔어요.');
      } else {
        _showSuccessToast(
          '복원 완료: ${importResult.imported}건 성공, ${importResult.failed}건 실패',
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('데이터 복원에 실패했습니다: $e');
    } finally {
      if (mounted) {
        setState(() => _isRestoring = false);
      }
    }
  }

  // ── UI 헬퍼 ──

  void _showSuccessToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.success,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFD7FFE9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDate(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final ampm = date.hour >= 12 ? '오후' : '오전';
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} '
        '$ampm $hour:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSurface,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text('데이터 백업', style: AppTextStyles.bodyMediumMedium),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          // ── 자동 백업 토글 ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('자동 백업하기', style: AppTextStyles.bodyLarge),
                Switch(
                  value: _autoBackup,
                  activeThumbColor: AppColors.backgroundSurface,
                  activeTrackColor: AppColors.switchActiveTrack,
                  inactiveThumbColor: AppColors.backgroundSurface,
                  inactiveTrackColor: AppColors.switchInactiveTrack,
                  onChanged: (value) async {
                    setState(() => _autoBackup = value);
                    await _backupService.setAutoBackup(value);
                  },
                ),
              ],
            ),
          ),

          // ── 마지막 백업 일시 ──
          if (_lastBackupDate != null)
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
              child: Text(
                '마지막 백업  ${_formatDate(_lastBackupDate!)}',
                style: AppTextStyles.captionRegular.copyWith(
                  color: AppColors.textSubtle,
                ),
              ),
            ),

          // ── 즉시 백업 버튼 ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AppButton(
              text: _isBackingUp ? '백업 중' : '즉시 백업하기',
              size: AppButtonSize.large,
              shape: AppButtonShape.round,
              expanded: true,
              isEnabled: !_isBackingUp,
              isLoading: _isBackingUp,
              onPressed: _handleBackup,
            ),
          ),

          const SizedBox(height: 28),

          // ── 데이터 관리 섹션 ──
          const SettingsSectionHeader(title: '데이터 관리'),

          // 기록 CSV 파일
          _buildDataManagementRow(
            title: '기록 CSV 파일',
            subtitle: '텍스트 기록을 다운 받을 수 있어요.',
            buttonText: '내보내기',
            isLoading: _isExportingCsv,
            onTap: _handleExportCsv,
          ),
          const Divider(
            height: 1,
            thickness: 1,
            indent: 20,
            endIndent: 20,
            color: AppColors.borderLight,
          ),

          // 데이터 복원
          _buildDataManagementRow(
            title: '데이터 복원',
            subtitle: '최근 백업한 데이터를 기준으로 복원 돼요.',
            buttonText: '복원하기',
            isLoading: _isRestoring,
            onTap: _handleRestore,
          ),
        ],
      ),
    );
  }

  Widget _buildDataManagementRow({
    required String title,
    required String subtitle,
    required String buttonText,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleMedium),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.captionRegular.copyWith(
                    color: AppColors.textSubtle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.brand,
                  ),
                )
              : AppButtonFactories.smallOutlined(
                  text: buttonText,
                  onPressed: onTap,
                ),
        ],
      ),
    );
  }
}
