import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_spacing.dart';
import '../../../core/admin_dependencies.dart';
import '../../viewmodels/admin_report_viewmodel.dart';
import '../../widgets/admin_data_table.dart';
import 'admin_report_detail_screen.dart';

/// 관리자 신고 목록 화면
///
/// 상태 필터(대기/처리됨/기각/전체)와 데이터 테이블로 신고 관리
class AdminReportListScreen extends StatefulWidget {
  const AdminReportListScreen({super.key});

  @override
  State<AdminReportListScreen> createState() => _AdminReportListScreenState();
}

class _AdminReportListScreenState extends State<AdminReportListScreen> {
  late AdminReportViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    final deps = Provider.of<AdminDependencies>(context, listen: false);
    _viewModel = deps.createReportViewModel();
    _viewModel.loadReports();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              const Text(
                '신고 관리',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),

              // 상태 필터 칩
              Wrap(
                spacing: 8,
                children: [
                  _FilterChip(
                    label: '대기',
                    selected: _viewModel.statusFilter == 'pending',
                    onSelected: () => _viewModel.setStatusFilter('pending'),
                  ),
                  _FilterChip(
                    label: '처리됨',
                    selected: _viewModel.statusFilter == 'resolved',
                    onSelected: () => _viewModel.setStatusFilter('resolved'),
                  ),
                  _FilterChip(
                    label: '기각',
                    selected: _viewModel.statusFilter == 'dismissed',
                    onSelected: () => _viewModel.setStatusFilter('dismissed'),
                  ),
                  _FilterChip(
                    label: '전체',
                    selected: _viewModel.statusFilter.isEmpty,
                    onSelected: () => _viewModel.setStatusFilter(''),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 콘텐츠 영역
              if (_viewModel.isLoading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: AdminDataTable(
                      columns: const [
                        DataColumn(label: Text('신고자')),
                        DataColumn(label: Text('대상 유형')),
                        DataColumn(label: Text('사유')),
                        DataColumn(label: Text('상태')),
                        DataColumn(label: Text('신고일')),
                      ],
                      rows: _viewModel.reports.map((report) {
                        final status = report['status']?.toString() ?? 'pending';
                        return DataRow(
                          onSelectChanged: (_) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AdminReportDetailScreen(
                                  reportId: report['id'],
                                ),
                              ),
                            );
                          },
                          cells: [
                            DataCell(Text(report['reporter_name']?.toString() ?? '-')),
                            DataCell(Text(_translateType(report['target_type']?.toString() ?? ''))),
                            DataCell(
                              SizedBox(
                                width: 200,
                                child: Text(
                                  report['reason']?.toString() ?? '',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(_buildStatusBadge(status)),
                            DataCell(Text(_formatDate(report['created']?.toString()))),
                          ],
                        );
                      }).toList(),
                      currentPage: _viewModel.currentPage,
                      totalPages: _viewModel.totalPages,
                      onPageChanged: _viewModel.goToPage,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// 대상 유형 한글 번역
  String _translateType(String type) {
    switch (type) {
      case 'post':
        return '게시글';
      case 'question':
        return '질문';
      case 'comment':
        return '댓글';
      case 'answer':
        return '답변';
      case 'user':
        return '사용자';
      default:
        return type;
    }
  }

  /// 상태 뱃지 생성
  Widget _buildStatusBadge(String status) {
    final Color bg;
    final Color text;
    final String label;

    switch (status) {
      case 'pending':
        bg = AppColors.chipSecondaryBg;
        text = AppColors.warning;
        label = '대기';
      case 'resolved':
        bg = AppColors.chipSuccessBg;
        text = AppColors.success;
        label = '처리됨';
      case 'dismissed':
        bg = AppColors.chipDisabledBg;
        text = AppColors.textSubtle;
        label = '기각';
      default:
        bg = AppColors.chipDisabledBg;
        text = AppColors.textSubtle;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.xsBorderRadius,
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: text, fontWeight: FontWeight.w500),
      ),
    );
  }

  /// 날짜 포맷 (yyyy-MM-dd)
  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return '-';
    try {
      final dt = DateTime.parse(date);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return date;
    }
  }
}

/// 필터 칩 위젯
///
/// 신고 상태 필터링에 사용
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.chipPrimaryBg,
      checkmarkColor: AppColors.brand,
    );
  }
}
