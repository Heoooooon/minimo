import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/di/app_dependencies.dart';
import '../../../data/services/onboarding_service.dart';
import '../../../domain/models/onboarding_data.dart';
import 'package:cmore_design_system/theme/app_colors.dart';
import 'package:cmore_design_system/theme/app_text_styles.dart';
import 'package:cmore_design_system/widgets/app_button.dart';
import 'onboarding_result_screen.dart';

/// 온보딩 설문 화면 (4단계)
class OnboardingSurveyScreen extends StatefulWidget {
  const OnboardingSurveyScreen({super.key});

  @override
  State<OnboardingSurveyScreen> createState() => _OnboardingSurveyScreenState();
}

class _OnboardingSurveyScreenState extends State<OnboardingSurveyScreen> {
  int _currentStep = 0;
  OnboardingData _data = const OnboardingData();

  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // 마지막 단계: 결과 분석 화면으로 이동
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OnboardingAnalyzingScreen(data: _data),
        ),
      );
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _data.fishKeepingDuration != null;
      case 1:
        return _data.fishKeepingSkill != null;
      case 2:
        return _data.fishKeepingDifficulty != null;
      case 3:
        return _data.fishKeepingGoal != null;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                  _buildStep4(),
                ],
              ),
            ),
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: _goToPreviousStep,
            icon: const Icon(
              Icons.chevron_left,
              size: 28,
              color: AppColors.textMain,
            ),
          ),
          const Spacer(),
          _buildStepIndicator(),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        final isCompleted = index < _currentStep;
        final isCurrent = index == _currentStep;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Container(
            width: 30,
            height: 30,
            decoration: isCurrent
                ? BoxDecoration(
                    color: AppColors.brand,
                    borderRadius: BorderRadius.circular(15),
                  )
                : null,
            alignment: Alignment.center,
            child: Text(
              '${index + 1}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: isCurrent
                    ? Colors.white
                    : isCompleted
                    ? AppColors.brand
                    : AppColors.textHint,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildBottomButton() {
    final isLastStep = _currentStep == 3;
    final canProceed = _canProceed();

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
        top: false,
        child: AppButton(
          text: isLastStep ? '결과보기' : '다음으로',
          size: AppButtonSize.large,
          expanded: true,
          isEnabled: canProceed,
          onPressed: canProceed ? _goToNextStep : null,
        ),
      ),
    );
  }

  // Step 1: 물고기 키운 기간
  Widget _buildStep1() {
    return _buildStepContent(
      title: '물고기를 키운 지\n얼마나 되셨나요?',
      child: Column(
        children: FishKeepingDuration.values.map((duration) {
          return _buildOptionCard(
            label: duration.label,
            isSelected: _data.fishKeepingDuration == duration,
            onTap: () {
              setState(() {
                _data = _data.copyWith(fishKeepingDuration: duration);
              });
            },
          );
        }).toList(),
      ),
    );
  }

  // Step 2: 물생활 실력
  Widget _buildStep2() {
    return _buildStepContent(
      title: '본인의 물생활 실력이\n어느 정도라고 생각하세요?',
      child: Column(
        children: FishKeepingSkill.values.map((skill) {
          return _buildOptionCard(
            label: skill.label,
            isSelected: _data.fishKeepingSkill == skill,
            onTap: () {
              setState(() {
                _data = _data.copyWith(fishKeepingSkill: skill);
              });
            },
          );
        }).toList(),
      ),
    );
  }

  // Step 3: 가장 어려운 점 (2x2 그리드)
  Widget _buildStep3() {
    return _buildStepContent(
      title: '물생활 중 가장 어려운 점은\n무엇이라고 생각하나요?',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildGridOptionCard(
                  label: FishKeepingDifficulty.healthManagement.label,
                  isSelected:
                      _data.fishKeepingDifficulty ==
                      FishKeepingDifficulty.healthManagement,
                  onTap: () {
                    setState(() {
                      _data = _data.copyWith(
                        fishKeepingDifficulty:
                            FishKeepingDifficulty.healthManagement,
                      );
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGridOptionCard(
                  label: FishKeepingDifficulty.fishBehavior.label,
                  isSelected:
                      _data.fishKeepingDifficulty ==
                      FishKeepingDifficulty.fishBehavior,
                  onTap: () {
                    setState(() {
                      _data = _data.copyWith(
                        fishKeepingDifficulty:
                            FishKeepingDifficulty.fishBehavior,
                      );
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildGridOptionCard(
                  label: FishKeepingDifficulty.tankSetup.label,
                  isSelected:
                      _data.fishKeepingDifficulty ==
                      FishKeepingDifficulty.tankSetup,
                  onTap: () {
                    setState(() {
                      _data = _data.copyWith(
                        fishKeepingDifficulty: FishKeepingDifficulty.tankSetup,
                      );
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGridOptionCard(
                  label: FishKeepingDifficulty.informationSearch.label,
                  isSelected:
                      _data.fishKeepingDifficulty ==
                      FishKeepingDifficulty.informationSearch,
                  onTap: () {
                    setState(() {
                      _data = _data.copyWith(
                        fishKeepingDifficulty:
                            FishKeepingDifficulty.informationSearch,
                      );
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Step 4: 가장 바라는 것
  Widget _buildStep4() {
    return _buildStepContent(
      title: '물고기를 키우며\n가장 바라는 건 무엇인가요?',
      child: Column(
        children: FishKeepingGoal.values.map((goal) {
          return _buildOptionCard(
            label: goal.label,
            isSelected: _data.fishKeepingGoal == goal,
            onTap: () {
              setState(() {
                _data = _data.copyWith(fishKeepingGoal: goal);
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStepContent({required String title, required Widget child}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(title, style: AppTextStyles.headlineLarge.copyWith(height: 1.5)),
          const SizedBox(height: 120),
          child,
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 64,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.blue50 : AppColors.backgroundSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.brand : AppColors.borderLight,
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.bodyMediumBold.copyWith(
              color: isSelected ? AppColors.brand : AppColors.textMain,
              height: 1.75,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridOptionCard({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 72,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.blue50 : AppColors.backgroundSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.brand : AppColors.borderLight,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.bodyMediumBold.copyWith(
            color: isSelected ? AppColors.brand : AppColors.textMain,
            height: 1.75,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// 온보딩 결과 분석 중 화면
class OnboardingAnalyzingScreen extends StatefulWidget {
  final OnboardingData data;

  const OnboardingAnalyzingScreen({super.key, required this.data});

  @override
  State<OnboardingAnalyzingScreen> createState() =>
      _OnboardingAnalyzingScreenState();
}

class _OnboardingAnalyzingScreenState extends State<OnboardingAnalyzingScreen>
    with TickerProviderStateMixin {
  late AnimationController _dotAnimationController;
  late final OnboardingService _onboardingService;
  bool _isNavigationStarted = false;
  bool _isDependenciesReady = false;

  @override
  void initState() {
    super.initState();

    _dotAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDependenciesReady) {
      _onboardingService = context.read<AppDependencies>().onboardingService;
      _isDependenciesReady = true;
    }

    if (!_isNavigationStarted) {
      _isNavigationStarted = true;
      _saveAndNavigate();
    }
  }

  Future<void> _saveAndNavigate() async {
    // 온보딩 완료 저장
    await _onboardingService.completeOnboarding(widget.data);

    // 3초 후 결과 화면으로 이동
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OnboardingResultScreen(data: widget.data),
        ),
      );
    }
  }

  @override
  void dispose() {
    _dotAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLoadingDots(),
              const SizedBox(height: 40),
              Text(
                '결과를 분석 중이에요.',
                style: AppTextStyles.headlineLarge.copyWith(
                  color: AppColors.brand,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '잠시만 기다려주세요!',
                style: AppTextStyles.bodyMediumBold.copyWith(
                  color: AppColors.textSubtle,
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingDots() {
    return AnimatedBuilder(
      animation: _dotAnimationController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final animValue = (_dotAnimationController.value - delay) % 1.0;
            final scale = 0.6 + (0.4 * _calculateBounce(animValue));
            final opacity = 0.4 + (0.6 * _calculateBounce(animValue));

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.5),
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.brand,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  double _calculateBounce(double value) {
    if (value < 0 || value > 1) return 0;
    // 간단한 bounce 효과
    if (value < 0.5) {
      return value * 2;
    } else {
      return (1 - value) * 2;
    }
  }
}
