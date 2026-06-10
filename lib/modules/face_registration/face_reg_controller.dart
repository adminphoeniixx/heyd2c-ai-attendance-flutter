import 'package:camera/camera.dart';
import 'package:flutter/painting.dart' show Size;
import 'package:get/get.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../core/services/face_detection_service.dart';
import '../../core/services/face_embedding_service.dart';
import '../../core/utils/app_logger.dart';
import '../../data/models/employee_model.dart';
import '../../data/repositories/employee_repository.dart';

enum RegState { idle, capturing, processing, success, error }

class FaceRegController extends GetxController {
  final _repo     = EmployeeRepository();
  final _detector = FaceDetectionService.instance;
  final _embedder = FaceEmbeddingService.instance;

  // ── Employee passed from the employee list ────────────────────────────────
  late EmployeeModel employee;

  // ── Observables ───────────────────────────────────────────────────────────
  final regState      = RegState.idle.obs;
  final statusMsg     = 'Position face clearly in the frame'.obs;
  final isCameraReady = false.obs;
  final cameraError   = ''.obs;

  // ── Camera ────────────────────────────────────────────────────────────────
  CameraController? cameraCtrl;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    employee   = args?['employee'] as EmployeeModel? ??
        const EmployeeModel(
            id: 0, employeeId: '', name: 'Unknown',
            designation: '', department: '',
            hasFace: false, faceEncoding: '');
    _initCamera();
  }

  @override
  void onClose() {
    final cam = cameraCtrl;
    if (cam != null && cam.value.isInitialized) {
      cam.dispose();
    }
    super.onClose();
  }

  // ── Camera ────────────────────────────────────────────────────────────────

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        cameraError.value = 'No camera found';
        return;
      }
      final front = cameras.firstWhereOrNull(
          (c) => c.lensDirection == CameraLensDirection.front);
      final cam = CameraController(
        front ?? cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await cam.initialize();
      cameraCtrl          = cam;
      isCameraReady.value = true;
    } catch (e) {
      cameraError.value = 'Camera error: $e';
      appLogger.e('FaceReg camera: $e');
    }
  }

  // ── Capture ───────────────────────────────────────────────────────────────

  Future<void> captureAndRegister() async {
    if (cameraCtrl == null || !cameraCtrl!.value.isInitialized) return;
    if (regState.value == RegState.capturing ||
        regState.value == RegState.processing) {
      return;
    }

    regState.value  = RegState.capturing;
    statusMsg.value = 'Capturing…';

    try {
      // Take a still photo → JPEG file
      final xfile = await cameraCtrl!.takePicture();
      final bytes = await xfile.readAsBytes();

      regState.value  = RegState.processing;
      statusMsg.value = 'Analysing face…';

      // Detect face using file path (ML Kit handles JPEG natively)
      final inputImage = InputImage.fromFilePath(xfile.path);
      const captureSize = Size(640, 480);
      final detection  = await _detector.detect(inputImage, captureSize);

      if (!detection.detected) {
        _fail(detection.error ?? 'No face detected — try again');
        return;
      }

      // Get embedding
      final embedding = await _embedder.getEmbedding(bytes, detection.face!);
      if (embedding == null || embedding.isEmpty) {
        _fail('Face model not available — add mobile_face_net.tflite');
        return;
      }

      // Upload to server
      statusMsg.value = 'Uploading…';
      final encodingStr = embedding.join(',');
      await _repo.saveFace(employee.id, encodingStr);

      regState.value  = RegState.success;
      statusMsg.value = 'Face registered! Stand in good light for best results.';

      await Future.delayed(const Duration(seconds: 2));
      Get.back(result: true);
    } catch (e) {
      _fail('Registration failed: $e');
      appLogger.e('FaceReg error: $e');
    }
  }

  Future<void> deleteFace() async {
    try {
      await _repo.deleteFace(employee.id);
      Get.back(result: true);
    } catch (e) {
      statusMsg.value = 'Delete failed: $e';
      appLogger.e('FaceReg delete: $e');
    }
  }

  void _fail(String msg) {
    regState.value  = RegState.error;
    statusMsg.value = msg;
    Future.delayed(const Duration(seconds: 3), () {
      if (regState.value == RegState.error) {
        regState.value  = RegState.idle;
        statusMsg.value = 'Position face clearly in the frame';
      }
    });
  }
}
