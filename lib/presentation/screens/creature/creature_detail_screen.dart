import 'package:flutter/material.dart';
import 'dart:io';
import '../../../core/utils/app_logger.dart';
import '../../../domain/models/creature_data.dart';
import '../../../data/services/creature_service.dart';
import '../../../data/services/creature_memo_service.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'creature_register_screen.dart' hide CreatureGender;

/// 생물 상세보기 화면
class CreatureDetailScreen extends StatefulWidget {
  final CreatureData creature;

  const CreatureDetailScreen({super.key, required this.creature});

  @override
  State<CreatureDetailScreen> createState() => _CreatureDetailScreenState();
}

class _CreatureDetailScreenState extends State<CreatureDetailScreen> {
  late CreatureData _creature;
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  // ignore: unused_field - BottomSheet 로딩 상태 표시용 (추후 활용)
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _creature = widget.creature;
    _loadCreatureWithMemos();
  }

  Future<void> _loadCreatureWithMemos() async {
    if (_creature.id == null) return;

    try {
      final creatureWithMemos = await CreatureService.instance
          .getCreatureWithMemos(_creature.id!);
      if (mounted) {
        setState(() {
          _creature = creatureWithMemos;
        });
      }
    } catch (e) {
      AppLogger.data('Failed to load creature with memos: $e', isError: true);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onEdit() async {
    final result = await Navigator.push<CreatureData>(
      context,
      MaterialPageRoute(
        builder: (context) => CreatureRegisterScreen(
          existingCreature: _creature, // 수정 모드로 기존 데이터 전달
        ),
      ),
    );
    if (result != null && mounted) {
      // 수정된 데이터 반영
      setState(() {
        _creature = result;
      });
      // 메모 목록 다시 로드
      _loadCreatureWithMemos();
    }
  }

  void _onAddMemo() async {
    if (_creature.id == null) return;

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MemoEditBottomSheet(),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        final newMemo = CreatureMemoData(
          creatureId: _creature.id!,
          content: result,
        );
        final created = await CreatureMemoService.instance.createMemo(newMemo);
        if (mounted) {
          setState(() {
            _creature = _creature.copyWith(
              memos: [..._creature.memos, created],
            );
            _isLoading = false;
          });
        }
      } catch (e) {
        AppLogger.data('Failed to create memo: $e', isError: true);
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _onEditMemo(CreatureMemoData memo) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MemoEditBottomSheet(initialContent: memo.content),
    );
    if (result != null && memo.id != null) {
      setState(() => _isLoading = true);
      try {
        final updated = await CreatureMemoService.instance.updateMemo(
          memo.copyWith(content: result),
        );
        if (mounted) {
          setState(() {
            final updatedMemos = _creature.memos.map((m) {
              if (m.id == memo.id) return updated;
              return m;
            }).toList();
            _creature = _creature.copyWith(memos: updatedMemos);
            _isLoading = false;
          });
        }
      } catch (e) {
        AppLogger.data('Failed to update memo: $e', isError: true);
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _onDeleteMemo(CreatureMemoData memo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('메모 삭제'),
        content: const Text('이 메모를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && memo.id != null) {
      setState(() => _isLoading = true);
      try {
        await CreatureMemoService.instance.deleteMemo(memo.id!);
        if (mounted) {
          setState(() {
            final updatedMemos = _creature.memos
                .where((m) => m.id != memo.id)
                .toList();
            _creature = _creature.copyWith(memos: updatedMemos);
            _isLoading = false;
          });
        }
      } catch (e) {
        AppLogger.data('Failed to delete memo: $e', isError: true);
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showMemoOptions(CreatureMemoData memo) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('수정'),
              onTap: () {
                Navigator.pop(context);
                _onEditMemo(memo);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('삭제', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _onDeleteMemo(memo);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      body: Stack(
        children: [
          // 스크롤 가능한 콘텐츠
          CustomScrollView(
            slivers: [
              // 이미지 갤러리
              SliverToBoxAdapter(child: _buildImageGallery()),
              // 정보 섹션
              SliverToBoxAdapter(child: _buildInfoSection()),
            ],
          ),
          // 투명한 앱바
          _buildAppBar(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 뒤로가기 버튼
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              // 수정 버튼
              IconButton(
                onPressed: _onEdit,
                icon: const Icon(
                  Icons.edit_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageGallery() {
    final hasPhotos = _creature.photoUrls.isNotEmpty;
    final photoCount = hasPhotos ? _creature.photoUrls.length : 1;

    return Stack(
      children: [
        // 이미지 슬라이더
        SizedBox(
          height: 336,
          child: hasPhotos
              ? PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                  itemCount: _creature.photoUrls.length,
                  itemBuilder: (context, index) {
                    final photoUrl = _creature.photoUrls[index];
                    return _buildImageItem(photoUrl);
                  },
                )
              : _buildPlaceholderImage(),
        ),
        // 그라데이션 오버레이
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 120,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // 페이지 인디케이터
        if (photoCount > 1)
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${_currentImageIndex + 1} / $photoCount',
                  style: const TextStyle(
                    fontFamily: 'WantedSans',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMain,
                    height: 18 / 12,
                    letterSpacing: -0.25,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImageItem(String photoUrl) {
    // 파일 경로인지 URL인지 확인
    if (photoUrl.startsWith('/') || photoUrl.startsWith('file://')) {
      return Image.file(
        File(photoUrl.replaceFirst('file://', '')),
        fit: BoxFit.cover,
        width: double.infinity,
        height: 336,
      );
    }
    return Image.network(
      photoUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: 336,
      errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 336,
      color: const Color(0xFF3D5A80),
      child: const Center(
        child: Icon(Icons.pets, color: Colors.white, size: 80),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundApp,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      transform: Matrix4.translationValues(0, -24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          // 이름, D+일, 성별
          _buildHeader(),
          const SizedBox(height: 24),
          _buildDivider(),
          const SizedBox(height: 24),
          // 상세 정보
          _buildDetailInfo(),
          const SizedBox(height: 24),
          _buildDivider(),
          const SizedBox(height: 24),
          // 비고/메모
          _buildMemoSection(),
          const SizedBox(height: 100), // 하단 여백
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 이름
          Text(
            _creature.displayName,
            style: const TextStyle(
              fontFamily: 'WantedSans',
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.textMain,
              height: 36 / 24,
              letterSpacing: -0.25,
            ),
          ),
          const SizedBox(width: 8),
          // D+일
          if (_creature.daysDisplayText.isNotEmpty)
            Text(
              _creature.daysDisplayText,
              style: const TextStyle(
                fontFamily: 'WantedSans',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: AppColors.textSubtle,
                height: 24 / 16,
                letterSpacing: -0.5,
              ),
            ),
          const SizedBox(width: 8),
          // 성별 아이콘
          if (_creature.gender != null) _buildGenderIcon(),
        ],
      ),
    );
  }

  Widget _buildGenderIcon() {
    IconData icon;
    Color color;

    switch (_creature.gender) {
      case CreatureGender.male:
        icon = Icons.male;
        color = const Color(0xFF1F99FF);
        break;
      case CreatureGender.female:
        icon = Icons.female;
        color = const Color(0xFFFF6B9D);
        break;
      case CreatureGender.mixed:
        icon = Icons.transgender;
        color = AppColors.textSubtle;
        break;
      default:
        icon = Icons.question_mark;
        color = AppColors.textSubtle;
    }

    return Icon(icon, size: 24, color: color);
  }

  Widget _buildDivider() {
    return Center(
      child: Container(width: 343, height: 1, color: AppColors.borderLight),
    );
  }

  Widget _buildDetailInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildInfoRow('종류', _creature.type),
          const SizedBox(height: 16),
          _buildInfoRow(
            '입양일',
            _creature.adoptionDate != null
                ? '${_creature.adoptionDate!.year}.${_creature.adoptionDate!.month.toString().padLeft(2, '0')}.${_creature.adoptionDate!.day.toString().padLeft(2, '0')}'
                : '-',
          ),
          const SizedBox(height: 16),
          _buildInfoRow('마릿수', '${_creature.quantity}'),
          if (_creature.source != null && _creature.source!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoRow('출처', _creature.source!),
          ],
          if (_creature.price != null && _creature.price!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoRow('분양가', _creature.price!),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'WantedSans',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppColors.textSubtle,
              height: 24 / 16,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'WantedSans',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textMain,
              height: 24 / 16,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMemoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 헤더
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '비고/메모',
                style: TextStyle(
                  fontFamily: 'WantedSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMain,
                  height: 24 / 16,
                  letterSpacing: -0.5,
                ),
              ),
              GestureDetector(
                onTap: _onAddMemo,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Text(
                    '추가',
                    style: TextStyle(
                      fontFamily: 'WantedSans',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.brand,
                      height: 20 / 14,
                      letterSpacing: -0.25,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // 메모 카드들
        if (_creature.memos.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '등록된 메모가 없습니다.',
              style: TextStyle(
                fontFamily: 'WantedSans',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textHint,
                height: 20 / 14,
                letterSpacing: -0.25,
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: _creature.memos
                  .map(
                    (memo) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildMemoCard(memo),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildMemoCard(CreatureMemoData memo) {
    final date = memo.created ?? DateTime.now();
    final dateStr =
        '${date.year}. ${date.month.toString().padLeft(2, '0')}. ${date.day.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 16, right: 2, top: 5, bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 날짜와 더보기 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateStr,
                style: const TextStyle(
                  fontFamily: 'WantedSans',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textHint,
                  height: 18 / 12,
                  letterSpacing: -0.25,
                ),
              ),
              // 더보기 버튼 (90도 회전된 ... 아이콘)
              GestureDetector(
                onTap: () => _showMemoOptions(memo),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: Transform.rotate(
                    angle: 1.5708, // 90도
                    child: const Icon(
                      Icons.more_horiz,
                      size: 24,
                      color: AppColors.textSubtle,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // 메모 내용
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Text(
              memo.content,
              style: const TextStyle(
                fontFamily: 'WantedSans',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSubtle,
                height: 20 / 14,
                letterSpacing: -0.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 메모 편집 바텀시트
class _MemoEditBottomSheet extends StatefulWidget {
  final String? initialContent;

  const _MemoEditBottomSheet({this.initialContent});

  @override
  State<_MemoEditBottomSheet> createState() => _MemoEditBottomSheetState();
}

class _MemoEditBottomSheetState extends State<_MemoEditBottomSheet> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.initialContent == null ? '메모 추가' : '메모 수정',
                style: const TextStyle(
                  fontFamily: 'WantedSans',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                  height: 26 / 18,
                  letterSpacing: -0.5,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: AppColors.textMain),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 텍스트 입력
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: AppColors.backgroundApp,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: TextField(
              controller: _controller,
              maxLines: null,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: '메모를 입력하세요',
                hintStyle: TextStyle(
                  fontFamily: 'WantedSans',
                  fontSize: 14,
                  color: AppColors.textHint,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
                counterText: '',
              ),
              style: const TextStyle(
                fontFamily: 'WantedSans',
                fontSize: 14,
                color: AppColors.textMain,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 저장 버튼
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _controller.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brand,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '저장',
                style: TextStyle(
                  fontFamily: 'WantedSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
