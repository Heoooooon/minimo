/// 온보딩 설문 데이터 모델
class OnboardingData {
  /// 물고기 키운 기간 (Step 1)
  final FishKeepingDuration? fishKeepingDuration;

  /// 물생활 실력 (Step 2)
  final FishKeepingSkill? fishKeepingSkill;

  /// 가장 어려운 점 (Step 3)
  final FishKeepingDifficulty? fishKeepingDifficulty;

  /// 가장 바라는 것 (Step 4)
  final FishKeepingGoal? fishKeepingGoal;

  const OnboardingData({
    this.fishKeepingDuration,
    this.fishKeepingSkill,
    this.fishKeepingDifficulty,
    this.fishKeepingGoal,
  });

  OnboardingData copyWith({
    FishKeepingDuration? fishKeepingDuration,
    FishKeepingSkill? fishKeepingSkill,
    FishKeepingDifficulty? fishKeepingDifficulty,
    FishKeepingGoal? fishKeepingGoal,
  }) {
    return OnboardingData(
      fishKeepingDuration: fishKeepingDuration ?? this.fishKeepingDuration,
      fishKeepingSkill: fishKeepingSkill ?? this.fishKeepingSkill,
      fishKeepingDifficulty:
          fishKeepingDifficulty ?? this.fishKeepingDifficulty,
      fishKeepingGoal: fishKeepingGoal ?? this.fishKeepingGoal,
    );
  }

  /// 모든 필수 항목이 선택되었는지 확인
  bool get isComplete =>
      fishKeepingDuration != null &&
      fishKeepingSkill != null &&
      fishKeepingDifficulty != null &&
      fishKeepingGoal != null;

  Map<String, dynamic> toJson() {
    return {
      'fishKeepingDuration': fishKeepingDuration?.name,
      'fishKeepingSkill': fishKeepingSkill?.name,
      'fishKeepingDifficulty': fishKeepingDifficulty?.name,
      'fishKeepingGoal': fishKeepingGoal?.name,
    };
  }
}

/// 물고기 키운 기간 (Step 1)
enum FishKeepingDuration {
  lessThanOneYear('1년 미만'),
  oneToThreeYears('1년 이상~3년 미만'),
  moreThanThreeYears('3년 이상');

  final String label;
  const FishKeepingDuration(this.label);
}

/// 물생활 실력 (Step 2)
enum FishKeepingSkill {
  beginner('기본도 어려워요'),
  intermediate('웬만한 건 알아요'),
  expert('다른 분들께 조언할 수 있어요');

  final String label;
  const FishKeepingSkill(this.label);
}

/// 가장 어려운 점 (Step 3)
enum FishKeepingDifficulty {
  healthManagement('건강 관리'),
  fishBehavior('물고기 행동'),
  tankSetup('어항 세팅'),
  informationSearch('관련 정보 탐색');

  final String label;
  const FishKeepingDifficulty(this.label);
}

/// 가장 바라는 것 (Step 4)
enum FishKeepingGoal {
  healthyFish('건강하게 키우고 싶어요'),
  properKnowledge('제대로 알고 키우고 싶어요'),
  enjoyTogether('즐겁게 함께하고 싶어요');

  final String label;
  const FishKeepingGoal(this.label);
}
