import '../core/algorithms/cognitive_scoring.dart';
import '../core/algorithms/change_detection.dart';
import '../core/database/cognitive_dao.dart';
import '../data/app_database.dart';

class CognitiveService {
  Future<int> getSessionCount() async {
    final db = await AppDatabase.instance;
    return CognitiveDao(db).sessionCount();
  }

  Future<({double composite, ChangeDetectionResult change})> saveSession({
    required int t1Immediate,
    required int t1Delayed,
    required int t2WordCount,
    required int userAge,
    required int t3ForwardSpan,
    required int t3BackwardSpan,
    required double t4TimeA,
    required double t4TimeB,
    required String wordSet,
  }) async {
    final t1Score = scoreT1(correctDelayed: t1Delayed);
    final t2Score = scoreT2(wordCount: t2WordCount, age: userAge);
    final t3Score = scoreT3(
        forwardSpan: t3ForwardSpan, backwardSpan: t3BackwardSpan);
    final t4Score = scoreT4(timeA: t4TimeA, timeB: t4TimeB);
    final composite = compositeScore(
          t1Score: t1Score,
          t2Score: t2Score,
          t3Score: t3Score,
          t4Score: t4Score,
        ) ??
        0.0;

    final session = CognitiveSession(
      testedAt: DateTime.now(),
      t1Immediate: t1Immediate,
      t1Delayed: t1Delayed,
      t1Score: t1Score,
      t2WordCount: t2WordCount,
      t2Score: t2Score,
      t3ForwardSpan: t3ForwardSpan,
      t3BackwardSpan: t3BackwardSpan,
      t3Score: t3Score,
      t4TimeA: t4TimeA,
      t4TimeB: t4TimeB,
      t4Score: t4Score,
      compositeScore: composite,
      wordSet: wordSet,
    );

    final db = await AppDatabase.instance;
    final dao = CognitiveDao(db);
    await dao.insertSession(session);

    final scores = await dao.getCompositeScoreTimeSeries();
    final baseline = computeBaseline(scores);
    if (baseline != null) {
      await dao.upsertBaseline(CognitiveBaseline(
        baselineComposite: baseline,
        calculatedAt: DateTime.now(),
        sessionCountUsed: scores.length,
      ));
    }

    final latest = await dao.getLatestSession();
    final changeResult = evaluateChange(
      allScores: scores,
      lastSessionDate: latest?.testedAt ?? DateTime.now(),
    );

    return (composite: composite, change: changeResult);
  }

  Future<CognitiveSession?> getLatestSession() async {
    final db = await AppDatabase.instance;
    return CognitiveDao(db).getLatestSession();
  }

  Future<ChangeDetectionResult?> getChangeResult() async {
    final db = await AppDatabase.instance;
    final dao = CognitiveDao(db);
    final scores = await dao.getCompositeScoreTimeSeries();
    if (scores.isEmpty) return null;
    final latest = await dao.getLatestSession();
    if (latest == null) return null;
    return evaluateChange(
      allScores: scores,
      lastSessionDate: latest.testedAt,
    );
  }
}
