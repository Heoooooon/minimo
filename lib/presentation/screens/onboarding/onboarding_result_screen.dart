import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/di/app_dependencies.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/onboarding_service.dart';
import '../../../domain/models/onboarding_data.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../widgets/common/app_button.dart';
import '../main_shell.dart';

/// 온보딩 결과 화면
class OnboardingResultScreen extends StatefulWidget {
  final OnboardingData data;

  const OnboardingResultScreen({super.key, required this.data});

  @override
  State<OnboardingResultScreen> createState() => _OnboardingResultScreenState();
}

class _OnboardingResultScreenState extends State<OnboardingResultScreen> {
  late final ScrollController _scrollController;
  late final Timer _autoScrollTimer;
  late final UserLevel _userLevel;
  late final AuthService _authService;
  late final OnboardingService _onboardingService;
  bool _isDependenciesReady = false;

  double _scrollOffset = 0;
  static const double _cardWidth = 136.8;
  static const double _cardGap = 24;
  static const double _scrollSpeed = 0.5;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // 자동 스크롤 타이머
    _autoScrollTimer = Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => _autoScroll(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isDependenciesReady) return;

    final dependencies = context.read<AppDependencies>();
    _authService = dependencies.authService;
    _onboardingService = dependencies.onboardingService;
    _userLevel = _onboardingService.calculateUserLevel(widget.data);
    _isDependenciesReady = true;
  }

  @override
  void dispose() {
    _autoScrollTimer.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _autoScroll() {
    if (!_scrollController.hasClients) return;

    _scrollOffset += _scrollSpeed;
    final maxScroll = _scrollController.position.maxScrollExtent;

    if (_scrollOffset >= maxScroll) {
      _scrollOffset = 0;
    }

    _scrollController.jumpTo(_scrollOffset);
  }

  String get _userName {
    final user = _authService.currentUser;
    return user?.getStringValue('name') ?? '사용자';
  }

  String get _titleMessage {
    switch (_userLevel) {
      case UserLevel.beginner:
        return '$_userName님,\n아직 기본이 낯설지만,\n건강하게 키우고 싶은\n마음은 누구보다 크시죠?';
      case UserLevel.intermediate:
        return '$_userName님,\n어느 정도 감이 잡히셨네요!\n더 깊이 알아가고 싶은\n마음이 느껴져요.';
      case UserLevel.expert:
        return '$_userName님,\n이미 많은 경험을 쌓으셨군요!\n더 완벽한 물생활을\n도와드릴게요.';
    }
  }

  String get _bottomMessage {
    switch (_userLevel) {
      case UserLevel.beginner:
        return '아직 시작 단계이지만, 걱정 말아요\n우물이 함께 도와드릴게요!';
      case UserLevel.intermediate:
        return '더 성장할 수 있는 기회가 많아요\n우물과 함께 해볼까요?';
      case UserLevel.expert:
        return '풍부한 경험을 살려\n더 멋진 물생활을 만들어봐요!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, AppColors.backgroundApp],
            stops: const [0.0, 0.91],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              // 제목 메시지
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: RichText(
                  text: TextSpan(
                    style: AppTextStyles.headlineLarge.copyWith(height: 1.5),
                    children: [
                      TextSpan(
                        text: _userName,
                        style: const TextStyle(color: AppColors.brand),
                      ),
                      TextSpan(text: _titleMessage.substring(_userName.length)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 96),
              // 자동 스크롤 카드들
              SizedBox(
                height: 173,
                child: ListView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildGoalCard(),
                    const SizedBox(width: _cardGap),
                    _buildDurationCard(),
                    const SizedBox(width: _cardGap),
                    _buildSkillCard(),
                    const SizedBox(width: _cardGap),
                    _buildDifficultyCard(),
                    const SizedBox(width: _cardGap),
                    // 무한 스크롤을 위한 복제
                    _buildGoalCard(),
                    const SizedBox(width: _cardGap),
                    _buildDurationCard(),
                    const SizedBox(width: _cardGap),
                    _buildSkillCard(),
                    const SizedBox(width: _cardGap),
                    _buildDifficultyCard(),
                  ],
                ),
              ),
              const Spacer(),
              // 하단 메시지
              Center(
                child: Text(
                  _bottomMessage,
                  style: AppTextStyles.bodyMediumMedium.copyWith(
                    color: AppColors.textSubtle,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              // 홈으로 버튼
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: AppButton(
                  text: '홈으로',
                  size: AppButtonSize.large,
                  expanded: true,
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const MainShell()),
                      (route) => false,
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // 바라는 것 카드 (노란색)
  Widget _buildGoalCard() {
    final goal = widget.data.fishKeepingGoal;
    return _ResultCard(
      width: _cardWidth,
      backgroundColor: const Color(0xFFFFF3DB),
      icon: Icons.lightbulb,
      iconColor: const Color(0xFFC88000),
      iconBackgroundColor: const Color(0xFFFFF3DB),
      text: goal?.label ?? '',
      textColor: const Color(0xFFC88000),
    );
  }

  // 키운 기간 카드 (민트색)
  Widget _buildDurationCard() {
    final duration = widget.data.fishKeepingDuration;
    return _ResultCard(
      width: _cardWidth,
      backgroundColor: const Color(0xFFE3FFF9),
      icon: Icons.eco,
      iconColor: const Color(0xFF1ABA6F),
      iconBackgroundColor: const Color(0xFFE3FFF9),
      text: duration?.label ?? '',
      textColor: const Color(0xFF1ABA6F),
    );
  }

  // 실력 카드 (연어색)
  Widget _buildSkillCard() {
    final skill = widget.data.fishKeepingSkill;
    return _ResultCard(
      width: _cardWidth,
      backgroundColor: const Color(0xFFFFEEE8),
      icon: Icons.sentiment_dissatisfied,
      iconColor: const Color(0xFFED532E),
      iconBackgroundColor: const Color(0xFFFFEEE8),
      text: skill?.label ?? '',
      textColor: const Color(0xFFED532E),
    );
  }

  // 어려운 점 카드 (연두색)
  Widget _buildDifficultyCard() {
    final difficulty = widget.data.fishKeepingDifficulty;
    return _ResultCard(
      width: _cardWidth,
      backgroundColor: const Color(0xFFE4FFF2),
      icon: Icons.favorite,
      iconColor: const Color(0xFF009F35),
      iconBackgroundColor: const Color(0xFFE4FFF2),
      text: difficulty?.label ?? '',
      textColor: const Color(0xFF009F35),
    );
  }
}

/// 결과 카드 위젯
class _ResultCard extends StatelessWidget {
  final double width;
  final Color backgroundColor;
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final String text;
  final Color textColor;

  const _ResultCard({
    required this.width,
    required this.backgroundColor,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.text,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 173,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(19),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 62, color: iconColor),
          const SizedBox(height: 16),
          Text(
            text,
            style: AppTextStyles.titleMedium.copyWith(
              color: textColor,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
