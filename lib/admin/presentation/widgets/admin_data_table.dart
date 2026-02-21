import 'package:flutter/material.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_spacing.dart';

/// 관리자 패널 재사용 가능한 데이터 테이블
///
/// 페이지네이션 기능을 포함한 DataTable 래퍼 위젯
class AdminDataTable extends StatelessWidget {
  const AdminDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.currentPage = 1,
    this.totalPages = 1,
    this.onPageChanged,
    this.onRowTap,
  });

  final List<DataColumn> columns;
  final List<DataRow> rows;
  final int currentPage;
  final int totalPages;
  final ValueChanged<int>? onPageChanged;
  final ValueChanged<int>? onRowTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 데이터 테이블
        Card(
          child: SizedBox(
            width: double.infinity,
            child: DataTable(
              columns: columns,
              rows: rows,
              headingRowHeight: 48,
              dataRowMinHeight: 48,
              dataRowMaxHeight: 56,
              columnSpacing: AppSpacing.xxl,
              horizontalMargin: AppSpacing.xl,
            ),
          ),
        ),
        // 페이지네이션
        if (totalPages > 1)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 이전 페이지 버튼
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: currentPage > 1
                      ? () => onPageChanged?.call(currentPage - 1)
                      : null,
                ),
                // 페이지 번호 버튼들 (최대 5개 표시)
                ...List.generate(
                  totalPages > 5 ? 5 : totalPages,
                  (i) {
                    int page;
                    if (totalPages <= 5) {
                      page = i + 1;
                    } else if (currentPage <= 3) {
                      page = i + 1;
                    } else if (currentPage >= totalPages - 2) {
                      page = totalPages - 4 + i;
                    } else {
                      page = currentPage - 2 + i;
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: TextButton(
                          onPressed: () => onPageChanged?.call(page),
                          style: TextButton.styleFrom(
                            backgroundColor: page == currentPage
                                ? AppColors.brand
                                : Colors.transparent,
                            foregroundColor: page == currentPage
                                ? AppColors.textInverse
                                : AppColors.textMain,
                            padding: EdgeInsets.zero,
                            shape: const RoundedRectangleBorder(
                              borderRadius: AppRadius.smBorderRadius,
                            ),
                          ),
                          child: Text(
                            '$page',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // 다음 페이지 버튼
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: currentPage < totalPages
                      ? () => onPageChanged?.call(currentPage + 1)
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
