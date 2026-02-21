import 'package:flutter/material.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_spacing.dart';
import '../../viewmodels/admin_content_viewmodel.dart';
import '../../widgets/admin_data_table.dart';

/// 관리자 질문 관리 탭 화면
///
/// 질문 목록을 테이블로 표시하고 상태 변경 기능 제공
class AdminQuestionListScreen extends StatelessWidget {
  const AdminQuestionListScreen({super.key, required this.viewModel});

  final AdminContentViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    // 로딩 상태
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: AdminDataTable(
        columns: const [
          DataColumn(label: Text('작성자')),
          DataColumn(label: Text('제목')),
          DataColumn(label: Text('카테고리')),
          DataColumn(label: Text('답변'), numeric: true),
          DataColumn(label: Text('상태')),
          DataColumn(label: Text('작업')),
        ],
        rows: viewModel.questions.map((q) {
          final status = q['status']?.toString() ?? 'active';
          return DataRow(cells: [
            DataCell(Text(q['author_name']?.toString() ?? '-')),
            DataCell(
              SizedBox(
                width: 200,
                child: Text(
                  q['title']?.toString() ?? '',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            DataCell(Text(q['category']?.toString() ?? '-')),
            DataCell(Text('${q['answer_count'] ?? 0}')),
            DataCell(_buildStatusBadge(status)),
            // 상태 변경 메뉴
            DataCell(
              PopupMenuButton<String>(
                onSelected: (value) => viewModel.updateQuestionStatus(q['id'], value),
                itemBuilder: (_) => [
                  if (status != 'active')
                    const PopupMenuItem(value: 'active', child: Text('활성화')),
                  if (status != 'hidden')
                    const PopupMenuItem(value: 'hidden', child: Text('숨기기')),
                  if (status != 'deleted')
                    const PopupMenuItem(value: 'deleted', child: Text('삭제')),
                ],
                child: const Icon(Icons.more_vert, size: 18),
              ),
            ),
          ]);
        }).toList(),
        currentPage: viewModel.questionPage,
        totalPages: viewModel.questionTotalPages,
        onPageChanged: (page) => viewModel.loadQuestions(page: page),
      ),
    );
  }

  /// 상태 뱃지 생성
  Widget _buildStatusBadge(String status) {
    final Color bg;
    final Color text;
    final String label;

    switch (status) {
      case 'active':
        bg = AppColors.chipSuccessBg;
        text = AppColors.success;
        label = '활성';
      case 'hidden':
        bg = AppColors.chipSecondaryBg;
        text = AppColors.warning;
        label = '숨김';
      case 'deleted':
        bg = AppColors.chipErrorBg;
        text = AppColors.error;
        label = '삭제됨';
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
}
