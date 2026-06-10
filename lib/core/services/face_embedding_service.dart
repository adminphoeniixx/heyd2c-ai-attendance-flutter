import 'dart:math' as math;
import 'dart:typed_data';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../constants/app_constants.dart';
import '../utils/app_logger.dart';

/// Runs MobileFaceNet TFLite model to produce 192-dim face embeddings.
///
/// Pre-processing (decode → crop → resize → normalise) runs inline on the main
/// isolate — the 112×112 input is small enough (~5-10 ms) that isolate-spawn
/// overhead (30-50 ms) would cost more than it saves.
/// TFLite [Interpreter.run] is also main-isolate only (not isolate-safe).
///
/// Input : [1, 112, 112, 3]  float32 normalised to [-1, 1]
/// Output: [1, 192]           float32 L2-normalised embedding vector
class FaceEmbeddingService {
  FaceEmbeddingService._();
  static final FaceEmbeddingService instance = FaceEmbeddingService._();

  Interpreter? _interpreter;
  bool get isReady => _interpreter != null;

  Future<void> init() async {
    if (_interpreter != null) return;
    try {
      _interpreter = await Interpreter.fromAsset(AppConstants.modelPath);
      appLogger.i('MobileFaceNet loaded');
    } catch (e) {
      appLogger.w('TFLite model not found — face embedding unavailable: $e');
    }
  }

  Future<void> dispose() async {
    _interpreter?.close();
    _interpreter = null;
  }

  /// Returns a 192-dim L2-normalised embedding, or null on any failure.
  Future<List<double>?> getEmbedding(Uint8List imageBytes, Face face) async {
    if (_interpreter == null) return null;

    try {
      // Step 1: decode + crop + resize + normalise — inline, fast for 112×112
      final input = _preprocess(
        bytes:      imageBytes,
        bboxLeft:   face.boundingBox.left,
        bboxTop:    face.boundingBox.top,
        bboxWidth:  face.boundingBox.width,
        bboxHeight: face.boundingBox.height,
        inputSize:  AppConstants.inputSize,
      );
      if (input.isEmpty) return null;

      // Step 2: TFLite inference (~10-30 ms)
      final output = [List<double>.filled(AppConstants.embeddingSize, 0.0)];
      _interpreter!.run(input, output);

      return _l2normalize(output[0]);
    } catch (e) {
      appLogger.e('Embedding error: $e');
      return null;
    }
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  List<List<List<List<double>>>> _preprocess({
    required Uint8List bytes,
    required double bboxLeft,
    required double bboxTop,
    required double bboxWidth,
    required double bboxHeight,
    required int inputSize,
  }) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return [];

    // MobileFaceNet needs context around the tight ML Kit bounding box.
    // Without margin the crop clips chin/forehead/ears, dropping cosine
    // similarity by ~0.1–0.2 compared to a properly padded crop.
    final mx = (bboxWidth  * 0.20).toInt();
    final my = (bboxHeight * 0.20).toInt();
    final x  = math.max(0, bboxLeft.toInt()  - mx);
    final y  = math.max(0, bboxTop.toInt()   - my);
    final w  = math.min(decoded.width  - x,   bboxWidth.toInt()  + 2 * mx);
    final h  = math.min(decoded.height - y,   bboxHeight.toInt() + 2 * my);
    if (w <= 0 || h <= 0) return [];

    final cropped = img.copyCrop(decoded, x: x, y: y, width: w, height: h);
    final resized  = img.copyResize(cropped, width: inputSize, height: inputSize);

    return [
      List.generate(
        inputSize,
        (row) => List.generate(
          inputSize,
          (col) {
            final pixel = resized.getPixel(col, row);
            return [
              (pixel.r / 127.5) - 1.0,
              (pixel.g / 127.5) - 1.0,
              (pixel.b / 127.5) - 1.0,
            ];
          },
        ),
      ),
    ];
  }

  List<double> _l2normalize(List<double> v) {
    double norm = 0;
    for (final x in v) { norm += x * x; }
    norm = math.sqrt(norm);
    if (norm == 0) return v;
    return v.map((x) => x / norm).toList();
  }
}
