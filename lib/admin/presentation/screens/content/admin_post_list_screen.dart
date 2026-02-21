import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_spacing.dart';
import '../../../core/admin_dependencies.dart';
import '../../viewmodels/admin_content_viewmodel.dart';
import '../../widgets/admin_data_table.dart';
import '../../widgets/admin_search_bar.dart';
import 'admin_question_list_screen.dart';
import 'admin_catalog_screen.dart';

/// 관리자 콘텐츠 관리 화면 (탭 뷰)
///
/// 게시글, 질문, 카탈로그 3개 탭으로 구성
class AdminPostListScreen extends StatefulWidget {
  const AdminPostListScreen({super.key});

  @override
  State<AdminPostListScreen> createState() => _AdminPostListScreenState();
}

class _AdminPostListScreenState extends State<AdminPostListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AdminContentViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final deps = Provider.of<AdminDependencies>(context, listen: false);
    _viewModel = deps.createContentViewModel();
    // 초기 데이터 로드
    _viewModel.loadPosts();
    _viewModel.loadQuestions();
    _viewModel.loadPendingCatalog();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
                '콘텐츠 관리',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),

              // 탭 바
              TabBar(
                controller: _tabController,
                labelColor: AppColors.brand,
                unselectedLabelColor: AppColors.textSubtle,
                indicatorColor: AppColors.brand,
                tabs: const [
                  Tab(text: '게시글'),
                  Tab(text: '질문'),
                  Tab(text: '카탈로그'),
                ],
              ),
              const SizedBox(height: 16),

              // 탭 콘텐츠
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _PostsTab(viewModel: _viewModel),
                    AdminQuestionListScreen(viewModel: _viewModel),
                    AdminCatalogScreen(viewModel: _viewModel),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 게시글 탭 콘텐츠
///
/// 게시글 검색, 상태 필터, 데이터 테이블 표시
class _PostsTab extends StatelessWidget {
  const _PostsTab({required this.viewModel});

  final AdminContentViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 검색 + 상태 필터
        AdminSearchBar(
          hintText: '게시글 검색...',
          onSearch: viewModel.setSearchQuery,
          filterOptions: const [
            AdminFilterOption(label: '활성', value: 'active'),
            AdminFilterOption(label: '숨김', value: 'hidden'),
            AdminFilterOption(label: '삭제됨', value: 'deleted'),
          ],
          selectedFilter: viewModel.statusFilter,
          onFilterChanged: viewModel.setStatusFilter,
        ),
        const SizedBox(height: 16),

        // 로딩 또는 테이블
        if (viewModel.isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else
          Expanded(
            child: SingleChildScrollView(
              child: AdminDataTable(
                columns: const [
                  DataColumn(label: Text('작성자')),
                  DataColumn(label: Text('내용')),
                  DataColumn(label: Text('좋아요'), numeric: true),
                  DataColumn(label: Text('댓글'), numeric: true),
                  DataColumn(label: Text('상태')),
                  DataColumn(label: Text('작업')),
                ],
                rows: viewModel.posts.map((post) {
                  final status = post['status']?.toString() ?? 'active';
                  return DataRow(cells: [
                    DataCell(Text(post['author_name']?.toString() ?? '-')),
                    DataCell(
                      SizedBox(
                        width: 200,
                        child: Text(
                          post['content']?.toString() ?? '',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                    DataCell(Text('${post['like_count'] ?? 0}')),
                    DataCell(Text('${post['comment_count'] ?? 0}')),
                    DataCell(_StatusBadge(status: status)),
                    // 상태 변경 메뉴
                    DataCell(
                      PopupMenuButton<String>(
                        onSelected: (value) => viewModel.updatePostStatus(post['id'], value),
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
                currentPage: viewModel.postPage,
                totalPages: viewModel.postTotalPages,
                onPageChanged: (page) => viewModel.loadPosts(page: page),
              ),
            ),
          ),
      ],
    );
  }
}

/// 상태 뱃지 위젯
///
/// 게시글/질문의 상태를 색상 뱃지로 표시
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
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
