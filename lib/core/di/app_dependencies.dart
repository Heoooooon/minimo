import '../../data/repositories/aquarium_repository.dart';
import '../../data/repositories/community_repository.dart';
import '../../data/repositories/record_repository.dart';
import '../../data/repositories/schedule_repository.dart';
import '../../data/services/aquarium_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/community_service.dart';
import '../../data/services/creature_service.dart';
import '../../data/services/answer_service.dart';
import '../../data/services/comment_service.dart';
import '../../data/services/curious_service.dart';
import '../../data/services/follow_service.dart';
import '../../data/services/onboarding_service.dart';
import '../../data/services/tag_service.dart';
import '../../presentation/viewmodels/aquarium_list_viewmodel.dart';
import '../../presentation/viewmodels/aquarium_register_viewmodel.dart';
import '../../presentation/viewmodels/community_question_viewmodel.dart';
import '../../presentation/viewmodels/community_post_viewmodel.dart';
import '../../presentation/viewmodels/community_following_viewmodel.dart';
import '../../presentation/viewmodels/community_qna_viewmodel.dart';
import '../../presentation/viewmodels/record_home_viewmodel.dart';
import '../../presentation/viewmodels/record_viewmodel.dart';

/// 앱 전체 의존성 조립(Composition Root)
class AppDependencies {
  AppDependencies({
    CommunityService? communityService,
    CuriousService? curiousService,
    FollowService? followService,
    TagService? tagService,
    AnswerService? answerService,
    CommentService? commentService,
    AuthService? authService,
    AquariumRepository? aquariumRepository,
    RecordRepository? recordRepository,
    CommunityRepository? communityRepository,
    AquariumService? aquariumService,
    CreatureService? creatureService,
    ScheduleRepository? scheduleRepository,
    OnboardingService? onboardingService,
  }) : communityService = communityService ?? CommunityService.instance,
       curiousService = curiousService ?? CuriousService.instance,
       followService = followService ?? FollowService.instance,
       tagService = tagService ?? TagService.instance,
       answerService = answerService ?? AnswerService.instance,
       commentService = commentService ?? CommentService.instance,
       authService = authService ?? AuthService.instance,
       aquariumRepository =
           aquariumRepository ?? PocketBaseAquariumRepository.instance,
       recordRepository =
           recordRepository ?? PocketBaseRecordRepository.instance,
       communityRepository =
           communityRepository ?? PocketBaseCommunityRepository.instance,
       aquariumService = aquariumService ?? AquariumService.instance,
       creatureService = creatureService ?? CreatureService.instance,
       scheduleRepository =
           scheduleRepository ?? PocketBaseScheduleRepository.instance,
       onboardingService = onboardingService ?? OnboardingService.instance;

  final CommunityService communityService;
  final CuriousService curiousService;
  final FollowService followService;
  final TagService tagService;
  final AnswerService answerService;
  final CommentService commentService;
  final AuthService authService;

  final AquariumRepository aquariumRepository;
  final RecordRepository recordRepository;
  final CommunityRepository communityRepository;
  final ScheduleRepository scheduleRepository;
  final OnboardingService onboardingService;

  final AquariumService aquariumService;
  final CreatureService creatureService;

  CommunityPostViewModel createCommunityPostViewModel({bool autoLoad = true}) {
    return CommunityPostViewModel(
      service: communityService,
      tagService: tagService,
      autoLoad: autoLoad,
    );
  }

  CommunityFollowingViewModel createCommunityFollowingViewModel() {
    return CommunityFollowingViewModel(
      service: communityService,
      followService: followService,
      authService: authService,
    );
  }

  CommunityQnaViewModel createCommunityQnaViewModel() {
    return CommunityQnaViewModel(
      service: communityService,
      curiousService: curiousService,
      tagService: tagService,
      authService: authService,
    );
  }

  AquariumListViewModel createAquariumListViewModel({bool autoLoad = true}) {
    return AquariumListViewModel(
      repository: aquariumRepository,
      creatureService: creatureService,
      autoLoad: autoLoad,
    );
  }

  AquariumRegisterViewModel createAquariumRegisterViewModel() {
    return AquariumRegisterViewModel(repository: aquariumRepository);
  }

  CommunityQuestionViewModel createCommunityQuestionViewModel() {
    return CommunityQuestionViewModel(
      communityRepository: communityRepository,
      recordRepository: recordRepository,
    );
  }

  RecordHomeViewModel createRecordHomeViewModel() {
    return RecordHomeViewModel(repository: recordRepository);
  }

  RecordViewModel createRecordViewModel() {
    return RecordViewModel.withRepository(recordRepository);
  }
}
