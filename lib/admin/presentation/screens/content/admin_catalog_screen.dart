import 'package:flutter/material.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import '../../viewmodels/admin_content_viewmodel.dart';
import '../../widgets/admin_data_table.dart';

/// 관리자 카탈로그 승인 화면
///
/// 사용자가 신청한 어종 카탈로그를 승인/거부 처리
class AdminCatalogScreen extends StatelessWidget {
  const AdminCatalogScreen({super.key, required this.viewModel});

  final AdminContentViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    // 로딩 상태
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 대기 목록이 없는 경우
    if (viewModel.pendingCatalog.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: AppColors.success),
            SizedBox(height: 12),
            Text(
              '대기 중인 카탈로그가 없습니다.',
              style: TextStyle(color: AppColors.textSubtle),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: AdminDataTable(
        columns: const [
          DataColumn(label: Text('신청자')),
          DataColumn(label: Text('일반명')),
          DataColumn(label: Text('학명')),
          DataColumn(label: Text('상태')),
          DataColumn(label: Text('작업')),
        ],
        rows: viewModel.pendingCatalog.map((item) {
          return DataRow(cells: [
            DataCell(Text(item['reporter_name']?.toString() ?? '-')),
            DataCell(Text(item['common_name']?.toString() ?? '-')),
            // 학명은 이탤릭체로 표시
            DataCell(
              Text(
                item['scientific_name']?.toString() ?? '-',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
            DataCell(Text(item['status']?.toString() ?? 'pending')),
            // 승인/거부 버튼
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: AppColors.success, size: 18),
                    tooltip: '승인',
                    onPressed: () => viewModel.approveCatalog(item['id'], true),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.error, size: 18),
                    tooltip: '거부',
                    onPressed: () => viewModel.approveCatalog(item['id'], false),
                  ),
                ],
              ),
            ),
          ]);
        }).toList(),
        currentPage: viewModel.catalogPage,
        totalPages: viewModel.catalogTotalPages,
        onPageChanged: (page) => viewModel.loadPendingCatalog(page: page),
      ),
    );
  }
}
