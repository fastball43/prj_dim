/// 인지 점수 변화 감지 및 기준선(baseline) 관리
///
/// - 처음 2회 평균을 baseline으로 설정
/// - 종합 점수가 baseline 대비 -15점 이상 하락 시 경고
/// - 기준선 이후 최근 2회 연속으로 하락 상태가 확인되면 알림 (단 1회 하락은 경고 안 함)
/// - 3개월 이상 공백 후 새 baseline 재계산 권유, 공백 뒤 첫 세션부터 새 기준선 기간 시작
library change_detection;

/// 기준선 계산에 필요한 최소 세션 수.
const int kBaselineSessionCount = 2;

/// 기준선 대비 경고 임계값 (하락 점수).
const double kAlertThreshold = 15.0;

/// 경고에 필요한 연속 유의미 하락 세션 수 (노이즈 필터).
const int kConsecutiveDeclinesForAlert = 2;

/// baseline 재계산 권유 기준 (일수).
const int kGapDaysForReset = 90;

// ---------------------------------------------------------------------------
// Baseline 계산
// ---------------------------------------------------------------------------

/// 첫 N개 세션으로 baseline 계산.
///
/// [scores]: 시간순 정렬된 종합 인지 점수 리스트
/// [n]: 기준선 계산에 사용할 세션 수 (기본 2)
/// Returns: baseline 점수. 세션이 부족하면 null.
double? computeBaseline(List<double> scores, {int n = kBaselineSessionCount}) {
  if (scores.length < n) return null;
  final subset = scores.take(n);
  return subset.reduce((a, b) => a + b) / n;
}

// ---------------------------------------------------------------------------
// 변화 감지
// ---------------------------------------------------------------------------

/// 단일 점수가 baseline 대비 임계값 이상 하락했는지 확인.
///
/// [score]: 검사할 점수
/// [baseline]: 기준선 점수
/// [threshold]: 하락 임계값 (기본 15점)
bool isSignificantDecline(
  double score,
  double baseline, {
  double threshold = kAlertThreshold,
}) {
  return (baseline - score) >= threshold;
}

/// 최근 [windowSize]개 세션에서 연속 하락 횟수를 계산.
///
/// [recentScores]: 시간순 정렬된 최근 점수 리스트 (최신 포함)
/// Returns: 연속 하락 횟수 (현재 점수 기준 뒤로 셈)
int consecutiveDeclineCount(List<double> recentScores) {
  if (recentScores.length < 2) return 0;
  int count = 0;
  for (int i = recentScores.length - 1; i > 0; i--) {
    if (recentScores[i] < recentScores[i - 1]) {
      count++;
    } else {
      break;
    }
  }
  return count;
}

/// 경고 신호 발생 여부 판단.
///
/// 조건: 기준선 이후 최근 [kConsecutiveDeclinesForAlert]회 세션이 **모두**
/// baseline 대비 [kAlertThreshold] 이상 낮을 것.
///
/// 한 번의 컨디션 난조(1회 하락)는 무시하되, 하락한 상태가 유지되면
/// (예: 80, 80 → 50, 50) 점수가 더 떨어지지 않아도 경고한다.
/// 직전 대비 소폭 등락(예: 50 → 49)은 판정에 영향을 주지 않는다.
///
/// [allScores]: 시간순 정렬된 전체 세션 점수 (baseline 계산 포함)
/// [baseline]: 미리 계산된 baseline (없으면 null → 경고 없음)
/// Returns: 경고 발생 여부
bool shouldAlert({
  required List<double> allScores,
  required double? baseline,
}) {
  if (baseline == null ||
      allScores.length < kBaselineSessionCount + kConsecutiveDeclinesForAlert) {
    return false;
  }

  final recent =
      allScores.sublist(allScores.length - kConsecutiveDeclinesForAlert);
  return recent.every((score) => isSignificantDecline(score, baseline));
}

// ---------------------------------------------------------------------------
// 공백 감지 (3개월 이상)
// ---------------------------------------------------------------------------

/// 현재 기준선 기간이 시작되는 세션 인덱스.
///
/// 세션 사이 공백이 [gapDays]일 이상이면 그 다음 세션부터 새 기준선 기간이
/// 시작된다. 공백이 여러 번이면 가장 마지막 공백 이후가 현재 기간이다.
///
/// [sessionDates]: 시간순 정렬된 세션 날짜
/// Returns: 현재 기준선 기간의 첫 세션 인덱스 (공백이 없으면 0)
int baselinePeriodStartIndex(
  List<DateTime> sessionDates, {
  int gapDays = kGapDaysForReset,
}) {
  for (int i = sessionDates.length - 1; i > 0; i--) {
    if (sessionDates[i].difference(sessionDates[i - 1]).inDays >= gapDays) {
      return i;
    }
  }
  return 0;
}

/// 마지막 세션 이후 공백이 [kGapDaysForReset]일 이상인지 확인.
///
/// [lastSessionDate]: 마지막 세션 날짜
/// [now]: 현재 날짜 (테스트 주입용, 기본값 DateTime.now())
/// Returns: 재계산 권유 여부
bool shouldRecommendBaselineReset({
  required DateTime lastSessionDate,
  DateTime? now,
}) {
  final reference = now ?? DateTime.now();
  final gap = reference.difference(lastSessionDate).inDays;
  return gap >= kGapDaysForReset;
}

// ---------------------------------------------------------------------------
// ChangeDetectionResult — 최종 판정 결과
// ---------------------------------------------------------------------------

/// 변화 감지 판정 결과.
class ChangeDetectionResult {
  /// 현재 사용 중인 baseline 점수.
  final double? baseline;

  /// 최신 세션 점수.
  final double? latestScore;

  /// baseline 대비 변화량 (양수 = 개선, 음수 = 하락).
  final double? delta;

  /// 경고 신호 발생 여부.
  final bool alert;

  /// baseline 재계산 권유 여부 (다음 세션부터 새 기준선 기간 시작).
  final bool recommendReset;

  /// 현재 기준선 기간의 첫 세션 인덱스 (전체 세션 기준).
  final int baselinePeriodStart;

  /// 현재 기준선 기간에 속한 세션 수.
  final int sessionsInPeriod;

  const ChangeDetectionResult({
    this.baseline,
    this.latestScore,
    this.delta,
    required this.alert,
    required this.recommendReset,
    this.baselinePeriodStart = 0,
    this.sessionsInPeriod = 0,
  });

  @override
  String toString() => 'ChangeDetectionResult('
      'baseline=$baseline, latest=$latestScore, '
      'delta=$delta, alert=$alert, reset=$recommendReset, '
      'periodStart=$baselinePeriodStart, inPeriod=$sessionsInPeriod)';
}

/// 전체 변화 감지 판정을 수행.
///
/// [sessionDates]가 주어지면 [kGapDaysForReset]일 이상 공백 뒤의 세션부터
/// 새 기준선 기간으로 보고, 그 기간의 점수만으로 baseline·경고를 판정한다.
///
/// [allScores]: 시간순 정렬된 전체 세션 점수
/// [lastSessionDate]: 마지막 세션 날짜 (공백 계산용)
/// [sessionDates]: [allScores]와 같은 순서·길이의 세션 날짜 (기준선 재설정용)
/// [now]: 현재 날짜 (테스트 주입용)
/// Returns: [ChangeDetectionResult]
ChangeDetectionResult evaluateChange({
  required List<double> allScores,
  required DateTime lastSessionDate,
  List<DateTime>? sessionDates,
  DateTime? now,
}) {
  assert(sessionDates == null || sessionDates.length == allScores.length,
      'sessionDates must match allScores length');
  final start =
      sessionDates != null ? baselinePeriodStartIndex(sessionDates) : 0;
  final periodScores = allScores.sublist(start);

  final baseline = computeBaseline(periodScores);
  final latest = periodScores.isNotEmpty ? periodScores.last : null;
  final delta = (baseline != null && latest != null) ? latest - baseline : null;

  final alert = shouldAlert(allScores: periodScores, baseline: baseline);
  final reset = shouldRecommendBaselineReset(
      lastSessionDate: lastSessionDate, now: now);

  return ChangeDetectionResult(
    baseline: baseline,
    latestScore: latest,
    delta: delta,
    alert: alert,
    recommendReset: reset,
    baselinePeriodStart: start,
    sessionsInPeriod: periodScores.length,
  );
}
