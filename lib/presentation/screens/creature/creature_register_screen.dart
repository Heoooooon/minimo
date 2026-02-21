import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/utils/app_logger.dart';
import '../../../data/services/creature_service.dart';
import '../../../domain/models/creature_data.dart' as domain;
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/widgets/date_picker_bottom_sheet.dart';
import 'creature_search_screen.dart';
import 'widgets/creature_info_header.dart';
import 'widgets/creature_form_fields.dart';
import 'widgets/creature_bottom_button.dart';

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
    } else if (widget.selectedCreature != null) {
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
    final aquariumId = widget.isEditMode
        ? widget.existingCreature!.aquariumId
        : widget.aquariumId;
    final hasAquarium = aquariumId != null;
    final hasCreature = _selectedCreature != null;
    final hasAdoptionInfo = _adoptionDate != null || _unknownAdoptionDate;
    final hasQuantity = _quantity > 0;
    return hasAquarium && hasCreature && hasAdoptionInfo && hasQuantity;
  }

  void _onChangeCreature() async {
    final result = await Navigator.push<CreatureSearchItem>(
      context,
      MaterialPageRoute(builder: (context) => const CreatureSearchScreen()),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('최대 5장까지 첨부 가능합니다.')));
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
        id: widget.existingCreature?.id,
        aquariumId: aquariumId,
        catalogId: widget.existingCreature?.catalogId,
        name: _selectedCreature!.name,
        type: _selectedCreature!.category,
        nickname: _nameController.text.isNotEmpty ? _nameController.text : null,
        adoptionDate: _adoptionDate,
        unknownAdoptionDate: _unknownAdoptionDate,
        quantity: _quantity,
        gender: domainGender,
        source: _sourceController.text.isNotEmpty
            ? _sourceController.text
            : null,
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
            content: Text(
              widget.isEditMode ? '생물 정보가 수정되었습니다.' : '생물이 등록되었습니다.',
            ),
          ),
        );
        Navigator.pop(context, result);
      }
    } catch (e) {
      AppLogger.data('Failed to save creature: $e', isError: true);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('저장에 실패했습니다: $e')));
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
      appBar: AppBar(
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
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 선택된 생물 정보
                  CreatureInfoHeader(
                    selectedCreature: _selectedCreature,
                    onChangeCreature: _onChangeCreature,
                  ),
                  const SizedBox(height: 8),
                  // 입력 폼
                  CreatureFormFields(
                    adoptionDate: _adoptionDate,
                    unknownAdoptionDate: _unknownAdoptionDate,
                    quantity: _quantity,
                    nameController: _nameController,
                    selectedGender: _selectedGender,
                    sourceController: _sourceController,
                    priceController: _priceController,
                    photos: _photos,
                    notesController: _notesController,
                    maxPhotos: _maxPhotos,
                    onSelectDate: _onSelectDate,
                    onToggleUnknownDate: _onToggleUnknownDate,
                    onIncreaseQuantity: _onIncreaseQuantity,
                    onDecreaseQuantity: _onDecreaseQuantity,
                    onSelectGender: _onSelectGender,
                    onAddPhoto: _onAddPhoto,
                    onRemovePhoto: _onRemovePhoto,
                    onChanged: () => setState(() {}),
                  ),
                ],
              ),
            ),
          ),
          // 저장 버튼
          CreatureBottomButton(
            isEnabled: _isFormValid,
            isSaving: _isSaving,
            onSave: _onSave,
          ),
        ],
      ),
    );
  }
}
