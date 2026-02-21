import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_spacing.dart';
import '../../../core/admin_dependencies.dart';
import '../../viewmodels/admin_dashboard_viewmodel.dart';
import '../../widgets/admin_stat_card.dart';
import '../../widgets/admin_activity_chart.dart';

/// 관리자 대시보드 화면
///
/// 주요 통계 카드(사용자, 게시글, 질문, 대기 신고)와
/// 최근 7일 활동 차트를 표시
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late AdminDashboardViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    final deps = Provider.of<AdminDependencies>(context, listen: false);
    _viewModel = deps.createDashboardViewModel();
    _viewModel.loadDashboard();
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
        // 최초 로딩 상태
        if (_viewModel.isLoading && _viewModel.overview == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final overview = _viewModel.overview ?? {};

        return RefreshIndicator(
          onRefresh: _viewModel.loadDashboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더: 제목 + 새로고침 버튼
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '대시보드',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _viewModel.loadDashboard,
                      tooltip: '새로고침',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 에러 메시지
                if (_viewModel.errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: const BoxDecoration(
                      color: AppColors.chipErrorBg,
                      borderRadius: AppRadius.smBorderRadius,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _viewModel.errorMessage!,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),

                // 통계 카드 그리드 (2x2)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = (constraints.maxWidth - 16) / 2;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: cardWidth,
                          child: AdminStatCard(
                            icon: Icons.people,
                            label: '전체 사용자',
                            value: '${overview['total_users'] ?? 0}',
                            iconColor: AppColors.brand,
                            iconBgColor: AppColors.chipPrimaryBg,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: AdminStatCard(
                            icon: Icons.article,
                            label: '전체 게시글',
                            value: '${overview['total_posts'] ?? 0}',
                            iconColor: AppColors.success,
                            iconBgColor: AppColors.chipSuccessBg,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: AdminStatCard(
                            icon: Icons.help_outline,
                            label: '전체 질문',
                            value: '${overview['total_questions'] ?? 0}',
                            iconColor: AppColors.warning,
                            iconBgColor: AppColors.chipSecondaryBg,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: AdminStatCard(
                            icon: Icons.flag,
                            label: '대기 중 신고',
                            value: '${overview['pending_reports'] ?? 0}',
                            iconColor: AppColors.error,
                            iconBgColor: AppColors.chipErrorBg,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // 최근 활동 차트
                AdminActivityChart(data: _viewModel.activity),
              ],
            ),
          ),
        );
      },
    );
  }
}
