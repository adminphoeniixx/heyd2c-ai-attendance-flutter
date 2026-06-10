import 'package:get/get.dart';
import '../../core/network/dio_client.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/face_detection_service.dart';
import '../../core/services/face_embedding_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/employee_repository.dart';
import '../../routes/app_routes.dart';

class SplashController extends GetxController {
  final _auth     = AuthRepository();
  final _empRepo  = EmployeeRepository();

  @override
  void onInit() {
    super.onInit();
    _boot();
  }

  Future<void> _boot() async {
    // Init network client
    DioClient.instance.init();

    // Init face services (both modes: fast for live scan, accurate for registration)
    FaceDetectionService.instance.init();
    FaceDetectionService.instance.initFast();
    await FaceEmbeddingService.instance.init();

    // Small splash delay
    await Future.delayed(const Duration(milliseconds: 1800));

    if (!_auth.isLoggedIn) {
      Get.offAllNamed(AppRoutes.login);
      return;
    }

    // Pre-warm employee cache in background (don't block splash)
    _warmCache();

    Get.offAllNamed(AppRoutes.faceScan);
  }

  Future<void> _warmCache() async {
    try {
      final online = await ConnectivityService.instance.isOnline;
      if (online) await _empRepo.syncEmployees();
    } catch (_) {
      // Use cached data — no crash
    }
  }
}
