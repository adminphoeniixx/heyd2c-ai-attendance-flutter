import 'package:flutter/painting.dart' show Size;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../utils/app_logger.dart';

class DetectedFaceResult {
  final bool    detected;
  final bool    multipleFaces;
  final String? error;
  final Face?   face;

  const DetectedFaceResult({
    required this.detected,
    this.multipleFaces = false,
    this.error,
    this.face,
  });

  factory DetectedFaceResult.none() =>
      const DetectedFaceResult(detected: false, error: 'No face detected');
  factory DetectedFaceResult.multiple() =>
      const DetectedFaceResult(detected: false, multipleFaces: true,
          error: 'Multiple faces — one person at a time');
  factory DetectedFaceResult.tooSmall() =>
      const DetectedFaceResult(detected: false, error: 'Move closer to camera');
  factory DetectedFaceResult.badAngle() =>
      const DetectedFaceResult(detected: false, error: 'Look straight at camera');
  factory DetectedFaceResult.eyesClosed() =>
      const DetectedFaceResult(detected: false, error: 'Please open your eyes');
}

/// Wraps ML Kit FaceDetector.
/// Two modes:
///   • fast  — for live camera stream (no landmarks/classification, minimal checks)
///   • accurate — for still-photo registration (landmarks + eye classification)
class FaceDetectionService {
  FaceDetectionService._();
  static final FaceDetectionService instance = FaceDetectionService._();

  FaceDetector? _fastDetector;    // live stream detection
  FaceDetector? _detector;        // registration / embedding confirmation

  /// Call once at startup. Initialises both detectors.
  void init() {
    _detector ??= FaceDetector(
      options: FaceDetectorOptions(
        performanceMode:      FaceDetectorMode.accurate,
        enableLandmarks:      true,
        enableClassification: true,
        enableContours:       false,
        minFaceSize:          0.10,
      ),
    );
  }

  /// Lightweight detector for camera-stream frames — ~3-5× faster than accurate.
  void initFast() {
    _fastDetector ??= FaceDetector(
      options: FaceDetectorOptions(
        performanceMode:      FaceDetectorMode.fast,
        enableLandmarks:      false,
        enableClassification: false,
        enableContours:       false,
        minFaceSize:          0.10,
      ),
    );
  }

  Future<void> dispose() async {
    await _fastDetector?.close();
    _fastDetector = null;
    await _detector?.close();
    _detector = null;
  }

  /// Full-quality detection with strict validity checks.
  /// Use this for face REGISTRATION — ensures the face is clean enough to
  /// produce a reliable embedding stored as the reference.
  Future<DetectedFaceResult> detect(
      InputImage inputImage, Size imageSize) async {
    if (_detector == null) {
      appLogger.w('FaceDetectionService not initialized');
      return const DetectedFaceResult(detected: false, error: 'Detector not ready');
    }
    try {
      final faces = await _detector!.processImage(inputImage);

      if (faces.isEmpty)    return DetectedFaceResult.none();
      if (faces.length > 1) return DetectedFaceResult.multiple();

      final face = faces.first;

      final faceArea  = face.boundingBox.width * face.boundingBox.height;
      final imageArea = imageSize.width * imageSize.height;
      if (imageArea > 0 && faceArea / imageArea < 0.015) {
        return DetectedFaceResult.tooSmall();
      }

      final yaw  = (face.headEulerAngleY ?? 0).abs();
      final roll = (face.headEulerAngleZ ?? 0).abs();
      if (yaw > 30 || roll > 25) return DetectedFaceResult.badAngle();

      final leftOpen  = face.leftEyeOpenProbability  ?? 1.0;
      final rightOpen = face.rightEyeOpenProbability ?? 1.0;
      if (leftOpen < 0.25 || rightOpen < 0.25) return DetectedFaceResult.eyesClosed();

      return DetectedFaceResult(detected: true, face: face);
    } catch (e) {
      appLogger.e('FaceDetection error: $e');
      return const DetectedFaceResult(detected: false, error: 'Detection error');
    }
  }

  /// Lenient detection for the ATTENDANCE scan step.
  /// Uses the accurate detector (good landmark localisation for cropping) but
  /// skips angle and eye-open checks — those are only needed for registration.
  /// The embedding comparison itself implicitly handles quality.
  Future<DetectedFaceResult> detectForEmbedding(InputImage inputImage) async {
    if (_detector == null) {
      appLogger.w('FaceDetectionService not initialized');
      return const DetectedFaceResult(detected: false, error: 'Detector not ready');
    }
    try {
      final faces = await _detector!.processImage(inputImage);

      if (faces.isEmpty)    return DetectedFaceResult.none();
      if (faces.length > 1) return DetectedFaceResult.multiple();

      return DetectedFaceResult(detected: true, face: faces.first);
    } catch (e) {
      appLogger.e('DetectForEmbedding error: $e');
      return const DetectedFaceResult(detected: false, error: 'Detection error');
    }
  }

  /// Fast detection on raw camera-stream frames.
  /// No landmark/angle/eye checks (classification is disabled for speed).
  /// Only verifies: face present, single face, minimum size.
  Future<DetectedFaceResult> detectFast(
      InputImage inputImage, Size imageSize) async {
    if (_fastDetector == null) {
      return const DetectedFaceResult(detected: false, error: 'Detector not ready');
    }
    try {
      final faces = await _fastDetector!.processImage(inputImage);

      if (faces.isEmpty)    return DetectedFaceResult.none();
      if (faces.length > 1) return DetectedFaceResult.multiple();

      final face     = faces.first;
      final faceArea = face.boundingBox.width * face.boundingBox.height;
      final imgArea  = imageSize.width * imageSize.height;
      if (imgArea > 0 && faceArea / imgArea < 0.015) {
        return DetectedFaceResult.tooSmall();
      }

      return DetectedFaceResult(detected: true, face: face);
    } catch (e) {
      appLogger.e('FastDetect error: $e');
      return const DetectedFaceResult(detected: false, error: 'Detection error');
    }
  }
}
