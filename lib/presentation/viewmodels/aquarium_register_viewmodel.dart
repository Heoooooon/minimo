import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/repositories/aquarium_repository.dart';
import '../../domain/models/aquarium_data.dart';

/// 어항 등록 ViewModel
///
/// 4단계 어항 등록 플로우의 상태를 관리합니다.
/// - Step 1: 기본 정보 (이름, 유형, 세팅일자, 치수)
/// - Step 2: 장비 등록 (여과기, 바닥재, 제품명, 조명, 히터)
/// - Step 3: 추가 정보 (목적, 비고)
/// - Step 4: 대표 사진 등록
class AquariumRegisterViewModel extends ChangeNotifier {
  AquariumRegisterViewModel();

  /// 현재 단계 (1-4)
  int _currentStep = 1;
  int get currentStep => _currentStep;

  /// 전체 단계 수
  static const int totalSteps = 4;

  /// 어항 데이터
  AquariumData _data = AquariumData();
  AquariumData get data => _data;

  /// 로딩 상태
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// 에러 메시지
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// ImagePicker 인스턴스
  final ImagePicker _picker = ImagePicker();

  /// Repository
  final AquariumRepository _repository = AquariumRepository.instance;

  // ==================== Step Navigation ====================

  /// 다음 단계로 이동
  void nextStep() {
    if (_currentStep < totalSteps && canProceed) {
      _currentStep++;
      notifyListeners();
    }
  }

  /// 이전 단계로 이동
  void previousStep() {
    if (_currentStep > 1) {
      _currentStep--;
      notifyListeners();
    }
  }

  /// 특정 단계로 이동
  void goToStep(int step) {
    if (step >= 1 && step <= totalSteps) {
      _currentStep = step;
      notifyListeners();
    }
  }

  /// 현재 단계에서 다음으로 진행 가능 여부
  bool get canProceed {
    switch (_currentStep) {
      case 1:
        return _data.isStep1Valid;
      case 2:
        return _data.isStep2Valid;
      case 3:
        return _data.isStep3Valid;
      case 4:
        return _data.isStep4Valid;
      default:
        return false;
    }
  }

  /// 마지막 단계인지 확인
  bool get isLastStep => _currentStep == totalSteps;

  /// 첫 번째 단계인지 확인
  bool get isFirstStep => _currentStep == 1;

  // ==================== Step 1: 기본 정보 ====================

  /// 어항 이름 설정
  void setName(String value) {
    _data = _data.copyWith(name: value.isEmpty ? null : value);
    notifyListeners();
  }

  /// 어항 유형 설정
  void setType(AquariumType type) {
    _data = _data.copyWith(type: type);
    notifyListeners();
  }

  /// 어항 세팅 일자 설정
  void setSettingDate(DateTime date) {
    _data = _data.copyWith(settingDate: date);
    notifyListeners();
  }

  /// 어항 치수 설정
  void setDimensions(String value) {
    _data = _data.copyWith(dimensions: value.isEmpty ? null : value);
    notifyListeners();
  }

  // ==================== Step 2: 장비 등록 ====================

  /// 여과기 종류 설정
  void setFilterType(FilterType? type) {
    _data = _data.copyWith(filterType: type);
    notifyListeners();
  }

  /// 바닥재 설정
  void setSubstrate(String value) {
    _data = _data.copyWith(substrate: value.isEmpty ? null : value);
    notifyListeners();
  }

  /// 제품명 설정
  void setProductName(String value) {
    _data = _data.copyWith(productName: value.isEmpty ? null : value);
    notifyListeners();
  }

  /// 조명 종류 설정
  void setLighting(LightingType? type) {
    _data = _data.copyWith(lighting: type);
    notifyListeners();
  }

  /// 히터 유무 설정
  void setHasHeater(bool value) {
    _data = _data.copyWith(hasHeater: value);
    notifyListeners();
  }

  // ==================== Step 3: 추가 정보 ====================

  /// 사육 목적 설정
  void setPurpose(AquariumPurpose? purpose) {
    _data = _data.copyWith(purpose: purpose);
    notifyListeners();
  }

  /// 비고 설정
  void setNotes(String value) {
    _data = _data.copyWith(notes: value.isEmpty ? null : value);
    notifyListeners();
  }

  // ==================== Step 4: 대표 사진 ====================

  /// 갤러리에서 사진 선택
  Future<void> pickPhotoFromGallery() async {
    try {
      _isLoading = true;
      notifyListeners();

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        _data = _data.copyWith(photoPath: image.path);
      }
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      _errorMessage = '이미지를 선택하는 중 오류가 발생했습니다.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 카메라로 사진 촬영
  Future<void> takePhoto() async {
    try {
      _isLoading = true;
      notifyListeners();

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        _data = _data.copyWith(photoPath: image.path);
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
      _errorMessage = '카메라를 사용하는 중 오류가 발생했습니다.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 사진 제거
  void removePhoto() {
    _data = AquariumData(
      id: _data.id,
      name: _data.name,
      type: _data.type,
      settingDate: _data.settingDate,
      dimensions: _data.dimensions,
      filterType: _data.filterType,
      substrate: _data.substrate,
      productName: _data.productName,
      lighting: _data.lighting,
      hasHeater: _data.hasHeater,
      purpose: _data.purpose,
      notes: _data.notes,
      photoPath: null,
      photoUrl: null,
    );
    notifyListeners();
  }

  /// 사진이 있는지 확인
  bool get hasPhoto => _data.photoPath != null || _data.photoUrl != null;

  // ==================== 최종 제출 ====================

  /// 어항 등록 제출
  Future<bool> submitRegistration() async {
    if (!_data.isAllValid) return false;

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // PocketBase에 저장
      final result = await _repository.createAquarium(_data);
      _data = result;

      debugPrint('Aquarium created with ID: ${result.id}');
      return true;
    } catch (e) {
      debugPrint('Error submitting registration: $e');
      _errorMessage = '어항 등록에 실패했습니다. 다시 시도해 주세요.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 에러 메시지 초기화
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// 상태 초기화
  void reset() {
    _currentStep = 1;
    _data = AquariumData();
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
