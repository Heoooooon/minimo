import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import '../../../core/admin_dependencies.dart';
import '../../viewmodels/admin_user_viewmodel.dart';

/// 관리자 사용자 상세 화면
///
/// 사용자 프로필 정보, 통계, 역할/상태 변경 기능 제공
class AdminUserDetailScreen extends StatefulWidget {
  const AdminUserDetailScreen({super.key, required this.userId});

  final String userId;

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  late AdminUserViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    final deps = Provider.of<AdminDependencies>(context, listen: false);
    _viewModel = deps.createUserViewModel();
    _viewModel.loadUserDetail(widget.userId);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('사용자 상세')),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          // 로딩 상태
          if (_viewModel.isLoading && _viewModel.selectedUser == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = _viewModel.selectedUser;
          if (user == null) {
            return Center(
              child: Text(_viewModel.errorMessage ?? '사용자를 찾을 수 없습니다.'),
            );
          }

          final role = user['role']?.toString() ?? 'user';
          final verified = user['verified'] == true;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 사용자 프로필 카드
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        // 아바타
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: AppColors.chipPrimaryBg,
                          child: Text(
                            (user['name']?.toString() ?? '?')
                                .substring(0, 1)
                                .toUpperCase(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.brand,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        // 사용자 정보
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user['name']?.toString() ?? '-',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user['email']?.toString() ?? '-',
                                style: const TextStyle(color: AppColors.textSubtle),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '가입일: ${user['created']?.toString() ?? '-'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 통계 칩 행
                Row(
                  children: [
                    _StatChip(label: '어항', value: '${user['aquarium_count'] ?? 0}'),
                    const SizedBox(width: 8),
                    _StatChip(label: '게시글', value: '${user['post_count'] ?? 0}'),
                    const SizedBox(width: 8),
                    _StatChip(label: '질문', value: '${user['question_count'] ?? 0}'),
                    const SizedBox(width: 8),
                    _StatChip(label: '신고', value: '${user['report_count'] ?? 0}'),
                  ],
                ),
                const SizedBox(height: 24),

                // 관리 작업 카드
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '관리 작업',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),

                        // 역할 변경
                        Row(
                          children: [
                            const Text('역할: ', style: TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(width: 8),
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(value: 'user', label: Text('일반')),
                                ButtonSegment(value: 'admin', label: Text('관리자')),
                              ],
                              selected: {role},
                              onSelectionChanged: (selected) async {
                                final newRole = selected.first;
                                final confirmed = await _showConfirmDialog(
                                  '역할을 ${newRole == 'admin' ? '관리자' : '일반'}(으)로 변경하시겠습니까?',
                                );
                                if (confirmed == true) {
                                  await _viewModel.updateUserRole(widget.userId, newRole);
                                  _viewModel.loadUserDetail(widget.userId);
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // 상태 변경 (활성/차단)
                        Row(
                          children: [
                            const Text('상태: ', style: TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(width: 8),
                            Switch(
                              value: verified,
                              onChanged: (value) async {
                                final confirmed = await _showConfirmDialog(
                                  value ? '사용자를 활성화하시겠습니까?' : '사용자를 차단하시겠습니까?',
                                );
                                if (confirmed == true) {
                                  await _viewModel.updateUserStatus(widget.userId, value);
                                  _viewModel.loadUserDetail(widget.userId);
                                }
                              },
                            ),
                            Text(
                              verified ? '활성' : '차단',
                              style: TextStyle(
                                color: verified ? AppColors.success : AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 확인 다이얼로그 표시
  Future<bool?> _showConfirmDialog(String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('확인'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}

/// 통계 칩 위젯
///
/// 사용자 상세 화면에서 어항/게시글/질문/신고 수를 표시
class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Column(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brand,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: AppColors.textSubtle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
