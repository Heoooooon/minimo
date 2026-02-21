import '../data/services/admin_auth_service.dart';
import '../data/services/admin_user_service.dart';
import '../data/services/admin_content_service.dart';
import '../data/services/admin_report_service.dart';
import '../data/services/admin_stats_service.dart';
import '../presentation/viewmodels/admin_dashboard_viewmodel.dart';
import '../presentation/viewmodels/admin_user_viewmodel.dart';
import '../presentation/viewmodels/admin_content_viewmodel.dart';
import '../presentation/viewmodels/admin_report_viewmodel.dart';

/// 관리자 패널 의존성 조립(Composition Root)
class AdminDependencies {
  AdminDependencies({
    AdminAuthService? authService,
    AdminUserService? userService,
    AdminContentService? contentService,
    AdminReportService? reportService,
    AdminStatsService? statsService,
  }) : authService = authService ?? AdminAuthService.instance,
       userService = userService ?? AdminUserService.instance,
       contentService = contentService ?? AdminContentService.instance,
       reportService = reportService ?? AdminReportService.instance,
       statsService = statsService ?? AdminStatsService.instance;

  final AdminAuthService authService;
  final AdminUserService userService;
  final AdminContentService contentService;
  final AdminReportService reportService;
  final AdminStatsService statsService;

  AdminDashboardViewModel createDashboardViewModel() {
    return AdminDashboardViewModel(statsService: statsService);
  }

  AdminUserViewModel createUserViewModel() {
    return AdminUserViewModel(userService: userService);
  }

  AdminContentViewModel createContentViewModel() {
    return AdminContentViewModel(contentService: contentService);
  }

  AdminReportViewModel createReportViewModel() {
    return AdminReportViewModel(reportService: reportService);
  }
}
