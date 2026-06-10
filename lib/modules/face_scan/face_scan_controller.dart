import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/painting.dart' show Size;
import 'package:flutter/widgets.dart'
    show AppLifecycleState, WidgetsBinding, WidgetsBindingObserver;
import 'package:get/get.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/face_detection_service.dart';
import '../../core/services/face_embedding_service.dart';
import '../../core/services/face_matching_service.dart';
import '../../core/services/sync_service.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/time_utils.dart';
import '../../data/models/employee_model.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../data/repositories/employee_repository.dart';

enum ScanState { idle, detecting, matched, punching, success, error }

class FaceScanController extends GetxController with WidgetsBindingObserver {
  final _empRepo  = EmployeeRepository();
  final _attRepo  = AttendanceRepository();
  final _detector = FaceDetectionService.instance;
  final _embedder = FaceEmbeddingService.instance;
  final _matcher  = FaceMatchingService.instance;

  // ── Observables ───────────────────────────────────────────────────────────
  final scanState       = ScanState.idle.obs;
  final statusMsg       = 'Position face in the frame'.obs;
  final matchedEmp      = Rxn<EmployeeModel>();
  final matchSimilarity = 0.0.obs;
  final lastPunchType   = ''.obs;
  final lastPunchTime   = ''.obs;
  final isOnline        = true.obs;
  final pendingCount    = 0.obs;

  // ── Camera ────────────────────────────────────────────────────────────────
  CameraController?   cameraCtrl;
  CameraDescription?  _cameraDescription;
  final isCameraReady = false.obs;
  final cameraError   = ''.obs;

  // ── Internal ──────────────────────────────────────────────────────────────
  bool _isStreaming         = false;
  bool _isProcessingStream  = false;
  bool _isPaused            = false;
  bool _isCameraInitializing = false;
  DateTime _lastFrameTime   = DateTime(0);
  Timer?   _confirmTimer;
  Timer?   _resetTimer;
  final Map<int, DateTime> _cooldown = {};
  List<EmployeeModel> _employees = [];

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    // Safety-net: splash initialises these, but if the OS killed the isolate
    // and the controller is re-created without going through splash again,
    // detectors would be null and every frame would silently return early.
    _detector.init();
    _detector.initFast();
    _completeMissedPunchOuts();
    _initCamera();
    _loadEmployees();
    _monitorConnectivity();
    _refreshPendingCount();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _confirmTimer?.cancel();
    _resetTimer?.cancel();
    unawaited(_disposeCamera());
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(resumeScanning());
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused   ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      unawaited(pauseScanning(releaseCamera: true));
    }
  }

  // ── Camera init ───────────────────────────────────────────────────────────

  Future<void> _initCamera() async {
    if (_isCameraInitializing || _isPaused) return;

    final existing = cameraCtrl;
    if (existing != null && existing.value.isInitialized) {
      isCameraReady.value = true;
      _startStream();
      return;
    }

    _isCameraInitializing = true;
    try {
      cameraError.value   = '';
      isCameraReady.value = false;

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        cameraError.value = 'No camera found';
        return;
      }
      final front = cameras.firstWhereOrNull(
          (c) => c.lensDirection == CameraLensDirection.front);
      final desc = front ?? cameras.first;
      _cameraDescription = desc;

      final cam = CameraController(
        desc,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await cam.initialize();
      cameraCtrl          = cam;
      isCameraReady.value = true;
      _startStream();
    } catch (e) {
      cameraError.value = 'Camera error: $e';
      appLogger.e('Camera init: $e');
    } finally {
      _isCameraInitializing = false;
    }
  }

  // ── Stream lifecycle ──────────────────────────────────────────────────────

  void _startStream() {
    if (_isStreaming || _isPaused) return;
    final cam = cameraCtrl;
    if (cam == null || !cam.value.isInitialized) return;
    try {
      _isStreaming = true;
      cam.startImageStream(_onCameraFrame);
    } catch (e) {
      _isStreaming = false;
      appLogger.w('startImageStream failed: $e');
    }
  }

  Future<void> _stopStream() async {
    if (!_isStreaming) return;
    _isStreaming = false;
    try {
      final cam = cameraCtrl;
      if (cam != null && cam.value.isInitialized) {
        await cam.stopImageStream();
      }
    } catch (e) {
      appLogger.w('stopImageStream failed: $e');
    }
  }

  // ── Per-frame callback (runs on camera thread, fast path) ─────────────────

  void _onCameraFrame(CameraImage image) {
    // Throttle: skip frames that arrive faster than frameThrottleMs
    final now = DateTime.now();
    if (now.difference(_lastFrameTime).inMilliseconds < AppConstants.frameThrottleMs) {
      return;
    }

    // Skip if busy or in terminal states
    if (_isProcessingStream || _isPaused) return;
    if (scanState.value == ScanState.matched  ||
        scanState.value == ScanState.punching ||
        scanState.value == ScanState.success) { return; }

    _lastFrameTime       = now;
    _isProcessingStream  = true;
    _processFrameAsync(image).whenComplete(() => _isProcessingStream = false);
  }

  // ── Async frame processing ─────────────────────────────────────────────────

  Future<void> _processFrameAsync(CameraImage image) async {
    try {
      await _ensureFaceCandidates();

      final inputImage = _toInputImage(image);
      if (inputImage == null) return;

      scanState.value = ScanState.detecting;

      final detection = await _detector.detectFast(
        inputImage,
        Size(image.width.toDouble(), image.height.toDouble()),
      );

      if (!detection.detected) {
        if (scanState.value == ScanState.detecting) {
          scanState.value = ScanState.idle;
          statusMsg.value = detection.error ?? 'Position face in the frame';
        }
        return;
      }

      // Face confirmed in stream — stop stream and take a quality still photo
      statusMsg.value = 'Verifying face…';
      await _stopStream();

      final matched = await _doEmbeddingMatch();

      // Restart stream unless we are waiting for punch confirmation / success
      if (!isClosed &&
          scanState.value != ScanState.matched  &&
          scanState.value != ScanState.punching &&
          scanState.value != ScanState.success) {
        if (scanState.value != ScanState.idle) scanState.value = ScanState.idle;
        _startStream();
      }

      // Keep the specific failure reason (set inside _doEmbeddingMatch) so the
      // user sees 'Not recognised (44%)' etc. — only fall back to the generic
      // prompt if nothing more specific was set.
      if (!matched && statusMsg.value.isEmpty) {
        statusMsg.value = 'Position face in the frame';
      }
    } catch (e) {
      appLogger.w('Frame processing error: $e');
      if (scanState.value != ScanState.success &&
          scanState.value != ScanState.punching) {
        scanState.value = ScanState.idle;
      }
      _startStream();
    }
  }

  // ── Embedding + matching (takes one still photo) ──────────────────────────

  Future<bool> _doEmbeddingMatch() async {
    final cam = cameraCtrl;
    if (cam == null || !cam.value.isInitialized) return false;

    try {
      final xfile      = await cam.takePicture();
      final bytes      = await xfile.readAsBytes();
      final inputImage = InputImage.fromFilePath(xfile.path);

      // detectForEmbedding: accurate detector (good bounding-box for crop)
      // but NO angle / eye-open checks — those are registration-only guards.
      // The embedding cosine distance already implicitly handles face quality.
      final detection = await _detector.detectForEmbedding(inputImage);
      if (!detection.detected || detection.face == null) {
        statusMsg.value = detection.error ?? 'No face detected';
        return false;
      }

      final embedding = await _embedder.getEmbedding(bytes, detection.face!);
      if (embedding == null || embedding.isEmpty) {
        statusMsg.value = 'Face scan failed — check model file';
        return false;
      }

      final match = await _matcher.findMatch(embedding, _employees);
      if (!match.matched || match.employee == null) {
        statusMsg.value =
            '${match.error ?? 'Not recognised'} '
            '(${(match.similarity * 100).clamp(0, 100).round()}%)';
        return false;
      }

      final emp         = match.employee!;
      final cooldownEnd = _cooldown[emp.id];
      if (cooldownEnd != null && DateTime.now().isBefore(cooldownEnd)) {
        statusMsg.value = '${emp.name} — please wait before punching again';
        _startStream();
        return true;
      }

      _onEmployeeMatched(emp, match.similarity);
      return true;
    } catch (e) {
      appLogger.w('Embedding match error: $e');
      return false;
    }
  }

  // ── CameraImage → InputImage converter ───────────────────────────────────

  InputImage? _toInputImage(CameraImage image) {
    try {
      final rotation = _sensorRotation();

      // iOS / single-plane BGRA — pass through directly
      if (image.planes.length == 1) {
        final format = InputImageFormatValue.fromRawValue(image.format.raw);
        if (format == null) return null;
        return InputImage.fromBytes(
          bytes: image.planes.first.bytes,
          metadata: InputImageMetadata(
            size:        Size(image.width.toDouble(), image.height.toDouble()),
            rotation:    rotation,
            format:      format,
            bytesPerRow: image.planes.first.bytesPerRow,
          ),
        );
      }

      // Android YUV_420_888 — must convert to NV21 (Y + interleaved VU).
      // Simply concatenating plane bytes is wrong: Y has row-stride padding and
      // U/V have pixel-stride gaps, making the raw sizes and layout invalid for
      // ML Kit's InputImageConverter → IllegalArgumentException.
      return InputImage.fromBytes(
        bytes: _yuv420ToNv21(image),
        metadata: InputImageMetadata(
          size:        Size(image.width.toDouble(), image.height.toDouble()),
          rotation:    rotation,
          format:      InputImageFormat.nv21,
          bytesPerRow: image.width,
        ),
      );
    } catch (e) {
      appLogger.w('InputImage convert error: $e');
      return null;
    }
  }

  /// Converts a 3-plane YUV_420_888 CameraImage to an NV21 byte buffer.
  /// Strips Y-plane row padding and correctly interleaves V then U bytes.
  Uint8List _yuv420ToNv21(CameraImage image) {
    final w = image.width;
    final h = image.height;
    final nv21 = Uint8List(w * h + (w * h) ~/ 2);

    final yPlane = image.planes[0];
    final uPlane = image.planes[1]; // Cb
    final vPlane = image.planes[2]; // Cr

    // Y plane — copy each row, stripping any bytesPerRow padding
    int idx = 0;
    for (int row = 0; row < h; row++) {
      nv21.setRange(idx, idx + w, yPlane.bytes, row * yPlane.bytesPerRow);
      idx += w;
    }

    // VU interleaved (NV21 = Y then V-U, not U-V).
    // bytesPerPixel is the pixel stride; Android NV12/NV21 UV planes use 2.
    final vStride = vPlane.bytesPerPixel ?? 2;
    final uStride = uPlane.bytesPerPixel ?? 2;
    final uvH = h ~/ 2;
    final uvW = w ~/ 2;
    for (int row = 0; row < uvH; row++) {
      for (int col = 0; col < uvW; col++) {
        nv21[idx++] = vPlane.bytes[row * vPlane.bytesPerRow + col * vStride];
        nv21[idx++] = uPlane.bytes[row * uPlane.bytesPerRow + col * uStride];
      }
    }

    return nv21;
  }

  InputImageRotation _sensorRotation() {
    switch (_cameraDescription?.sensorOrientation ?? 0) {
      case 90:  return InputImageRotation.rotation90deg;
      case 180: return InputImageRotation.rotation180deg;
      case 270: return InputImageRotation.rotation270deg;
      default:  return InputImageRotation.rotation0deg;
    }
  }

  // ── Pause / resume ────────────────────────────────────────────────────────

  Future<void> pauseScanning({bool releaseCamera = false}) async {
    _isPaused           = true;
    _isProcessingStream = false;
    _confirmTimer?.cancel();

    if (scanState.value != ScanState.success &&
        scanState.value != ScanState.error) {
      _resetToIdle(restartStream: false);
    }

    await _stopStream();
    if (releaseCamera) await _disposeCamera();
  }

  Future<void> resumeScanning() async {
    if (isClosed) return;
    _isPaused = false;
    _resetToIdle(restartStream: false);
    await _loadEmployees();

    final cam = cameraCtrl;
    if (cam == null || !cam.value.isInitialized) {
      await _initCamera();
      return;
    }

    isCameraReady.value = true;
    _startStream();
  }

  Future<void> _disposeCamera() async {
    await _stopStream();
    final cam = cameraCtrl;
    cameraCtrl          = null;
    isCameraReady.value = false;
    if (cam == null) return;
    try {
      await cam.dispose();
    } catch (e) {
      appLogger.w('Camera dispose failed: $e');
    }
  }

  // ── Employees & connectivity ──────────────────────────────────────────────

  Future<void> _loadEmployees() async {
    _employees = _empRepo.getFaceRegistered();
    appLogger.i('Face scan candidates: ${_employees.length}');
    if (_employees.isEmpty && await ConnectivityService.instance.isOnline) {
      try {
        await _empRepo.syncEmployees();
        _employees = _empRepo.getFaceRegistered();
        appLogger.i('After sync: ${_employees.length}');
      } catch (_) {}
    }
  }

  Future<void> _ensureFaceCandidates() async {
    if (_employees.isNotEmpty) return;
    _employees = _empRepo.getFaceRegistered();
    if (_employees.isNotEmpty) return;

    final online = await ConnectivityService.instance.isOnline;
    if (!online) return;
    try {
      await _empRepo.syncEmployees();
      _employees = _empRepo.getFaceRegistered();
    } catch (e) {
      appLogger.w('Face candidates refresh failed: $e');
    }
  }

  void _monitorConnectivity() {
    ConnectivityService.instance.onlineStream.listen((online) {
      isOnline.value = online;
      if (online) _triggerBackgroundSync();
    });
    ConnectivityService.instance.isOnline.then((v) => isOnline.value = v);
  }

  void _refreshPendingCount() {
    pendingCount.value = _attRepo.pendingCount;
  }

  // ── Match → punch flow ────────────────────────────────────────────────────

  void _onEmployeeMatched(EmployeeModel emp, double similarity) {
    if (scanState.value == ScanState.matched  ||
        scanState.value == ScanState.punching ||
        scanState.value == ScanState.success) { return; }

    matchedEmp.value      = emp;
    matchSimilarity.value = similarity;
    lastPunchType.value   = _attRepo.nextPunchType(emp.id);
    scanState.value       = ScanState.matched;
    statusMsg.value       =
        'Match found — ${lastPunchType.value == 'punch_in' ? 'punch in' : 'punch out'} confirming…';

    _confirmTimer?.cancel();
    if (AppConstants.confirmationSeconds <= 0) {
      unawaited(_doPunch(emp));
      return;
    }
    _confirmTimer = Timer(
      const Duration(seconds: AppConstants.confirmationSeconds),
      () => _doPunch(emp),
    );
  }

  Future<void> _doPunch(EmployeeModel emp) async {
    if (scanState.value == ScanState.punching) return;
    scanState.value = ScanState.punching;
    statusMsg.value = 'Recording attendance…';

    final type = lastPunchType.value.isNotEmpty
        ? lastPunchType.value
        : _attRepo.nextPunchType(emp.id);

    try {
      final result = await _attRepo.punch(
        employeeId:   emp.id,
        employeeName: emp.name,
        type:         type,
        isOnline:     isOnline.value,
      );

      final punchType     = result.response?.type ?? type;
      lastPunchType.value = punchType;
      lastPunchTime.value = TimeUtils.nowHHmmss();
      scanState.value     = ScanState.success;
      statusMsg.value     =
          '${emp.name} ${punchType == 'punch_in' ? 'checked in' : 'checked out'} ✓';

      _cooldown[emp.id] =
          DateTime.now().add(const Duration(seconds: AppConstants.cooldownSeconds));

      _refreshPendingCount();
      if (isOnline.value) _triggerBackgroundSync();

      _resetTimer?.cancel();
      _resetTimer = Timer(const Duration(seconds: 3), () => _resetToIdle());
    } catch (e) {
      scanState.value = ScanState.error;
      statusMsg.value = 'Punch failed — please retry';
      appLogger.e('Punch error: $e');
      _resetTimer = Timer(const Duration(seconds: 3), () => _resetToIdle());
    }
  }

  void _resetToIdle({bool restartStream = true}) {
    matchedEmp.value      = null;
    matchSimilarity.value = 0;
    lastPunchType.value   = '';
    scanState.value       = ScanState.idle;
    statusMsg.value       = 'Position face in the frame';
    if (restartStream && !_isPaused) _startStream();
  }

  // ── Background sync ───────────────────────────────────────────────────────

  void _completeMissedPunchOuts() async {
    try {
      final closed = await _attRepo.completeMissedPunchOuts();
      if (closed > 0) _refreshPendingCount();
    } catch (e) {
      appLogger.w('Missed punch-out completion failed: $e');
    }
  }

  void _triggerBackgroundSync() async {
    try {
      await SyncService.runBackgroundSync();
      _refreshPendingCount();
    } catch (_) {}
  }

  // ── Manual punch ──────────────────────────────────────────────────────────

  void manualPunch() {
    if (matchedEmp.value != null && scanState.value == ScanState.matched) {
      _confirmTimer?.cancel();
      _doPunch(matchedEmp.value!);
    }
  }
}
