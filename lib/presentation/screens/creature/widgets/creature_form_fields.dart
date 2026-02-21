import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cmore_design_system/theme/app_colors.dart';
import '../creature_register_screen.dart';

/// 생물 등록 폼 필드들
class CreatureFormFields extends StatelessWidget {
  final DateTime? adoptionDate;
  final bool unknownAdoptionDate;
  final int quantity;
  final TextEditingController nameController;
  final CreatureGender? selectedGender;
  final TextEditingController sourceController;
  final TextEditingController priceController;
  final List<File> photos;
  final TextEditingController notesController;
  final int maxPhotos;
  final VoidCallback onSelectDate;
  final ValueChanged<bool?> onToggleUnknownDate;
  final VoidCallback onIncreaseQuantity;
  final VoidCallback onDecreaseQuantity;
  final ValueChanged<CreatureGender> onSelectGender;
  final VoidCallback onAddPhoto;
  final ValueChanged<int> onRemovePhoto;
  final VoidCallback onChanged;

  const CreatureFormFields({
    super.key,
    required this.adoptionDate,
    required this.unknownAdoptionDate,
    required this.quantity,
    required this.nameController,
    required this.selectedGender,
    required this.sourceController,
    required this.priceController,
    required this.photos,
    required this.notesController,
    required this.maxPhotos,
    required this.onSelectDate,
    required this.onToggleUnknownDate,
    required this.onIncreaseQuantity,
    required this.onDecreaseQuantity,
    required this.onSelectGender,
    required this.onAddPhoto,
    required this.onRemovePhoto,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 입양일 (필수)
          _buildAdoptionDateField(),
          const SizedBox(height: 24),
          // 마릿수 (필수)
          _buildQuantityField(),
          const SizedBox(height: 24),
          // 이름 (선택)
          _buildNameField(),
          const SizedBox(height: 24),
          // 성별 (선택)
          _buildGenderField(),
          const SizedBox(height: 24),
          // 출처 (선택)
          _buildSourceField(),
          const SizedBox(height: 24),
          // 가격 (선택)
          _buildPriceField(),
          const SizedBox(height: 24),
          // 사진 (선택)
          _buildPhotoField(),
          const SizedBox(height: 24),
          // 비고 (선택)
          _buildNotesField(),
          const SizedBox(height: 120), // 하단 버튼 공간
        ],
      ),
    );
  }

  Widget _buildAdoptionDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 라벨
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontFamily: 'WantedSans',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSubtle,
              height: 20 / 14,
              letterSpacing: -0.25,
            ),
            children: [
              TextSpan(text: '입양일 '),
              TextSpan(
                text: '(필수)',
                style: TextStyle(color: AppColors.brand),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // 날짜 선택 버튼
        GestureDetector(
          onTap: unknownAdoptionDate ? null : onSelectDate,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  adoptionDate != null
                      ? '${adoptionDate!.year}.${adoptionDate!.month.toString().padLeft(2, '0')}.${adoptionDate!.day.toString().padLeft(2, '0')}'
                      : 'YYYY.MM.DD',
                  style: TextStyle(
                    fontFamily: 'WantedSans',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: adoptionDate != null
                        ? AppColors.textMain
                        : AppColors.textHint,
                    height: 20 / 14,
                    letterSpacing: -0.25,
                  ),
                ),
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 24,
                  color: AppColors.textMain,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // 입양일 모름 체크박스
        Row(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: Checkbox(
                value: unknownAdoptionDate,
                onChanged: onToggleUnknownDate,
                activeColor: AppColors.brand,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                side: const BorderSide(color: AppColors.border),
              ),
            ),
            const Text(
              '입양일 모름',
              style: TextStyle(
                fontFamily: 'WantedSans',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSubtle,
                height: 20 / 14,
                letterSpacing: -0.25,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuantityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 라벨
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontFamily: 'WantedSans',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSubtle,
              height: 20 / 14,
              letterSpacing: -0.25,
            ),
            children: [
              TextSpan(text: '마릿수 '),
              TextSpan(
                text: '(필수)',
                style: TextStyle(color: AppColors.brand),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // 숫자 피커
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 마이너스 버튼
            GestureDetector(
              onTap: onDecreaseQuantity,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.remove,
                  size: 24,
                  color: quantity > 1
                      ? AppColors.textMain
                      : AppColors.textHint,
                ),
              ),
            ),
            // 숫자 표시
            Container(
              width: 200,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              alignment: Alignment.center,
              child: Text(
                '$quantity',
                style: TextStyle(
                  fontFamily: 'WantedSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: quantity > 0
                      ? AppColors.textMain
                      : AppColors.textHint,
                  height: 24 / 16,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            // 플러스 버튼
            GestureDetector(
              onTap: onIncreaseQuantity,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.add,
                  size: 24,
                  color: AppColors.textMain,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '이름',
          style: TextStyle(
            fontFamily: 'WantedSans',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSubtle,
            height: 20 / 14,
            letterSpacing: -0.25,
          ),
        ),
        const SizedBox(height: 12),
        _buildTextField(controller: nameController, hintText: 'Text'),
      ],
    );
  }

  Widget _buildGenderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '성별',
          style: TextStyle(
            fontFamily: 'WantedSans',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSubtle,
            height: 20 / 14,
            letterSpacing: -0.25,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: CreatureGender.values.map((gender) {
            final isSelected = selectedGender == gender;
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () => onSelectGender(gender),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.brand
                                : AppColors.border,
                            width: isSelected ? 6 : 1,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      gender.label,
                      style: TextStyle(
                        fontFamily: 'WantedSans',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? AppColors.textMain
                            : AppColors.textSubtle,
                        height: 24 / 16,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSourceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '출처',
          style: TextStyle(
            fontFamily: 'WantedSans',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSubtle,
            height: 20 / 14,
            letterSpacing: -0.25,
          ),
        ),
        const SizedBox(height: 12),
        _buildTextField(controller: sourceController, hintText: 'Text'),
      ],
    );
  }

  Widget _buildPriceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '가격',
          style: TextStyle(
            fontFamily: 'WantedSans',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSubtle,
            height: 20 / 14,
            letterSpacing: -0.25,
          ),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: priceController,
          hintText: 'Text',
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildPhotoField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '사진 (최대 5장 첨부 가능)',
          style: TextStyle(
            fontFamily: 'WantedSans',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSubtle,
            height: 20 / 14,
            letterSpacing: -0.25,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 109,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // 사진 추가 버튼
              GestureDetector(
                onTap: onAddPhoto,
                child: Container(
                  width: 109,
                  height: 109,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundDisabled,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    size: 24,
                    color: AppColors.textHint,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 추가된 사진들
              ...photos.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      Container(
                        width: 109,
                        height: 109,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          image: DecorationImage(
                            image: FileImage(entry.value),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => onRemovePhoto(entry.key),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '비고',
          style: TextStyle(
            fontFamily: 'WantedSans',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSubtle,
            height: 20 / 14,
            letterSpacing: -0.25,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 227,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notesController.text.isNotEmpty
                  ? AppColors.brand
                  : AppColors.borderLight,
            ),
          ),
          child: Stack(
            children: [
              TextField(
                controller: notesController,
                maxLines: null,
                maxLength: 300,
                onChanged: (_) => onChanged(),
                decoration: const InputDecoration(
                  hintText: 'Text',
                  hintStyle: TextStyle(
                    fontFamily: 'WantedSans',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textHint,
                    height: 24 / 16,
                    letterSpacing: -0.5,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                  counterText: '',
                ),
                style: const TextStyle(
                  fontFamily: 'WantedSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMain,
                  height: 24 / 16,
                  letterSpacing: -0.5,
                ),
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: Text(
                  '${notesController.text.length}/300',
                  style: const TextStyle(
                    fontFamily: 'WantedSans',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textHint,
                    height: 20 / 14,
                    letterSpacing: -0.25,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: (_) => onChanged(),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontFamily: 'WantedSans',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textHint,
            height: 20 / 14,
            letterSpacing: -0.25,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 24,
                    color: AppColors.textHint,
                  ),
                  onPressed: () {
                    controller.clear();
                    onChanged();
                  },
                )
              : null,
        ),
        style: const TextStyle(
          fontFamily: 'WantedSans',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textMain,
          height: 20 / 14,
          letterSpacing: -0.25,
        ),
      ),
    );
  }
}
