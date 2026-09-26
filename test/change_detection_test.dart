import 'package:test/test.dart';
import 'package:prj_dim/core/algorithms/change_detection.dart';

void main() {
  // =========================================================================
  // computeBaseline
  // =========================================================================
  group('computeBaseline', () {
    test('2개 세션 → 첫 2개 평균', () {
      expect(computeBaseline([80.0, 70.0, 65.0]), closeTo(75.0, 0.01));
    });

    test('정확히 2개 세션 → 평균', () {
      expect(computeBaseline([90.0, 80.0]), closeTo(85.0, 0.01));
    });

    test('1개 세션 → null (부족)', () {
      expect(computeBaseline([80.0]), isNull);
    });

    test('빈 리스트 → null', () {
      expect(computeBaseline([]), isNull);
    });

    test('n=3으로 변경: 3개 이상이면 첫 3개 평균', () {
      expect(computeBaseline([90.0, 80.0, 70.0, 60.0], n: 3),
          closeTo(80.0, 0.01));
    });
  });

  // =========================================================================
  // isSignificantDecline
  // =========================================================================
  group('isSignificantDecline', () {
    test('15점 정확히 하락 → true (경계값)', () {
      expect(isSignificantDecline(60.0, 75.0), isTrue);
    });

    test('16점 하락 → true', () {
      expect(isSignificantDecline(59.0, 75.0), isTrue);
    });

    test('14점 하락 → false', () {
      expect(isSignificantDecline(61.0, 75.0), isFalse);
    });

    test('상승 → false', () {
      expect(isSignificantDecline(80.0, 75.0), isFalse);
    });

    test('동점 → false', () {
      expect(isSignificantDecline(75.0, 75.0), isFalse);
    });

    test('커스텀 임계값(20점): 20점 하락 → true', () {
      expect(isSignificantDecline(55.0, 75.0, threshold: 20.0), isTrue);
    });

    test('커스텀 임계값(20점): 19점 하락 → false', () {
      expect(isSignificantDecline(56.0, 75.0, threshold: 20.0), isFalse);
    });
  });

  // =========================================================================
  // consecutiveDeclineCount
  // =========================================================================
  group('consecutiveDeclineCount', () {
    test('2회 연속 하락', () {
      // 80 → 75 → 70 (연속 2회 하락)
      expect(consecutiveDeclineCount([80.0, 75.0, 70.0]), equals(2));
    });

    test('1회 하락 후 상승 → 연속 0 (최신 기준)', () {
      // 80 → 75 → 78 (마지막 구간 상승)
      expect(consecutiveDeclineCount([80.0, 75.0, 78.0]), equals(0));
    });

    test('1회만 하락 → 1', () {
      expect(consecutiveDeclineCount([80.0, 70.0]), equals(1));
    });

    test('모두 동점 → 0', () {
      expect(consecutiveDeclineCount([80.0, 80.0, 80.0]), equals(0));
    });

    test('세션 1개 → 0', () {
      expect(consecutiveDeclineCount([80.0]), equals(0));
    });

    test('빈 리스트 → 0', () {
      expect(consecutiveDeclineCount([]), equals(0));
    });

    test('3회 연속 하락', () {
      expect(consecutiveDeclineCount([90.0, 85.0, 80.0, 75.0]), equals(3));
    });
  });

  // =========================================================================
  // shouldAlert
  // =========================================================================
  group('shouldAlert', () {
    final baseline = 80.0; // 첫 2개 평균: (85+75)/2 = 80

    test('기준선 충족 후 2회 연속 유의미한 하락 → true', () {
      // scores: [85, 75, 60, 55]
      // baseline = (85+75)/2 = 80
      // 최근 2회: 80-60=20, 80-55=25 → 모두 >= 15 ✓
      final scores = [85.0, 75.0, 60.0, 55.0];
      final result = shouldAlert(allScores: scores, baseline: computeBaseline(scores));
      expect(result, isTrue);
    });

    test('유의미한 하락이지만 1회만 → false (노이즈 필터)', () {
      // scores: [85, 75, 90, 55]
      // baseline = 80, latest=55, 80-55=25 >=15 ✓
      // 직전 세션 90은 하락 아님 → 유의미 하락 1회만 ✗
      final scores = [85.0, 75.0, 90.0, 55.0];
      expect(shouldAlert(allScores: scores, baseline: computeBaseline(scores)),
          isFalse);
    });

    test('2회 연속 하락이지만 15점 미만 → false', () {
      // scores: [85, 75, 74, 73]
      // baseline=80, latest=73, 하락=7점 < 15 ✗
      final scores = [85.0, 75.0, 74.0, 73.0];
      expect(shouldAlert(allScores: scores, baseline: computeBaseline(scores)),
          isFalse);
    });

    test('baseline null → false', () {
      expect(shouldAlert(allScores: [80.0], baseline: null), isFalse);
    });

    test('세션 부족(2개 이하) → false', () {
      expect(
          shouldAlert(allScores: [80.0, 75.0], baseline: baseline), isFalse);
    });

    test('기준선 이후 1회만 측정 → false (연속 확인 불가)', () {
      // baseline=80, latest=50 (30점 하락)이지만 기준선 이후 1회뿐
      final scores = [80.0, 80.0, 50.0];
      expect(shouldAlert(allScores: scores, baseline: computeBaseline(scores)),
          isFalse);
    });

    test('크게 하락한 뒤 그대로 유지 → true (추가 하락 없어도 경고)', () {
      // baseline=80, 50 → 50: 직전 대비 하락은 없지만 2회 모두 30점 하락
      final scores = [80.0, 80.0, 50.0, 50.0];
      expect(shouldAlert(allScores: scores, baseline: computeBaseline(scores)),
          isTrue);
    });

    test('크게 하락한 뒤 약간 회복했지만 여전히 임계값 아래 → true', () {
      // baseline=80, 50 → 60: 모두 15점 이상 하락 상태
      final scores = [80.0, 80.0, 50.0, 60.0];
      expect(shouldAlert(allScores: scores, baseline: computeBaseline(scores)),
          isTrue);
    });

    test('하락 후 임계값 위로 회복 → false', () {
      // baseline=80, 50 → 70: 최신은 10점 하락 < 15
      final scores = [80.0, 80.0, 50.0, 70.0];
      expect(shouldAlert(allScores: scores, baseline: computeBaseline(scores)),
          isFalse);
    });

    test('정확히 임계값(15점) 하락 2회 → true', () {
      final scores = [80.0, 80.0, 65.0, 65.0];
      expect(shouldAlert(allScores: scores, baseline: computeBaseline(scores)),
          isTrue);
    });

    test('과거 하락 후 최근 2회 정상 → false', () {
      final scores = [80.0, 80.0, 50.0, 50.0, 78.0, 79.0];
      expect(shouldAlert(allScores: scores, baseline: computeBaseline(scores)),
          isFalse);
    });
  });

  // =========================================================================
  // shouldRecommendBaselineReset
  // =========================================================================
  group('shouldRecommendBaselineReset', () {
    final now = DateTime(2026, 3, 1);

    test('90일 공백 → true', () {
      final last = now.subtract(const Duration(days: 90));
      expect(
          shouldRecommendBaselineReset(lastSessionDate: last, now: now), isTrue);
    });

    test('89일 공백 → false', () {
      final last = now.subtract(const Duration(days: 89));
      expect(
          shouldRecommendBaselineReset(lastSessionDate: last, now: now),
          isFalse);
    });

    test('30일 공백 → false', () {
      final last = now.subtract(const Duration(days: 30));
      expect(
          shouldRecommendBaselineReset(lastSessionDate: last, now: now),
          isFalse);
    });

    test('당일 → false', () {
      expect(
          shouldRecommendBaselineReset(lastSessionDate: now, now: now), isFalse);
    });
  });

  // =========================================================================
  // baselinePeriodStartIndex
  // =========================================================================
  group('baselinePeriodStartIndex', () {
    final d0 = DateTime(2026, 1, 1);
    DateTime day(int n) => d0.add(Duration(days: n));

    test('공백 없음 → 0', () {
      expect(baselinePeriodStartIndex([day(0), day(30), day(60), day(90)]),
          equals(0));
    });

    test('90일 공백 뒤 세션부터 새 기간', () {
      expect(baselinePeriodStartIndex([day(0), day(30), day(120), day(150)]),
          equals(2));
    });

    test('89일 공백은 재설정 안 함', () {
      expect(baselinePeriodStartIndex([day(0), day(30), day(119)]), equals(0));
    });

    test('공백이 여러 번이면 마지막 공백 이후', () {
      expect(
          baselinePeriodStartIndex(
              [day(0), day(100), day(130), day(300), day(330)]),
          equals(3));
    });

    test('빈 리스트·세션 1개 → 0', () {
      expect(baselinePeriodStartIndex([]), equals(0));
      expect(baselinePeriodStartIndex([day(0)]), equals(0));
    });
  });

  // =========================================================================
  // evaluateChange (통합)
  // =========================================================================
  group('evaluateChange', () {
    final now = DateTime(2026, 3, 1);

    test('정상 진행 (기준선 안착, 최근 상승) → 경고 없음', () {
      final scores = [80.0, 82.0, 84.0, 85.0];
      final result = evaluateChange(
        allScores: scores,
        lastSessionDate: now.subtract(const Duration(days: 7)),
        now: now,
      );
      expect(result.alert, isFalse);
      expect(result.recommendReset, isFalse);
      expect(result.baseline, closeTo(81.0, 0.01));
      expect(result.latestScore, equals(85.0));
      expect(result.delta, isPositive);
    });

    test('경고 발생 (2회 연속 큰 하락)', () {
      // baseline=(85+75)/2=80, 이후 55→50
      final scores = [85.0, 75.0, 55.0, 50.0];
      final result = evaluateChange(
        allScores: scores,
        lastSessionDate: now.subtract(const Duration(days: 7)),
        now: now,
      );
      expect(result.alert, isTrue);
      expect(result.delta, isNegative);
    });

    test('3개월 공백 → 재계산 권유', () {
      final scores = [80.0, 82.0];
      final result = evaluateChange(
        allScores: scores,
        lastSessionDate: now.subtract(const Duration(days: 100)),
        now: now,
      );
      expect(result.recommendReset, isTrue);
    });

    test('90일 공백 뒤 새 기준선으로 판정', () {
      // 이전 기간 [90, 90], 공백 뒤 [60, 62, 64]
      // → 새 baseline = (60+62)/2 = 61, 이전 기준선(90) 대비 하락 경고 없음
      final d0 = DateTime(2026, 1, 1);
      final dates = [0, 30, 150, 180, 210]
          .map((n) => d0.add(Duration(days: n)))
          .toList();
      final result = evaluateChange(
        allScores: [90.0, 90.0, 60.0, 62.0, 64.0],
        sessionDates: dates,
        lastSessionDate: dates.last,
        now: dates.last,
      );
      expect(result.baselinePeriodStart, equals(2));
      expect(result.sessionsInPeriod, equals(3));
      expect(result.baseline, closeTo(61.0, 0.01));
      expect(result.delta, closeTo(3.0, 0.01));
      expect(result.alert, isFalse);
      expect(result.recommendReset, isFalse);
    });

    test('공백 뒤 첫 세션만 있으면 baseline null (재측정 중)', () {
      final d0 = DateTime(2026, 1, 1);
      final dates = [d0, d0.add(const Duration(days: 30)),
          d0.add(const Duration(days: 150))];
      final result = evaluateChange(
        allScores: [90.0, 90.0, 60.0],
        sessionDates: dates,
        lastSessionDate: dates.last,
        now: dates.last,
      );
      expect(result.baseline, isNull);
      expect(result.delta, isNull);
      expect(result.alert, isFalse);
      expect(result.sessionsInPeriod, equals(1));
    });

    test('새 기간 안에서도 하락 경고 동작', () {
      final d0 = DateTime(2026, 1, 1);
      final dates = [0, 30, 150, 180, 210, 240]
          .map((n) => d0.add(Duration(days: n)))
          .toList();
      final result = evaluateChange(
        allScores: [90.0, 90.0, 70.0, 70.0, 50.0, 50.0],
        sessionDates: dates,
        lastSessionDate: dates.last,
        now: dates.last,
      );
      expect(result.baseline, closeTo(70.0, 0.01));
      expect(result.alert, isTrue);
    });

    test('세션 없음 → baseline null, 경고 없음', () {
      final result = evaluateChange(
        allScores: [],
        lastSessionDate: now,
        now: now,
      );
      expect(result.baseline, isNull);
      expect(result.latestScore, isNull);
      expect(result.alert, isFalse);
    });
  });
}
