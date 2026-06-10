import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/painting.dart' show Size;
import 'package:get/get.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/face_detection_service.dart';
import '../../core/services/face_embedding_service.dart';
import '../../core/services/sync_service.dart';
import '../../core/utils/app_logger.dart';
import '../../data/local/local_db.dart';
import '../../data/models/employee_model.dart';
import '../../data/models/pending_employee.dart';

enum AddEmpStep { form, face }

enum FaceCaptureState { idle, capturing, processing, captured, error }

class AddEmployeeController extends GetxController {
  final _db = LocalDb.instance;
  final _detector = FaceDetectionService.instance;
  final _embedder = FaceEmbeddingService.instance;
  final _uuid = const Uuid();

  // ── Step ──────────────────────────────────────────────────────────────────
  final step = AddEmpStep.form.obs;

  // ── Form field errors ─────────────────────────────────────────────────────
  final nameError = ''.obs;
  final empIdError = ''.obs;
  final designationError = ''.obs;
  final departmentError = ''.obs;

  // ── Face capture ──────────────────────────────────────────────────────────
  final captureState = FaceCaptureState.idle.obs;
  final faceMsg = 'Position face clearly in the frame'.obs;
  final isCameraReady = false.obs;
  final cameraError = ''.obs;
  String? _capturedEncoding;
  String? _capturedImagePath;

  // ── Submission ─────────────────────────────────────────────────────────────
  final isSubmitting = false.obs;
  final submitError = ''.obs;

  CameraController? cameraCtrl;

  @override
  void onClose() {
    final cam = cameraCtrl;
    if (cam != null && cam.value.isInitialized) cam.dispose();
    super.onClose();
  }

  // ── Step 1: form validation ───────────────────────────────────────────────

  bool validateForm({
    required String name,
    required String empId,
    required String designation,
    required String department,
  }) {
    nameError.value = name.trim().isEmpty ? 'Name is required' : '';
    empIdError.value = empId.trim().isEmpty ? 'Employee ID is required' : '';
    designationError.value =
        designation.trim().isEmpty ? 'Designation is required' : '';
    departmentError.value =
        department.trim().isEmpty ? 'Department is required' : '';

    return nameError.value.isEmpty &&
        empIdError.value.isEmpty &&
        designationError.value.isEmpty &&
        departmentError.value.isEmpty;
  }

  void goToFaceStep() {
    step.value = AddEmpStep.face;
    _initCamera();
  }

  // ── Camera ────────────────────────────────────────────────────────────────

  Future<void> _initCamera() async {
    isCameraReady.value = false;
    cameraError.value = '';
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
      cameraCtrl = cam;
      isCameraReady.value = true;
    } catch (e) {
      cameraError.value = 'Camera error: $e';
      appLogger.e('AddEmp camera: $e');
    }
  }

  // ── Step 2: face capture ──────────────────────────────────────────────────

  Future<void> captureface() async {
    if (cameraCtrl == null || !cameraCtrl!.value.isInitialized) return;
    if (captureState.value == FaceCaptureState.capturing ||
        captureState.value == FaceCaptureState.processing) {
      return;
    }

    _capturedEncoding = null;
    _capturedImagePath = null;
    captureState.value = FaceCaptureState.capturing;
    faceMsg.value = 'Capturing…';

    try {
      final xfile = await cameraCtrl!.takePicture();
      final bytes = await xfile.readAsBytes();
      _capturedImagePath = xfile.path;

      captureState.value = FaceCaptureState.processing;
      faceMsg.value = 'Analysing face…';

      // Detect — uses ML Kit (fast, on-device)
      final inputImage = InputImage.fromFilePath(xfile.path);
      final detection =
          await _detector.detect(inputImage, const Size(640, 480));

      if (!detection.detected) {
        _faceFail(detection.error ?? 'No face detected — try again');
        return;
      }

      faceMsg.value = 'Computing embedding…';

      // Embedding — heavy preprocessing runs in background isolate via compute()
      final embedding = await _embedder.getEmbedding(bytes, detection.face!);
      if (embedding == null || embedding.isEmpty) {
        _faceFail(
            'Face model unavailable — check assets/models/mobile_face_net.tflite');
        return;
      }

      _capturedEncoding = embedding.join(',');
      captureState.value = FaceCaptureState.captured;
      faceMsg.value = 'Face captured! Ready to save.';
    } catch (e) {
      _faceFail('Capture failed: $e');
      appLogger.e('AddEmp face capture: $e');
    }
  }

  void retakePhoto() {
    _capturedEncoding = null;
    _capturedImagePath = null;
    captureState.value = FaceCaptureState.idle;
    faceMsg.value = 'Position face clearly in the frame';
  }

  void _faceFail(String msg) {
    captureState.value = FaceCaptureState.error;
    faceMsg.value = msg;
    Future.delayed(const Duration(seconds: 3), () {
      if (captureState.value == FaceCaptureState.error) {
        captureState.value = FaceCaptureState.idle;
        faceMsg.value = 'Position face clearly in the frame';
      }
    });
  }

  // ── Offline-first submit ──────────────────────────────────────────────────

  /// Saves the employee to the local Hive queue immediately so the UI responds
  /// instantly.  A background sync (Workmanager + foreground trigger) pushes
  /// the record to the server; the employee appears in the list right away.
  Future<void> submit({
    required String name,
    required String empId,
    required String designation,
    required String department,
  }) async {
    isSubmitting.value = true;
    submitError.value = '';

    try {
      final localId = _uuid.v4();
      final faceImagePath = await _persistFaceImage(localId);
      final pending = PendingEmployee(
        localId: localId,
        name: name.trim(),
        employeeId: empId.trim(),
        designation: designation.trim(),
        department: department.trim(),
        faceEncoding: _capturedEncoding,
        faceImagePath: faceImagePath,
        createdAt: DateTime.now().toIso8601String(),
      );

      // ── 1. Persist locally — instant, never fails ────────────────────────
      await _db.saveQueuedEmployee(pending);
      await _db.updateEmployee(
        EmployeeModel(
          id: pending.localEmployeeId,
          employeeId: pending.employeeId,
          name: pending.name,
          designation: pending.designation,
          department: pending.department,
          hasFace:
              pending.faceEncoding != null && pending.faceEncoding!.isNotEmpty,
          faceEncoding: pending.faceEncoding ?? '',
        ),
      );
      appLogger.i('Employee queued locally: ${pending.name}');

      // ── 2. Try immediate sync if online ──────────────────────────────────
      final online = await ConnectivityService.instance.isOnline;
      if (online) {
        // Fire-and-forget — does not block the UI
        SyncService.runBackgroundSync().then((_) {
          appLogger.i('Foreground employee sync triggered');
        }).catchError((e) {
          appLogger.w('Foreground employee sync error: $e');
        });
      }

      // ── 3. Return immediately — employee visible in list at once ─────────
      Get.back(result: true);
    } catch (e) {
      submitError.value = e.toString().replaceAll('Exception:', '').trim();
      appLogger.e('AddEmp queue error: $e');
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<String?> _persistFaceImage(String localId) async {
    final sourcePath = _capturedImagePath;
    if (sourcePath == null || sourcePath.isEmpty) return null;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final faceDir = Directory('${dir.path}/registered_faces');
      if (!await faceDir.exists()) {
        await faceDir.create(recursive: true);
      }
      final targetPath = '${faceDir.path}/$localId.jpg';
      await File(sourcePath).copy(targetPath);
      return targetPath;
    } catch (e) {
      appLogger.w('Face image save failed: $e');
      return sourcePath;
    }
  }
}
