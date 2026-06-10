import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../../data/models/employee_model.dart';
import '../constants/app_constants.dart';
import '../utils/app_logger.dart';

class FaceMatchResult {
  final bool matched;
  final EmployeeModel? employee;
  final double similarity; // 0.0 – 1.0
  final String? error;

  const FaceMatchResult({
    required this.matched,
    this.employee,
    this.similarity = 0,
    this.error,
  });

  factory FaceMatchResult.noMatch([double sim = 0]) => FaceMatchResult(
      matched: false,
      similarity: sim,
      error: 'Employee not recognized. Please try again.');

  factory FaceMatchResult.notRegistered() => const FaceMatchResult(
      matched: false,
      error: 'No registered faces found. Ask admin to register.');
}

/// 1:N face matching — compares a live embedding against all stored encodings.
/// Small kiosk candidate lists run inline; larger lists use a background isolate.
class FaceMatchingService {
  FaceMatchingService._();
  static final FaceMatchingService instance = FaceMatchingService._();

  Future<FaceMatchResult> findMatch(
    List<double> liveEmbedding,
    List<EmployeeModel> employees,
  ) async {
    final registered = employees
        .where((e) =>
            e.hasFace && e.embeddingVector.length == liveEmbedding.length)
        .toList();

    if (registered.isEmpty) return FaceMatchResult.notRegistered();

    final threshold = registered.length == 1
        ? AppConstants.singleCandidateFaceMatchThreshold
        : AppConstants.faceMatchThreshold;
    final args = {
      'live': liveEmbedding,
      'candidates': registered
          .map((e) => {
                'id': e.id,
                'name': e.name,
                'vec': e.embeddingVector,
              })
          .toList(),
      'threshold': threshold,
    };

    // Avoid isolate startup overhead for kiosk-sized candidate lists.
    final result = registered.length <= 3
        ? _matchIsolate(args)
        : await compute(_matchIsolate, args);

    final id = result['id'] as int?;
    final similarity = (result['similarity'] as num).toDouble();

    if (id == null) {
      appLogger.w(
        'No face match. candidates=${registered.length}, '
        'best=${result['name'] ?? 'unknown'}, '
        'sim=${similarity.toStringAsFixed(3)}, '
        'threshold=$threshold',
      );
      return FaceMatchResult.noMatch(similarity);
    }

    final emp = employees.firstWhere((e) => e.id == id);
    appLogger.i('Match: ${emp.name} sim=${similarity.toStringAsFixed(3)}');
    return FaceMatchResult(
        matched: true, employee: emp, similarity: similarity);
  }
}

// ── Isolate top-level function ────────────────────────────────────────────────

Map<String, dynamic> _matchIsolate(Map<String, dynamic> args) {
  final live = (args['live'] as List).cast<double>();
  final candidates = (args['candidates'] as List).cast<Map<String, dynamic>>();
  final threshold = (args['threshold'] as num).toDouble();

  int? bestId;
  String? bestName;
  double bestSim = -1.0;

  for (final c in candidates) {
    final vec = (c['vec'] as List).cast<double>();
    if (vec.length != live.length || vec.isEmpty) continue;

    final sim = _cosine(live, vec);
    if (sim > bestSim) {
      bestSim = sim;
      bestId = c['id'] as int;
      bestName = c['name']?.toString();
    }
  }

  if (bestId != null && bestSim >= threshold) {
    return {'id': bestId, 'name': bestName, 'similarity': bestSim};
  }
  return {'id': null, 'name': bestName, 'similarity': bestSim};
}

double _cosine(List<double> a, List<double> b) {
  double dot = 0, na = 0, nb = 0;
  for (int i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    na += a[i] * a[i];
    nb += b[i] * b[i];
  }
  final denom = math.sqrt(na) * math.sqrt(nb);
  return denom == 0 ? 0 : dot / denom;
}
