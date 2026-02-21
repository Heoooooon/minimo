import 'package:flutter/material.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/services/creature_service.dart';
import '../../../domain/models/creature_data.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';
import '../../screens/creature/creature_register_screen.dart';
import '../../screens/creature/creature_search_screen.dart';

/// 어항 등록 후 생물 등록 안내 위젯
///
/// 어항에 등록된 생물 목록을 보여주고, 새 생물 추가 버튼을 제공합니다.
class RegisterStepCreature extends StatefulWidget {
  final String? aquariumId;

  const RegisterStepCreature({super.key, this.aquariumId});

  @override
  State<RegisterStepCreature> createState() => _RegisterStepCreatureState();
}

class _RegisterStepCreatureState extends State<RegisterStepCreature> {
  List<CreatureData> _creatures = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.aquariumId != null) {
      _loadCreatures();
    }
  }

  Future<void> _loadCreatures() async {
    if (widget.aquariumId == null) return;
    setState(() => _isLoading = true);
    try {
      final creatures = await CreatureService.instance
          .getCreaturesByAquarium(widget.aquariumId!);
      if (mounted) {
        setState(() {
          _creatures = creatures;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.data('생물 목록 로드 실패: $e', isError: true);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onAddCreature() async {
    // 생물 검색 화면으로 이동
    final searchResult = await Navigator.push<CreatureSearchItem>(
      context,
      MaterialPageRoute(builder: (context) => const CreatureSearchScreen()),
    );

    if (searchResult != null && mounted) {
      // 선택된 생물로 등록 화면 이동
      final result = await Navigator.push<CreatureData>(
        context,
        MaterialPageRoute(
          builder: (context) => CreatureRegisterScreen(
            aquariumId: widget.aquariumId,
            selectedCreature: searchResult,
          ),
        ),
      );

      if (result != null && mounted) {
        _loadCreatures();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '함께 살고 있는\n생물을 등록해 주세요.',
            style: AppTextStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '나중에 등록할 수도 있어요.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSubtle,
            ),
          ),
          const SizedBox(height: 40),

          // 생물 추가 버튼
          _buildAddButton(),
          const SizedBox(height: 16),

          // 로딩 표시
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),

          // 등록된 생물 목록
          ..._creatures.map((creature) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildCreatureCard(creature),
              )),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: widget.aquariumId != null ? _onAddCreature : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.backgroundSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.chipPrimaryBg,
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.add_circle_outline, color: AppColors.brand, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              '생물 추가하기',
              style: AppTextStyles.bodyMediumBold.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '어항에 살고 있는 물고기, 새우 등을 추가해 보세요',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSubtle,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreatureCard(CreatureData creature) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.chipPrimaryBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: creature.photoUrls.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      creature.photoUrls.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.pets, color: AppColors.brand, size: 24),
                    ),
                  )
                : const Icon(Icons.pets, color: AppColors.brand, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  creature.nickname ?? creature.name,
                  style: AppTextStyles.bodyMediumBold.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${creature.type} · ${creature.quantity}마리',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSubtle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
