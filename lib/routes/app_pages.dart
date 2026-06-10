import 'package:get/get.dart';
import '../modules/add_employee/add_employee_screen.dart';
import '../modules/auth/login_screen.dart';
import '../modules/auth/otp_screen.dart';
import '../modules/dashboard/dashboard_screen.dart';
import '../modules/employees/employee_list_screen.dart';
import '../modules/face_registration/face_reg_screen.dart';
import '../modules/face_scan/face_scan_screen.dart';
import '../modules/settings/settings_screen.dart';
import '../modules/splash/splash_screen.dart';
import '../modules/sync/sync_screen.dart';
import '../modules/today_attendance/today_screen.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = <GetPage>[
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.otp,
      page: () => const OtpScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.faceScan,
      page: () => const FaceScanScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.employees,
      page: () => const EmployeeListScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.faceReg,
      page: () => const FaceRegScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.today,
      page: () => const TodayScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.syncQueue,
      page: () => const SyncScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.addEmployee,
      page: () => const AddEmployeeScreen(),
      transition: Transition.rightToLeft,
    ),
  ];
}
