import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../domain/models/record_data.dart';
import '../common/skeleton_loader.dart';

class HomeScheduleSection extends StatelessWidget {
  const HomeScheduleSection({
    super.key,
    required this.recordItems,
    required this.hasAquariums,
    this.isLoading = false,
    this.onAddRecordTap,
    this.onExpandTap,
  });

  final List<RecordData> recordItems;
  final bool hasAquariums;
  final bool isLoading;
  final VoidCallback? onAddRecordTap;
  final VoidCallback? onExpandTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.backgroundApp,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 4, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateHeader(),
            const SizedBox(height: 17),
            if (isLoading)
              const ScheduleSkeleton()
            else if (recordItems.isEmpty || !hasAquariums)
              _buildEmptyTimeline()
            else
              _buildTimelineItems(),
            _buildExpandButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader() {
    final now = DateTime.now();
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[now.weekday - 1];

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${now.day}일 ($weekday)',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              height: 26 / 18,
              letterSpacing: -0.5,
              color: AppColors.textMain,
            ),
          ),
          if (hasAquariums)
            GestureDetector(
              onTap: onAddRecordTap,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.chipPrimaryBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add, color: AppColors.brand, size: 20),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyTimeline() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Text(
            '오늘 기록이 비어있어요',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
          ),
          const SizedBox(height: 4),
          Text(
            '어항을 등록한 후 기록을 추가해 보세요',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItems() {
    return Column(
      children: recordItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isLast = index == recordItems.length - 1;
        return _RecordTimelineItem(item: item, isLast: isLast);
      }).toList(),
    );
  }

  Widget _buildExpandButton() {
    return Center(
      child: GestureDetector(
        onTap: onExpandTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFFDFDFF),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.textHint,
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _RecordTimelineItem extends StatelessWidget {
  const _RecordTimelineItem({required this.item, required this.isLast});

  final RecordData item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final hour = item.date.hour;
    final minute = item.date.minute;
    final amPm = hour < 12 ? '오전' : '오후';
    final displayHour = hour <= 12 ? hour : hour - 12;
    final time = '$displayHour:${minute.toString().padLeft(2, '0')}';

    final tagLabels = item.tags.map((t) => t.label).join(', ');

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 17),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 12,
              child: Column(
                children: [
                  const SizedBox(height: 4),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFB6E4FF),
                      border: Border.all(
                        color: const Color(0xFFD6EEFF),
                        width: 1,
                      ),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 1,
                        margin: const EdgeInsets.only(top: 4),
                        color: const Color(0xFFD6EEFF),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 60,
              child: Row(
                children: [
                  Text(
                    amPm,
                    style: AppTextStyles.captionRegular.copyWith(
                      color: AppColors.textSubtle,
                      fontSize: 12,
                      height: 18 / 12,
                      letterSpacing: -0.25,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    time,
                    style: AppTextStyles.captionRegular.copyWith(
                      color: AppColors.textSubtle,
                      fontSize: 12,
                      height: 18 / 12,
                      letterSpacing: -0.25,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tagLabels.isNotEmpty ? tagLabels : '기록',
                    style: AppTextStyles.bodyMediumMedium.copyWith(
                      color: AppColors.textMain,
                      fontSize: 16,
                      height: 24 / 16,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (item.content.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      item.content,
                      style: AppTextStyles.captionRegular.copyWith(
                        color: AppColors.textHint,
                        fontSize: 12,
                        height: 18 / 12,
                        letterSpacing: -0.25,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}
