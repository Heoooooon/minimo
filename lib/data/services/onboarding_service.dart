import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/models/onboarding_data.dart';

/// 온보딩 서비스
///
/// 온보딩 완료 여부 및 결과를 로컬에 저장/조회
class OnboardingService {
  OnboardingService._();

  static OnboardingService? _instance;
  static OnboardingService get instance => _instance ??= OnboardingService._();

  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyOnboardingData = 'onboarding_data';

  SharedPreferences? _prefs;

  /// 초기화
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// 온보딩 완료 여부 확인
  bool get isOnboardingCompleted {
    return _prefs?.getBool(_keyOnboardingCompleted) ?? false;
  }

  /// 온보딩 완료 처리 및 데이터 저장
  Future<void> completeOnboarding(OnboardingData data) async {
    // _prefs가 null이면 다시 초기화
    _prefs ??= await SharedPreferences.getInstance();

    await _prefs!.setBool(_keyOnboardingCompleted, true);
    await _prefs!.setString(_keyOnboardingData, jsonEncode(data.toJson()));

    // 저장 확인을 위해 다시 읽기
    final saved = _prefs!.getBool(_keyOnboardingCompleted);
    AppLogger.data('OnboardingService: 온보딩 완료 저장됨 (saved=$saved)');
    AppLogger.data(
      'OnboardingService: isOnboardingCompleted = $isOnboardingCompleted',
    );
  }

  /// 저장된 온보딩 데이터 조회
  OnboardingData? getSavedOnboardingData() {
    final jsonString = _prefs?.getString(_keyOnboardingData);
    if (jsonString == null) return null;

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return OnboardingData(
        fishKeepingDuration: _parseDuration(json['fishKeepingDuration']),
        fishKeepingSkill: _parseSkill(json['fishKeepingSkill']),
        fishKeepingDifficulty: _parseDifficulty(json['fishKeepingDifficulty']),
        fishKeepingGoal: _parseGoal(json['fishKeepingGoal']),
      );
    } catch (e) {
      AppLogger.data('Failed to parse onboarding data: $e', isError: true);
      return null;
    }
  }

  /// 사용자 레벨 계산 (초보자, 중급자, 숙련자)
  UserLevel calculateUserLevel(OnboardingData data) {
    int score = 0;

    // 키운 기간 점수
    switch (data.fishKeepingDuration) {
      case FishKeepingDuration.lessThanOneYear:
        score += 1;
        break;
      case FishKeepingDuration.oneToThreeYears:
        score += 2;
        break;
      case FishKeepingDuration.moreThanThreeYears:
        score += 3;
        break;
      case null:
        break;
    }

    // 실력 점수
    switch (data.fishKeepingSkill) {
      case FishKeepingSkill.beginner:
        score += 1;
        break;
      case FishKeepingSkill.intermediate:
        score += 2;
        break;
      case FishKeepingSkill.expert:
        score += 3;
        break;
      case null:
        break;
    }

    // 레벨 결정
    if (score <= 3) {
      return UserLevel.beginner;
    } else if (score <= 4) {
      return UserLevel.intermediate;
    } else {
      return UserLevel.expert;
    }
  }

  /// 온보딩 초기화 (테스트용)
  Future<void> resetOnboarding() async {
    await _prefs?.remove(_keyOnboardingCompleted);
    await _prefs?.remove(_keyOnboardingData);
  }

  // 파싱 헬퍼 메서드들
  FishKeepingDuration? _parseDuration(String? value) {
    if (value == null) return null;
    return FishKeepingDuration.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FishKeepingDuration.lessThanOneYear,
    );
  }

  FishKeepingSkill? _parseSkill(String? value) {
    if (value == null) return null;
    return FishKeepingSkill.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FishKeepingSkill.beginner,
    );
  }

  FishKeepingDifficulty? _parseDifficulty(String? value) {
    if (value == null) return null;
    return FishKeepingDifficulty.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FishKeepingDifficulty.healthManagement,
    );
  }

  FishKeepingGoal? _parseGoal(String? value) {
    if (value == null) return null;
    return FishKeepingGoal.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FishKeepingGoal.healthyFish,
    );
  }
}

/// 사용자 레벨
enum UserLevel {
  beginner('초보자'),
  intermediate('중급자'),
  expert('숙련자');

  final String label;
  const UserLevel(this.label);
}
