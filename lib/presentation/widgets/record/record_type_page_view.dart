import 'package:flutter/material.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_spacing.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';
import '../../viewmodels/record_viewmodel.dart';
import 'todo_tab_content.dart';
import 'activity_tab_content.dart';
import 'diary_tab_content.dart';

/// 할 일 / 기록 / 일기 스와이프 PageView
///
/// PageView로 3개 페이지를 좌우 스와이프하여 전환
/// 하단에 dot indicator + 현재 탭 라벨 표시
class RecordTypePageView extends StatefulWidget {
  final String aquariumId;
  final String? aquariumName;
  final String? creatureId;
  final DateTime selectedDate;
  final RecordViewModel recordViewModel;
  final VoidCallback onDataChanged;
  final bool isLoading;
  final double? height;

  const RecordTypePageView({
    super.key,
    required this.aquariumId,
    this.aquariumName,
    required this.creatureId,
    required this.selectedDate,
    required this.recordViewModel,
    required this.onDataChanged,
    this.isLoading = false,
    this.height,
  });

  @override
  State<RecordTypePageView> createState() => _RecordTypePageViewState();
}

class _RecordTypePageViewState extends State<RecordTypePageView> {
  late PageController _pageController;
  int _currentPage = 0;

  static const _labels = ['할 일', '기록', '일기'];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return SizedBox(
        height: widget.height ?? 320,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final pageView = PageView(
      controller: _pageController,
      onPageChanged: (page) {
        setState(() => _currentPage = page);
      },
      children: [
        SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: TodoTabContent(
            aquariumId: widget.aquariumId,
            aquariumName: widget.aquariumName,
            creatureId: widget.creatureId,
            selectedDate: widget.selectedDate,
            recordViewModel: widget.recordViewModel,
            onDataChanged: widget.onDataChanged,
          ),
        ),
        SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ActivityTabContent(
            aquariumId: widget.aquariumId,
            creatureId: widget.creatureId,
            selectedDate: widget.selectedDate,
            recordViewModel: widget.recordViewModel,
            onDataChanged: widget.onDataChanged,
          ),
        ),
        SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: DiaryTabContent(
            aquariumId: widget.aquariumId,
            creatureId: widget.creatureId,
            selectedDate: widget.selectedDate,
            recordViewModel: widget.recordViewModel,
            onDataChanged: widget.onDataChanged,
          ),
        ),
      ],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // dot indicator + 라벨
        _buildIndicator(),
        const SizedBox(height: AppSpacing.xs),
        // PageView
        SizedBox(
          height: widget.height ?? 320,
          child: pageView,
        ),
      ],
    );
  }

  Widget _buildIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        children: [
          // 현재 탭 라벨
          Text(
            _labels[_currentPage],
            style: AppTextStyles.captionMedium.copyWith(
              color: AppColors.textSubtle,
            ),
          ),
          const SizedBox(height: 6),
          // dot indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              final isActive = _currentPage == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3.0),
                width: isActive ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.brand : AppColors.borderLight,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
