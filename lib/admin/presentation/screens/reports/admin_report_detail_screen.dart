import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import '../../../core/admin_dependencies.dart';
import '../../viewmodels/admin_report_viewmodel.dart';

/// 관리자 신고 상세 화면
///
/// 신고 정보 표시 및 처리(경고/삭제/차단/조치없음) 폼 제공
class AdminReportDetailScreen extends StatefulWidget {
  const AdminReportDetailScreen({super.key, required this.reportId});

  final String reportId;

  @override
  State<AdminReportDetailScreen> createState() => _AdminReportDetailScreenState();
}

class _AdminReportDetailScreenState extends State<AdminReportDetailScreen> {
  late AdminReportViewModel _viewModel;
  final _noteController = TextEditingController();
  String _selectedAction = 'warning';

  @override
  void initState() {
    super.initState();
    final deps = Provider.of<AdminDependencies>(context, listen: false);
    _viewModel = deps.createReportViewModel();
    _viewModel.loadReportDetail(widget.reportId);
  }

  @override
  void dispose() {
    _noteController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('신고 상세')),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          // 로딩 상태
          if (_viewModel.isLoading && _viewModel.selectedReport == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final report = _viewModel.selectedReport;
          if (report == null) {
            return Center(
              child: Text(_viewModel.errorMessage ?? '신고를 찾을 수 없습니다.'),
            );
          }

          final status = report['status']?.toString() ?? 'pending';
          final isResolved = status != 'pending';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 신고 정보 카드
                _buildReportInfoCard(report, status),
                const SizedBox(height: 16),

                // 이미 처리된 경우: 처리 결과 표시
                if (isResolved) _buildResolvedCard(report),

                // 미처리 상태: 처리 폼 표시
                if (!isResolved) _buildResolveForm(),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 신고 정보 카드
  Widget _buildReportInfoCard(Map<String, dynamic> report, String status) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '신고 정보',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            _InfoRow(label: '신고자', value: report['reporter_name']?.toString() ?? '-'),
            _InfoRow(
              label: '대상 유형',
              value: _translateType(report['target_type']?.toString() ?? ''),
            ),
            _InfoRow(label: '대상 ID', value: report['target_id']?.toString() ?? '-'),
            _InfoRow(label: '사유', value: report['reason']?.toString() ?? '-'),
            // 상세 내용이 있는 경우에만 표시
            if (report['detail'] != null &&
                report['detail'].toString().isNotEmpty)
              _InfoRow(label: '상세', value: report['detail'].toString()),
            _InfoRow(label: '신고일', value: report['created']?.toString() ?? '-'),
            _InfoRow(label: '상태', value: _translateStatus(status)),
          ],
        ),
      ),
    );
  }

  /// 처리 완료 결과 카드
  Widget _buildResolvedCard(Map<String, dynamic> report) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '처리 결과',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            _InfoRow(
              label: '조치',
              value: _translateAction(report['action_taken']?.toString() ?? ''),
            ),
            if (report['admin_note'] != null &&
                report['admin_note'].toString().isNotEmpty)
              _InfoRow(label: '관리자 메모', value: report['admin_note'].toString()),
          ],
        ),
      ),
    );
  }

  /// 신고 처리 폼
  Widget _buildResolveForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '신고 처리',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // 조치 선택
            const Text('조치 선택', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'warning', label: Text('경고')),
                ButtonSegment(value: 'delete', label: Text('삭제')),
                ButtonSegment(value: 'block', label: Text('차단')),
                ButtonSegment(value: 'none', label: Text('조치없음')),
              ],
              selected: {_selectedAction},
              onSelectionChanged: (selected) {
                setState(() => _selectedAction = selected.first);
              },
            ),
            const SizedBox(height: 16),

            // 관리자 메모 입력
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: '관리자 메모',
                hintText: '처리 사유를 입력하세요...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // 처리 버튼
            Row(
              children: [
                ElevatedButton(
                  onPressed: _viewModel.isLoading ? null : _handleResolve,
                  child: const Text('처리 완료'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 신고 처리 실행
  Future<void> _handleResolve() async {
    final success = await _viewModel.resolveReport(
      widget.reportId,
      action: _selectedAction,
      adminNote: _noteController.text.isNotEmpty ? _noteController.text : null,
    );
    if (success && mounted) {
      Navigator.pop(context);
    }
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

  /// 상태 한글 번역
  String _translateStatus(String status) {
    switch (status) {
      case 'pending':
        return '대기';
      case 'resolved':
        return '처리됨';
      case 'dismissed':
        return '기각';
      default:
        return status;
    }
  }

  /// 조치 한글 번역
  String _translateAction(String action) {
    switch (action) {
      case 'warning':
        return '경고';
      case 'delete':
        return '삭제';
      case 'block':
        return '차단';
      case 'none':
        return '조치없음';
      default:
        return action;
    }
  }
}

/// 정보 행 위젯
///
/// 레이블-값 쌍을 가로 행으로 표시
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSubtle,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
