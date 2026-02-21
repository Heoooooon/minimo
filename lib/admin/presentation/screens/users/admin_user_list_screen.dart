import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_spacing.dart';
import '../../../core/admin_dependencies.dart';
import '../../viewmodels/admin_user_viewmodel.dart';
import '../../widgets/admin_data_table.dart';
import '../../widgets/admin_search_bar.dart';
import 'admin_user_detail_screen.dart';

/// 관리자 사용자 목록 화면
///
/// 검색, 역할 필터, 데이터 테이블을 통해 사용자 목록 관리
class AdminUserListScreen extends StatefulWidget {
  const AdminUserListScreen({super.key});

  @override
  State<AdminUserListScreen> createState() => _AdminUserListScreenState();
}

class _AdminUserListScreenState extends State<AdminUserListScreen> {
  late AdminUserViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    final deps = Provider.of<AdminDependencies>(context, listen: false);
    _viewModel = deps.createUserViewModel();
    _viewModel.loadUsers();
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
                '사용자 관리',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                '총 ${_viewModel.totalItems}명',
                style: const TextStyle(color: AppColors.textSubtle),
              ),
              const SizedBox(height: 20),

              // 검색 + 역할 필터
              AdminSearchBar(
                hintText: '이름 또는 이메일 검색...',
                onSearch: _viewModel.setSearchQuery,
                filterOptions: const [
                  AdminFilterOption(label: '일반', value: 'user'),
                  AdminFilterOption(label: '관리자', value: 'admin'),
                ],
                selectedFilter: _viewModel.roleFilter,
                onFilterChanged: _viewModel.setRoleFilter,
              ),
              const SizedBox(height: 16),

              // 콘텐츠 영역
              if (_viewModel.isLoading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (_viewModel.errorMessage != null)
                Expanded(
                  child: Center(
                    child: Text(
                      _viewModel.errorMessage!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: AdminDataTable(
                      columns: const [
                        DataColumn(label: Text('이름')),
                        DataColumn(label: Text('이메일')),
                        DataColumn(label: Text('역할')),
                        DataColumn(label: Text('인증')),
                        DataColumn(label: Text('가입일')),
                      ],
                      rows: _viewModel.users.map((user) {
                        final role = user['role']?.toString() ?? 'user';
                        final verified = user['verified'] == true;
                        return DataRow(
                          onSelectChanged: (_) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AdminUserDetailScreen(userId: user['id']),
                              ),
                            );
                          },
                          cells: [
                            DataCell(Text(user['name']?.toString() ?? '-')),
                            DataCell(Text(user['email']?.toString() ?? '-')),
                            // 역할 뱃지
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: role == 'admin'
                                      ? AppColors.chipPrimaryBg
                                      : AppColors.chipDisabledBg,
                                  borderRadius: AppRadius.xsBorderRadius,
                                ),
                                child: Text(
                                  role == 'admin' ? '관리자' : '일반',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: role == 'admin'
                                        ? AppColors.brand
                                        : AppColors.textSubtle,
                                  ),
                                ),
                              ),
                            ),
                            // 인증 상태 아이콘
                            DataCell(
                              Icon(
                                verified ? Icons.check_circle : Icons.cancel,
                                size: 18,
                                color: verified ? AppColors.success : AppColors.textHint,
                              ),
                            ),
                            DataCell(Text(_formatDate(user['created']?.toString()))),
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
