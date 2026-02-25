import '../core/algorithms/change_detection.dart';

class DashboardState {
  final double? cognitiveScore;
  final double? lifestyleScore;
  final ChangeDetectionResult? changeResult;
  final DateTime? lastCognitiveDate;
  final DateTime? lastLifestyleDate;

  const DashboardState({
    this.cognitiveScore,
    this.lifestyleScore,
    this.changeResult,
    this.lastCognitiveDate,
    this.lastLifestyleDate,
  });

  double? get integratedScore {
    if (cognitiveScore == null && lifestyleScore == null) return null;
    if (cognitiveScore == null) return lifestyleScore;
    if (lifestyleScore == null) return cognitiveScore;
    return cognitiveScore! * 0.40 + lifestyleScore! * 0.60;
  }

  bool get hasAnyData =>
      cognitiveScore != null || lifestyleScore != null;
}
