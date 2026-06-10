abstract class AppConstants {
  static const appName = 'Pulsara Kiosk';

  // Face matching — cosine similarity thresholds for MobileFaceNet.
  // Same-person (good kiosk conditions): 0.65–0.85 after 20% crop margin fix.
  // Different person: typically 0.05–0.25.
  // Set conservatively below expected true-positive range with headroom.
  // Raise these if false positives occur; lower if legitimate employees are rejected.
  static const faceMatchThreshold = 0.45;
  static const singleCandidateFaceMatchThreshold = 0.40;
  static const frameThrottleMs = 250; // process up to ~4 frames/sec
  static const confirmationSeconds = 0;
  static const cooldownSeconds = 12;

  // TFLite model
  static const modelPath = 'assets/models/mobile_face_net.tflite';
  static const inputSize = 112; // MobileFaceNet: 112×112
  static const embeddingSize = 192; // MobileFaceNet output dimensions

  // Sync
  static const syncBatchSize = 20;
  static const syncRetryMax = 5;

  // Token validity: 90 days in seconds
  static const tokenValiditySeconds = 90 * 24 * 60 * 60;
}
