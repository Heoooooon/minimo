import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/di/app_dependencies.dart';
import '../../../data/services/community_service.dart';
import '../../../data/services/answer_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../domain/models/question_data.dart';
import '../../../domain/models/answer_data.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';
import 'package:cmore_design_system/widgets/empty_state.dart';

/// 질문 상세 화면
class QuestionDetailScreen extends StatefulWidget {
  const QuestionDetailScreen({super.key});

  @override
  State<QuestionDetailScreen> createState() => _QuestionDetailScreenState();
}

class _QuestionDetailScreenState extends State<QuestionDetailScreen> {
  late final AppDependencies _dependencies;
  late final CommunityService _service;
  late final AnswerService _answerService;
  late final AuthService _authService;
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _answerFocusNode = FocusNode();

  QuestionData? _question;
  String? _questionId;
  List<AnswerData> _answers = [];
  bool _isLoading = true;
  bool _isLoadingAnswers = false;
  String? _errorMessage;
  bool _isSubmitting = false;
  bool _isDependenciesReady = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isDependenciesReady) return;

    _dependencies = context.read<AppDependencies>();
    _service = _dependencies.communityService;
    _answerService = _dependencies.answerService;
    _authService = _dependencies.authService;
    _isDependenciesReady = true;

    _loadQuestion();
  }

  @override
  void dispose() {
    _answerController.dispose();
    _answerFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadQuestion() async {
    _questionId = ModalRoute.of(context)?.settings.arguments as String?;
    if (_questionId == null) {
      setState(() {
        _errorMessage = '질문 ID가 없습니다.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final question = await _service.getQuestion(_questionId!);

      // 조회수 증가
      await _service.incrementViewCount(_questionId!);

      setState(() {
        _question = question;
        _isLoading = false;
      });

      // 답변 로드
      if (question != null) {
        _loadAnswers();
      }
    } catch (e) {
      AppLogger.data('질문 로드 실패: $e', isError: true);
      setState(() {
        _errorMessage = '질문을 불러오는데 실패했습니다.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAnswers() async {
    if (_questionId == null) return;

    setState(() {
      _isLoadingAnswers = true;
    });

    try {
      final answers = await _answerService.getAnswers(questionId: _questionId!);
      setState(() {
        _answers = answers;
        _isLoadingAnswers = false;
      });
    } catch (e) {
      AppLogger.data('Failed to load answers: $e', isError: true);
      setState(() {
        _isLoadingAnswers = false;
      });
    }
  }

  Future<void> _submitAnswer() async {
    if (_answerController.text.trim().isEmpty || _questionId == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // 현재 사용자 이름 가져오기
      final currentUser = _authService.currentUser;
      final userName = currentUser?.getStringValue('name') ?? '익명';

      final answerData = AnswerData(
        questionId: _questionId!,
        authorId: currentUser?.id,
        authorName: userName,
        content: _answerController.text.trim(),
      );

      await _answerService.createAnswer(answerData);

      _answerController.clear();
      _answerFocusNode.unfocus();

      // 답변 목록 새로고침
      await _loadAnswers();

      // 답변 수 업데이트
      if (_question != null) {
        setState(() {
          _question = QuestionData(
            id: _question!.id,
            title: _question!.title,
            content: _question!.content,
            category: _question!.category,
            attachedRecords: _question!.attachedRecords,
            viewCount: _question!.viewCount,
            commentCount: _question!.commentCount + 1,
            created: _question!.created,
            updated: _question!.updated,
          );
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('답변이 등록되었습니다.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      AppLogger.data('답변 등록 실패: $e', isError: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('답변 등록에 실패했습니다.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundApp,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textMain),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Q&A',
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textMain,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textMain),
            onPressed: _showOptions,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildAnswerInput(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.brand),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSubtle,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadQuestion,
              child: Text(
                '다시 시도',
                style: AppTextStyles.bodyMediumBold.copyWith(
                  color: AppColors.brand,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_question == null) {
      return const Center(child: Text('질문을 찾을 수 없습니다.'));
    }

    return RefreshIndicator(
      onRefresh: _loadQuestion,
      color: AppColors.brand,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 질문 헤더
            _buildQuestionHeader(),

            const Divider(height: 1, color: AppColors.borderLight),

            // 질문 내용
            _buildQuestionContent(),

            // 첨부된 기록
            if (_question!.attachedRecords.isNotEmpty) ...[
              const Divider(height: 1, color: AppColors.borderLight),
              _buildAttachedRecords(),
            ],

            const Divider(height: 1, color: AppColors.borderLight),

            // 답변 섹션
            _buildAnswersSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 카테고리 태그
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.chipPrimaryBg,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _getCategoryLabel(_question!.category),
              style: AppTextStyles.captionMedium.copyWith(
                color: AppColors.brand,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 제목
          Text(
            _question!.title,
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textMain,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // 메타 정보
          Row(
            children: [
              // 프로필 아바타
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gray200,
                ),
                child: const Icon(
                  Icons.person,
                  size: 18,
                  color: AppColors.textHint,
                ),
              ),
              const SizedBox(width: 8),

              // 작성자명 (익명)
              Text(
                '익명',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSubtle,
                ),
              ),
              const SizedBox(width: 16),

              // 시간
              Text(
                _formatTimeAgo(_question!.created),
                style: AppTextStyles.captionRegular.copyWith(
                  color: AppColors.textHint,
                ),
              ),

              const Spacer(),

              // 조회수
              Row(
                children: [
                  const Icon(
                    Icons.remove_red_eye_outlined,
                    size: 16,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_question!.viewCount}',
                    style: AppTextStyles.captionRegular.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Text(
        _question!.content,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textMain,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildAttachedRecords() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '첨부된 기록',
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.textMain,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // 첨부된 기록 목록
          ...(_question!.attachedRecords.map((record) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFDFDFF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.chipPrimaryBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.description,
                      color: AppColors.brand,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.tags.isNotEmpty
                              ? record.tags.first.label
                              : '기록',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textMain,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          record.content,
                          style: AppTextStyles.captionRegular.copyWith(
                            color: AppColors.textSubtle,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textHint),
                ],
              ),
            );
          })),
        ],
      ),
    );
  }

  Widget _buildAnswersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '답변',
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.textMain,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_answers.length}',
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.brand,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 로딩 중
          if (_isLoadingAnswers)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: AppColors.brand),
              ),
            )
          // 답변이 없는 경우
          else if (_answers.isEmpty)
            EmptyStatePresets.noComments(type: '답변')
          // 답변 목록
          else
            ..._answers.map((answer) => _buildAnswerItem(answer)),
        ],
      ),
    );
  }

  Widget _buildAnswerItem(AnswerData answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: answer.isAccepted
            ? AppColors.chipPrimaryBg
            : const Color(0xFFFDFDFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: answer.isAccepted ? AppColors.brand : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 채택 배지
          if (answer.isAccepted)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.brand,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '채택된 답변',
                style: AppTextStyles.captionMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          // 작성자 정보
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gray200,
                ),
                child: const Icon(
                  Icons.person,
                  size: 18,
                  color: AppColors.textHint,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                answer.authorName,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMain,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatTimeAgo(answer.created),
                style: AppTextStyles.captionRegular.copyWith(
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 답변 내용
          Text(
            answer.content,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textMain,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),

          // 좋아요 + 채택 버튼
          Row(
            children: [
              GestureDetector(
                onTap: () async {
                  if (answer.id != null) {
                    // 낙관적 업데이트
                    final newCount = answer.likeCount + 1;
                    setState(() {
                      final idx = _answers.indexWhere((a) => a.id == answer.id);
                      if (idx != -1) {
                        _answers[idx] = AnswerData(
                          id: answer.id,
                          questionId: answer.questionId,
                          authorId: answer.authorId,
                          authorName: answer.authorName,
                          content: answer.content,
                          likeCount: newCount,
                          isAccepted: answer.isAccepted,
                          created: answer.created,
                        );
                      }
                    });
                    try {
                      await _answerService.toggleLike(answer.id!, true);
                      _loadAnswers();
                    } catch (e) {
                      AppLogger.data('답변 좋아요 토글 실패: $e', isError: true);
                      _loadAnswers();
                    }
                  }
                },
                child: Row(
                  children: [
                    Icon(
                      answer.likeCount > 0
                          ? Icons.favorite
                          : Icons.favorite_border,
                      size: 18,
                      color: answer.likeCount > 0
                          ? AppColors.error
                          : AppColors.textHint,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${answer.likeCount}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              // 채택 버튼: 질문 작성자만 보이고, 본인 답변은 제외, 아직 채택 안된 경우만
              if (_canAcceptAnswer(answer)) ...[
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => _acceptAnswer(answer),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.brand),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '채택하기',
                      style: AppTextStyles.captionMedium.copyWith(
                        color: AppColors.brand,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFF),
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _answerController,
              focusNode: _answerFocusNode,
              decoration: InputDecoration(
                hintText: '답변을 입력하세요...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textHint,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppColors.brand),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submitAnswer(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isSubmitting ? null : _submitAnswer,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _isSubmitting
                    ? AppColors.brand.withValues(alpha: 0.5)
                    : AppColors.brand,
                shape: BoxShape.circle,
              ),
              child: _isSubmitting
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('신고하기'),
              onTap: () {
                Navigator.pop(context);
                _showReportDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('공유하기'),
              onTap: () {
                Navigator.pop(context);
                _shareQuestion();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 현재 사용자가 이 답변을 채택할 수 있는지 확인
  bool _canAcceptAnswer(AnswerData answer) {
    final currentUserId = _authService.currentUser?.id;
    if (currentUserId == null || _question == null) return false;

    // 질문 작성자만 채택 가능
    if (_question!.ownerId != currentUserId) return false;

    // 본인 답변은 채택 불가
    if (answer.authorId == currentUserId) return false;

    // 이미 채택된 답변이 있으면 채택 버튼 숨김
    if (_answers.any((a) => a.isAccepted)) return false;

    return true;
  }

  Future<void> _acceptAnswer(AnswerData answer) async {
    if (answer.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('답변 채택'),
        content: const Text('이 답변을 채택하시겠습니까?\n채택 후에는 변경할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('취소', style: TextStyle(color: AppColors.textSubtle)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand),
            child: const Text('채택', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _answerService.acceptAnswer(answer.id!);
      await _loadAnswers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('답변이 채택되었습니다.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      AppLogger.data('답변 채택 실패: $e', isError: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('답변 채택에 실패했습니다.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return '방금 전';

    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) {
      return '${diff.inDays}일 전';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}시간 전';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}분 전';
    }
    return '방금 전';
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'beginner':
        return '초보';
      case 'maintenance':
        return '관리';
      case 'species':
        return '어종';
      case 'disease':
        return '질병';
      case 'equipment':
        return '장비';
      case 'other':
        return '기타';
      default:
        return category.isNotEmpty ? category : '일반';
    }
  }

  void _showReportDialog() {
    final reasons = ['스팸/광고', '욕설/비하', '음란물', '허위정보', '저작권 침해', '기타'];
    String? selectedReason;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('질문 신고'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '신고 사유를 선택해주세요.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSubtle,
                ),
              ),
              const SizedBox(height: 16),
              RadioGroup<String>(
                groupValue: selectedReason ?? '',
                onChanged: (value) {
                  setState(() {
                    selectedReason = value;
                  });
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: reasons
                      .map(
                        (reason) => RadioListTile<String>(
                          title: Text(reason),
                          value: reason,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('취소', style: TextStyle(color: AppColors.textSubtle)),
            ),
            ElevatedButton(
              onPressed: selectedReason == null
                  ? null
                  : () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text('신고가 접수되었습니다.'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('신고', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _shareQuestion() {
    if (_questionId == null) return;

    final shareUrl = 'minimo://question/$_questionId';
    Clipboard.setData(ClipboardData(text: shareUrl));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('링크가 클립보드에 복사되었습니다.'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}
