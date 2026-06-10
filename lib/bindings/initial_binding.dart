import 'package:get/get.dart';
import '../core/services/connectivity_service.dart';
import '../core/services/face_detection_service.dart';
import '../core/services/face_embedding_service.dart';
import '../core/services/face_matching_service.dart';

/// Bindings registered at app startup — available throughout the lifetime of
/// the app. Screen-level controllers are registered lazily via Get.put() in
/// their own build() methods.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Core services (permanent singletons)
    Get.put(ConnectivityService.instance, permanent: true);
    Get.put(FaceDetectionService.instance, permanent: true);
    Get.put(FaceEmbeddingService.instance, permanent: true);
    Get.put(FaceMatchingService.instance, permanent: true);
  }
}
