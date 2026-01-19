import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../data/services/creature_service.dart';
import '../../../domain/models/creature_data.dart' as domain;
import '../../../theme/app_colors.dart';
import '../../widgets/common/date_picker_bottom_sheet.dart';
import 'creature_search_screen.dart';

/// 성별 열거형
enum CreatureGender {
  female('암'),
  male('수'),
  mixed('혼합'),
  unknown('미상');

  final String label;
  const CreatureGender(this.label);
}

/// 생물 등록/수정 화면
///
/// Figma 디자인 기반 - 내 생물 등록/수정
class CreatureRegisterScreen extends StatefulWidget {
  final String? aquariumId;
  final String? creatureName;
  final String? creatureType;
  final CreatureSearchItem? selectedCreature;
  final domain.CreatureData? existingCreature; // 수정 모드용

  const CreatureRegisterScreen({
    super.key,
    this.aquariumId,
    this.creatureName,
    this.creatureType,
    this.selectedCreature,
    this.existingCreature,
  });

  /// 수정 모드인지 여부
  bool get isEditMode => existingCreature != null;

  @override
  State<CreatureRegisterScreen> createState() => _CreatureRegisterScreenState();
}

class _CreatureRegisterScreenState extends State<CreatureRegisterScreen> {
  // 선택된 생물 정보
  CreatureSearchItem? _selectedCreature;

  // 필수 입력 필드
  DateTime? _adoptionDate;
  bool _unknownAdoptionDate = false;
  int _quantity = 1;

  // 선택 입력 필드
  final TextEditingController _nameController = TextEditingController();
  CreatureGender? _selectedGender;
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final List<File> _photos = [];
  final TextEditingController _notesController = TextEditingController();

  // 저장 중 상태
  bool _isSaving = false;

  // 최대 사진 개수
  static const int _maxPhotos = 5;

  @override
  void initState() {
    super.initState();

    // 수정 모드인 경우 기존 데이터로 초기화
    if (widget.existingCreature != null) {
      final creature = widget.existingCreature!;
      _selectedCreature = CreatureSearchItem(
        id: creature.catalogId ?? 'existing',
        name: creature.name,
        category: creature.type,
      );
      _adoptionDate = creature.adoptionDate;
      _unknownAdoptionDate = creature.unknownAdoptionDate;
      _quantity = creature.quantity;
      _nameController.text = creature.nickname ?? '';
      _selectedGender = _convertDomainGender(creature.gender);
      _sourceController.text = creature.source ?? '';
      _priceController.text = creature.price ?? '';
      // 기존 사진은 URL로만 표시 (수정 시 새 사진 추가 가능)
    } else if (widget.selectedCreature != null) {
      // 전달받은 생물 정보로 초기화
      _selectedCreature = widget.selectedCreature;
    } else if (widget.creatureName != null) {
      _selectedCreature = CreatureSearchItem(
        id: 'new',
        name: widget.creatureName!,
        category: widget.creatureType ?? '미분류',
      );
    }
  }

  /// domain.CreatureGender를 로컬 CreatureGender로 변환
  CreatureGender? _convertDomainGender(domain.CreatureGender? gender) {
    if (gender == null) return null;
    switch (gender) {
      case domain.CreatureGender.male:
        return CreatureGender.male;
      case domain.CreatureGender.female:
        return CreatureGender.female;
      case domain.CreatureGender.mixed:
        return CreatureGender.mixed;
      case domain.CreatureGender.unknown:
        return CreatureGender.unknown;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sourceController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    // 수정 모드인 경우 기존 어항 ID 사용
    final aquariumId = widget.isEditMode
        ? widget.existingCreature!.aquariumId
        : widget.aquariumId;
    // 필수 항목 체크: 어항 ID + 생물 선택 + (입양일 또는 모름 체크) + 마릿수
    final hasAquarium = aquariumId != null;
    final hasCreature = _selectedCreature != null;
    final hasAdoptionInfo = _adoptionDate != null || _unknownAdoptionDate;
    final hasQuantity = _quantity > 0;
    return hasAquarium && hasCreature && hasAdoptionInfo && hasQuantity;
  }

  void _onChangeCreature() async {
    final result = await Navigator.push<CreatureSearchItem>(
      context,
      MaterialPageRoute(
        builder: (context) => const CreatureSearchScreen(),
      ),
    );
    if (result != null) {
      setState(() {
        _selectedCreature = result;
      });
    }
  }

  void _onSelectDate() async {
    final result = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DatePickerBottomSheet(
        initialDate: _adoptionDate ?? DateTime.now(),
        title: '입양일 선택',
      ),
    );
    if (result != null) {
      setState(() {
        _adoptionDate = result;
        _unknownAdoptionDate = false;
      });
    }
  }

  void _onToggleUnknownDate(bool? value) {
    setState(() {
      _unknownAdoptionDate = value ?? false;
      if (_unknownAdoptionDate) {
        _adoptionDate = null;
      }
    });
  }

  void _onIncreaseQuantity() {
    setState(() {
      _quantity++;
    });
  }

  void _onDecreaseQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  void _onSelectGender(CreatureGender gender) {
    setState(() {
      _selectedGender = gender;
    });
  }

  Future<void> _onAddPhoto() async {
    if (_photos.length >= _maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('최대 5장까지 첨부 가능합니다.')),
      );
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _photos.add(File(pickedFile.path));
      });
    }
  }

  void _onRemovePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  Future<void> _onSave() async {
    if (!_isFormValid || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      // 성별 변환
      domain.CreatureGender? domainGender;
      if (_selectedGender != null) {
        switch (_selectedGender!) {
          case CreatureGender.male:
            domainGender = domain.CreatureGender.male;
            break;
          case CreatureGender.female:
            domainGender = domain.CreatureGender.female;
            break;
          case CreatureGender.mixed:
            domainGender = domain.CreatureGender.mixed;
            break;
          case CreatureGender.unknown:
            domainGender = domain.CreatureGender.unknown;
            break;
        }
      }

      // 어항 ID 결정
      final aquariumId = widget.isEditMode
          ? widget.existingCreature!.aquariumId
          : widget.aquariumId!;

      // CreatureData 생성
      final creature = domain.CreatureData(
        id: widget.existingCreature?.id, // 수정 모드일 때 기존 ID 유지
        aquariumId: aquariumId,
        catalogId: widget.existingCreature?.catalogId,
        name: _selectedCreature!.name,
        type: _selectedCreature!.category,
        nickname: _nameController.text.isNotEmpty ? _nameController.text : null,
        adoptionDate: _adoptionDate,
        unknownAdoptionDate: _unknownAdoptionDate,
        quantity: _quantity,
        gender: domainGender,
        source: _sourceController.text.isNotEmpty ? _sourceController.text : null,
        price: _priceController.text.isNotEmpty ? _priceController.text : null,
        photoUrls: widget.existingCreature?.photoUrls ?? [],
        photoFiles: _photos.map((f) => f.path).toList(),
        memos: widget.existingCreature?.memos ?? [],
      );

      // 저장 또는 업데이트
      domain.CreatureData result;
      if (widget.isEditMode) {
        result = await CreatureService.instance.updateCreature(creature);
      } else {
        result = await CreatureService.instance.createCreature(creature);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditMode ? '생물 정보가 수정되었습니다.' : '생물이 등록되었습니다.'),
          ),
        );
        Navigator.pop(context, result); // 수정된 데이터 반환
      }
    } catch (e) {
      debugPrint('Failed to save creature: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장에 실패했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 선택된 생물 정보
                  _buildCreatureInfo(),
                  const SizedBox(height: 8),
                  // 입력 폼
                  _buildForm(),
                ],
              ),
            ),
          ),
          // 저장 버튼
          _buildBottomButton(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.backgroundApp,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(
          Icons.arrow_back_ios,
          color: AppColors.textMain,
          size: 24,
        ),
      ),
      title: Text(
        widget.isEditMode ? '생물 정보 수정' : '내 생물 등록',
        style: const TextStyle(
          fontFamily: 'WantedSans',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textMain,
          height: 26 / 18,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildCreatureInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight),
        ),
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
            child: const Icon(
              Icons.pets,
              color: AppColors.brand,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          // 생물 이름
          Text(
            _selectedCreature?.name ?? '생물 선택',
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
            _selectedCreature?.category ?? '',
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
            onTap: _onChangeCreature,
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

  Widget _buildForm() {
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
          onTap: _unknownAdoptionDate ? null : _onSelectDate,
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
                  _adoptionDate != null
                      ? '${_adoptionDate!.year}.${_adoptionDate!.month.toString().padLeft(2, '0')}.${_adoptionDate!.day.toString().padLeft(2, '0')}'
                      : 'YYYY.MM.DD',
                  style: TextStyle(
                    fontFamily: 'WantedSans',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _adoptionDate != null
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
                value: _unknownAdoptionDate,
                onChanged: _onToggleUnknownDate,
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
              onTap: _onDecreaseQuantity,
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
                  color: _quantity > 1 ? AppColors.textMain : AppColors.textHint,
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
                '$_quantity',
                style: TextStyle(
                  fontFamily: 'WantedSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _quantity > 0 ? AppColors.textMain : AppColors.textHint,
                  height: 24 / 16,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            // 플러스 버튼
            GestureDetector(
              onTap: _onIncreaseQuantity,
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
        _buildTextField(
          controller: _nameController,
          hintText: 'Text',
        ),
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
            final isSelected = _selectedGender == gender;
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () => _onSelectGender(gender),
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
                            color: isSelected ? AppColors.brand : AppColors.border,
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
                        color: isSelected ? AppColors.textMain : AppColors.textSubtle,
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
        _buildTextField(
          controller: _sourceController,
          hintText: 'Text',
        ),
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
          controller: _priceController,
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
                onTap: _onAddPhoto,
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
              ..._photos.asMap().entries.map((entry) {
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
                          onTap: () => _onRemovePhoto(entry.key),
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
              color: _notesController.text.isNotEmpty
                  ? AppColors.brand
                  : AppColors.borderLight,
            ),
          ),
          child: Stack(
            children: [
              TextField(
                controller: _notesController,
                maxLines: null,
                maxLength: 300,
                onChanged: (_) => setState(() {}),
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
                  '${_notesController.text.length}/300',
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
        onChanged: (_) => setState(() {}),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 24, color: AppColors.textHint),
                  onPressed: () {
                    controller.clear();
                    setState(() {});
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

  Widget _buildBottomButton() {
    final isEnabled = _isFormValid && !_isSaving;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            AppColors.backgroundApp,
            AppColors.backgroundApp.withValues(alpha: 0),
          ],
          stops: const [0.36, 1.0],
        ),
      ),
      child: SafeArea(
        child: GestureDetector(
          onTap: isEnabled ? _onSave : null,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: isEnabled ? AppColors.brand : AppColors.backgroundDisabled,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: _isSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    '저장하기',
                    style: TextStyle(
                      fontFamily: 'WantedSans',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isEnabled ? AppColors.backgroundApp : AppColors.disabledText,
                      height: 24 / 16,
                      letterSpacing: -0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
