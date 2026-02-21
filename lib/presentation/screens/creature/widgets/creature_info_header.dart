import 'package:flutter/material.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import '../creature_search_screen.dart';

/// 선택된 생물 정보 헤더
class CreatureInfoHeader extends StatelessWidget {
  final CreatureSearchItem? selectedCreature;
  final VoidCallback onChangeCreature;

  const CreatureInfoHeader({
    super.key,
    required this.selectedCreature,
    required this.onChangeCreature,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        children: [
          // 생물 이미지
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFD6EEFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.pets, color: AppColors.brand, size: 20),
          ),
          const SizedBox(width: 8),
          // 생물 이름
          Text(
            selectedCreature?.name ?? '생물 선택',
            style: const TextStyle(
              fontFamily: 'WantedSans',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textMain,
              height: 24 / 16,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(width: 8),
          // 생물 종류
          Text(
            selectedCreature?.category ?? '',
            style: const TextStyle(
              fontFamily: 'WantedSans',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textHint,
              height: 20 / 14,
              letterSpacing: -0.25,
            ),
          ),
          const Spacer(),
          // 변경 버튼
          GestureDetector(
            onTap: onChangeCreature,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Text(
                '변경',
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
    );
  }
}
