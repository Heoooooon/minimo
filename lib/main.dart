import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'config/app_config.dart';
import 'theme/app_theme.dart';
import 'data/services/pocketbase_service.dart';
import 'data/services/auth_service.dart';
import 'data/services/notification_service.dart';
import 'data/services/onboarding_service.dart';
import 'data/services/fcm_service.dart';
import 'presentation/screens/main_shell.dart';
import 'presentation/screens/tank_register_screen.dart';
import 'presentation/screens/record_add_screen.dart';
import 'presentation/screens/community_question_screen.dart';
import 'presentation/screens/aquarium/aquarium_list_screen.dart';
import 'presentation/screens/aquarium/aquarium_register_screen.dart';
import 'presentation/screens/aquarium/aquarium_detail_screen.dart';
import 'presentation/screens/creature/creature_search_screen.dart';
import 'presentation/screens/creature/creature_detail_screen.dart';
import 'presentation/screens/schedule/schedule_add_screen.dart';
import 'presentation/screens/auth/social_login_screen.dart';
import 'presentation/screens/auth/email_login_screen.dart';
import 'presentation/screens/auth/sign_up_screen.dart';
import 'presentation/screens/onboarding/onboarding_survey_screen.dart';
import 'presentation/screens/gallery/photo_detail_screen.dart';
import 'presentation/screens/community/question_detail_screen.dart';
import 'presentation/screens/community/post_detail_screen.dart';
import 'presentation/screens/community/post_create_screen.dart';
import 'presentation/screens/community/search_screen.dart';
import 'presentation/screens/community/notification_screen.dart';
import 'presentation/screens/community/more_list_screen.dart';
import 'presentation/viewmodels/community_viewmodel.dart';
import 'domain/models/creature_data.dart';

// 개발용 데모 화면 (프로덕션에서는 tree-shaking으로 제거됨)
import 'dev/demo_screens.dart' as dev;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 앱 설정 출력 (디버그 모드에서만)
  AppConfig.printConfig();

  // 한국어 로케일 초기화 (table_calendar용)
  await initializeDateFormatting('ko_KR', null);

  // PocketBase 초기화
  await PocketBaseService.instance.initialize();

  // NotificationService 초기화
  await NotificationService.instance.initialize();

  // OnboardingService 초기화
  await OnboardingService.instance.initialize();

  // FCM 서비스 초기화
  await FcmService.instance.initialize();

  // 상태바 스타일 설정
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  runApp(const OomoolApp());
}

/// 우물(Oomool) 앱 루트 위젯
class OomoolApp extends StatelessWidget {
  const OomoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 로그인 상태 및 온보딩 완료 여부에 따라 시작 화면 결정
    final isLoggedIn = AuthService.instance.isLoggedIn;
    final isOnboardingCompleted =
        OnboardingService.instance.isOnboardingCompleted;

    Widget homeScreen;
    if (!isLoggedIn) {
      homeScreen = const SocialLoginScreen();
    } else if (!isOnboardingCompleted) {
      homeScreen = const OnboardingSurveyScreen();
    } else {
      homeScreen = const MainShell();
    }

    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => CommunityViewModel())],
      child: MaterialApp(
        title: '우물 - 반려어 관리',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: homeScreen,
        routes: {
          '/login': (context) => const SocialLoginScreen(),
          '/login/email': (context) => const EmailLoginScreen(),
          '/signup': (context) => const SignUpScreen(),
          '/onboarding': (context) => const OnboardingSurveyScreen(),
          '/tank-register': (context) => const TankRegisterScreen(),
          '/record': (context) => const RecordAddScreen(),
          '/community-question': (context) => const CommunityQuestionScreen(),
          '/aquarium': (context) => const AquariumListScreen(),
          '/aquarium/register': (context) => const AquariumRegisterScreen(),
          '/aquarium/detail': (context) => const AquariumDetailScreen(),
          '/creature/search': (context) => const CreatureSearchScreen(),
          '/creature/detail': (context) => const _CreatureDetailWrapper(),
          '/schedule/add': (context) => const ScheduleAddScreen(),
          '/gallery/photo-detail': (context) => const PhotoDetailScreen(),
          '/question-detail': (context) => const QuestionDetailScreen(),
          '/post-detail': (context) => const PostDetailScreen(),
          '/post-create': (context) => const PostCreateScreen(),
          '/search': (context) => const SearchScreen(),
          '/notifications': (context) => const NotificationScreen(),
          '/more-list': (context) => const MoreListScreen(),
          // 개발용 라우트 (디버그 모드에서만 접근 권장)
          '/design-system': (context) => const dev.DesignSystemScreen(),
          '/demo': (context) => const dev.DemoHomeScreen(),
        },
      ),
    );
  }
}

/// 생물 상세 화면 래퍼 (route arguments 처리)
class _CreatureDetailWrapper extends StatelessWidget {
  const _CreatureDetailWrapper();

  @override
  Widget build(BuildContext context) {
    final creature =
        ModalRoute.of(context)?.settings.arguments as CreatureData?;
    if (creature == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('오류')),
        body: const Center(child: Text('생물 정보를 불러올 수 없습니다.')),
      );
    }
    return CreatureDetailScreen(creature: creature);
  }
}
