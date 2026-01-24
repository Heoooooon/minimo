import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/models/record_data.dart';
import '../../domain/models/aquarium_data.dart';
import '../../data/services/aquarium_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../viewmodels/record_viewmodel.dart';
import '../widgets/common/app_button.dart';
import '../widgets/record/activity_add_bottom_sheet.dart';

/// 기록 추가 화면
///
/// 새로운 구조:
/// - 전체 어항 목록이 섹션으로 표시
/// - 각 어항 아래 체크리스트 형태로 할 일 표시
/// - + 할 일 추가 버튼으로 태그 추가
class RecordAddScreen extends StatefulWidget {
  final DateTime? initialDate;

  const RecordAddScreen({super.key, this.initialDate});

  @override
  State<RecordAddScreen> createState() => _RecordAddScreenState();
}

class _RecordAddScreenState extends State<RecordAddScreen> {
  DateTime _selectedDate = DateTime.now();

  // 어항 목록
  List<AquariumData> _aquariums = [];
  bool _isLoadingAquariums = true;

  // 어항별 선택된 태그 (체크된 항목)
  // Key: aquariumId, Value: Set of checked RecordTags
  final Map<String, Set<RecordTag>> _checkedTagsByAquarium = {};

  late RecordViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = RecordViewModel();
    if (widget.initialDate != null) {
      _selectedDate = widget.initialDate!;
    }
    _loadAquariums();
  }

  Future<void> _loadAquariums() async {
    try {
      final aquariums = await AquariumService.instance.getAllAquariums();
      if (mounted) {
        setState(() {
          _aquariums = aquariums;
          // 각 어항에 대해 빈 Set 초기화
          for (final aquarium in aquariums) {
            _checkedTagsByAquarium[aquarium.id ?? ''] = {};
          }
          _isLoadingAquariums = false;
        });
      }
    } catch (e) {
      AppLogger.data('Error loading aquariums: $e', isError: true);
      if (mounted) {
        setState(() {
          _isLoadingAquariums = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  /// 저장 가능 여부: 최소 하나의 어항에서 하나 이상의 태그가 체크됨
  bool get _isFormValid {
    return _checkedTagsByAquarium.values.any((tags) => tags.isNotEmpty);
  }

  /// 태그 토글 (체크/언체크)
  void _toggleTag(String aquariumId, RecordTag tag) {
    setState(() {
      final tags = _checkedTagsByAquarium[aquariumId] ?? {};
      if (tags.contains(tag)) {
        tags.remove(tag);
      } else {
        tags.add(tag);
      }
      _checkedTagsByAquarium[aquariumId] = tags;
    });
  }

  /// 할 일 추가 (바텀시트)
  Future<void> _showAddActivitySheet(String aquariumId) async {
    final selectedTags = await ActivityAddBottomSheet.show(
      context,
      selectedDate: _selectedDate,
    );

    if (selectedTags != null && selectedTags.isNotEmpty && mounted) {
      setState(() {
        final currentTags = _checkedTagsByAquarium[aquariumId] ?? {};
        currentTags.addAll(selectedTags);
        _checkedTagsByAquarium[aquariumId] = currentTags;
      });
    }
  }

  /// 저장 처리
  Future<void> _handleSave() async {
    if (!_isFormValid) return;

    bool allSuccess = true;
    int savedCount = 0;

    // 각 어항별로 체크된 태그가 있으면 기록 저장
    for (final aquarium in _aquariums) {
      final aquariumId = aquarium.id ?? '';
      final tags = _checkedTagsByAquarium[aquariumId] ?? {};

      if (tags.isNotEmpty) {
        final success = await _viewModel.saveRecord(
          date: _selectedDate,
          tags: tags.toList(),
          content: '', // 체크리스트 방식에서는 내용 생략
          isPublic: false,
          aquariumId: aquariumId,
        );

        if (success) {
          savedCount++;
        } else {
          allSuccess = false;
        }
      }
    }

    if (mounted) {
      if (savedCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$savedCount개의 기록이 저장되었습니다.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textInverse,
              ),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        Navigator.of(context).pop(true);
      } else if (!allSuccess && _viewModel.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_viewModel.errorMessage!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.brand,
              onPrimary: AppColors.textInverse,
              surface: AppColors.backgroundSurface,
              onSurface: AppColors.textMain,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<RecordViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            backgroundColor: AppColors.backgroundApp,
            appBar: AppBar(
              title: const Text('기록하기'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 날짜 선택
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: _buildDateSelector(),
                          ),

                          // 어항별 체크리스트
                          if (_isLoadingAquariums)
                            _buildLoadingState()
                          else if (_aquariums.isEmpty)
                            _buildEmptyState()
                          else
                            _buildAquariumSections(),
                        ],
                      ),
                    ),
                  ),

                  // 하단 버튼
                  _buildBottomButton(viewModel),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateSelector() {
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[_selectedDate.weekday - 1];

    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.chipPrimaryBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.calendar_today_rounded,
                color: AppColors.brand,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '기록 날짜',
                    style: AppTextStyles.captionRegular.copyWith(
                      color: AppColors.textSubtle,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_selectedDate.month}월 ${_selectedDate.day}일 ($weekday)',
                    style: AppTextStyles.bodyMediumMedium,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSubtle),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.water_drop_outlined,
              size: 48,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              '등록된 어항이 없어요',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSubtle,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/aquarium/register');
              },
              child: Text(
                '어항 등록하기',
                style: AppTextStyles.bodyMediumMedium.copyWith(
                  color: AppColors.brand,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAquariumSections() {
    return Column(
      children: _aquariums.map((aquarium) {
        return _buildAquariumSection(aquarium);
      }).toList(),
    );
  }

  Widget _buildAquariumSection(AquariumData aquarium) {
    final aquariumId = aquarium.id ?? '';
    final checkedTags = _checkedTagsByAquarium[aquariumId] ?? {};

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 어항 이름 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.chipPrimaryBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.water_drop,
                    color: AppColors.brand,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    aquarium.name ?? '이름 없음',
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // 체크된 항목 수 표시
                if (checkedTags.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.brand.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${checkedTags.length}개 선택',
                      style: AppTextStyles.captionMedium.copyWith(
                        color: AppColors.brand,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.borderLight),

          // 체크리스트 아이템들
          if (checkedTags.isEmpty)
            _buildEmptyChecklist(aquariumId)
          else
            ...checkedTags.map((tag) => _buildChecklistItem(aquariumId, tag)),

          // + 할 일 추가 버튼
          _buildAddButton(aquariumId),
        ],
      ),
    );
  }

  Widget _buildEmptyChecklist(String aquariumId) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Center(
        child: Text(
          '할 일을 추가해주세요',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
        ),
      ),
    );
  }

  Widget _buildChecklistItem(String aquariumId, RecordTag tag) {
    return InkWell(
      onTap: () => _toggleTag(aquariumId, tag),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // 체크박스
            _buildCheckbox(true),
            const SizedBox(width: 12),
            // 태그 라벨
            Expanded(
              child: Text(
                tag.label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textMain,
                ),
              ),
            ),
            // 삭제 버튼 (X)
            GestureDetector(
              onTap: () => _toggleTag(aquariumId, tag),
              child: const Icon(
                Icons.close,
                size: 18,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckbox(bool isChecked) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: isChecked ? AppColors.brand : Colors.transparent,
        border: isChecked
            ? null
            : Border.all(color: AppColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: isChecked
          ? const Icon(Icons.check, color: Colors.white, size: 14)
          : null,
    );
  }

  Widget _buildAddButton(String aquariumId) {
    return InkWell(
      onTap: () => _showAddActivitySheet(aquariumId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.borderLight)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, size: 18, color: AppColors.brand),
            const SizedBox(width: 8),
            Text(
              '할 일 추가',
              style: AppTextStyles.bodyMediumMedium.copyWith(
                color: AppColors.brand,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton(RecordViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 8,
          ),
        ],
      ),
      child: AppButton(
        text: '저장하기',
        onPressed: _isFormValid ? _handleSave : null,
        size: AppButtonSize.large,
        shape: AppButtonShape.round,
        variant: AppButtonVariant.contained,
        isEnabled: _isFormValid,
        isLoading: viewModel.isLoading,
      ),
    );
  }
}
