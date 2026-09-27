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

    final series = await dao.getCompositeScoreSeries();
    final changeResult = _evaluate(series)!;

    // 현재 기준선 기간의 baseline이 확정되었으면 저장
    if (changeResult.baseline != null) {
      final establishedAt = series[changeResult.baselinePeriodStart +
              kBaselineSessionCount -
              1]
          .testedAt;
      await dao.upsertBaseline(CognitiveBaseline(
        baselineComposite: changeResult.baseline,
        calculatedAt: establishedAt,
        sessionCountUsed: kBaselineSessionCount,
      ));
    }

    return (composite: composite, change: changeResult);
  }

  Future<CognitiveSession?> getLatestSession() async {
    final db = await AppDatabase.instance;
    return CognitiveDao(db).getLatestSession();
  }

  Future<ChangeDetectionResult?> getChangeResult() async {
    final db = await AppDatabase.instance;
    return _evaluate(await CognitiveDao(db).getCompositeScoreSeries());
  }

  /// 전체 세션으로 변화 감지. 90일 이상 공백 뒤에는 새 기준선 기간으로 판정.
  ChangeDetectionResult? _evaluate(
      List<({DateTime testedAt, double score})> series) {
    if (series.isEmpty) return null;
    return evaluateChange(
      allScores: series.map((s) => s.score).toList(),
      sessionDates: series.map((s) => s.testedAt).toList(),
      lastSessionDate: series.last.testedAt,
    );
  }
}
