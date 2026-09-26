/// 인지 기능 테스트 점수 계산 모듈
///
/// 4종 테스트(T1~T4)의 원점수를 0-100 정규화 점수로 변환하고,
/// 종합 인지 점수를 산출한다.
library cognitive_scoring;

// ---------------------------------------------------------------------------
// T1. 기억력 (Word Recall)
// ---------------------------------------------------------------------------

/// T1 지연 회상 점수 계산.
///
/// [correctDelayed]: 지연 회상 정답 수 (0-5)
/// Returns: 0-100 정규화 점수
double scoreT1({required int correctDelayed}) {
  assert(correctDelayed >= 0 && correctDelayed <= 5,
      'correctDelayed must be 0-5, got $correctDelayed');
  return (correctDelayed / 5) * 100;
}

/// T1 재인(recognition) 회상 정답 수 계산.
///
/// 보기(목표 단어 + 오답 단어) 중에서 고르는 방식이므로, 보기를 모두 고르면
/// 만점이 되지 않도록 오답 선택 1개당 1점을 감점한다 (hits − false alarms).
///
/// [selected]: 사용자가 선택한 단어 집합
/// [targets]: 제시했던 목표 단어 목록
/// Returns: 0 ~ targets.length
int recallCorrectCount({
  required Set<String> selected,
  required List<String> targets,
}) {
  final hits = selected.where(targets.contains).length;
  final falseAlarms = selected.length - hits;
  return (hits - falseAlarms).clamp(0, targets.length);
}

// ---------------------------------------------------------------------------
// T2. 언어 유창성 (Verbal Fluency)
// ---------------------------------------------------------------------------

/// 연령대별 동물 이름 유창성 기준값.
const Map<String, int> _fluencyAgeNorms = {
  '40s': 18,
  '50s': 16,
  '60s': 14,
  '70s+': 12,
};

/// 연령 → 유창성 기준값 반환.
int fluencyAgeNorm(int age) {
  if (age < 50) return _fluencyAgeNorms['40s']!;
  if (age < 60) return _fluencyAgeNorms['50s']!;
  if (age < 70) return _fluencyAgeNorms['60s']!;
  return _fluencyAgeNorms['70s+']!;
}

/// T2 언어 유창성 점수 계산.
///
/// [wordCount]: 유효 단어 수 (중복·비실존 동물 제외 후)
/// [age]: 사용자 나이 (연령 보정에 사용)
/// Returns: 0-100 정규화 점수 (100 초과 clamp)
double scoreT2({required int wordCount, required int age}) {
  assert(wordCount >= 0, 'wordCount must be >= 0, got $wordCount');
  final norm = fluencyAgeNorm(age);
  return (wordCount / norm * 100).clamp(0.0, 100.0);
}

// ---------------------------------------------------------------------------
// T3. 주의력 — 숫자 폭 (Digit Span)
// ---------------------------------------------------------------------------

/// T3 숫자 폭 점수 계산.
///
/// [forwardSpan]: Forward 마지막 성공 자릿수 (3-7, 최솟값 3 기준)
/// [backwardSpan]: Backward 마지막 성공 자릿수 (2-6, 최솟값 2 기준)
/// Returns: 0-100 정규화 점수 (이론 최대 130 → clamp 100)
double scoreT3({required int forwardSpan, required int backwardSpan}) {
  assert(forwardSpan >= 0, 'forwardSpan must be >= 0');
  assert(backwardSpan >= 0, 'backwardSpan must be >= 0');
  final raw = (forwardSpan * 10 + backwardSpan * 10).toDouble();
  return raw.clamp(0.0, 100.0);
}

// ---------------------------------------------------------------------------
// T4. 처리 속도 — 연결 잇기 (Trail Making 변형)
// ---------------------------------------------------------------------------

/// T4 Trail Making 점수 계산.
///
/// [timeA]: Trail A 완료 시간(초). 15초=100점, 55초=0점
/// [timeB]: Trail B 완료 시간(초). 30초=100점, 97초=0점
/// Returns: 0-100 정규화 점수
double scoreT4({required double timeA, required double timeB}) {
  assert(timeA > 0, 'timeA must be > 0, got $timeA');
  assert(timeB > 0, 'timeB must be > 0, got $timeB');
  final scoreA = (100 - ((timeA - 15) * 2.5)).clamp(0.0, 100.0);
  final scoreB = (100 - ((timeB - 30) * 1.5)).clamp(0.0, 100.0);
  return (scoreA + scoreB) / 2;
}

// ---------------------------------------------------------------------------
// 종합 인지 점수
// ---------------------------------------------------------------------------

/// 각 테스트 가중치.
const double _wT1 = 0.30;
const double _wT2 = 0.20;
const double _wT3 = 0.25;
const double _wT4 = 0.25;

/// 종합 인지 점수 계산.
///
/// null 값은 결측 처리: 나머지 항목 가중치를 비례 배분.
/// 모든 항목이 null이면 null 반환.
double? compositeScore({
  double? t1Score,
  double? t2Score,
  double? t3Score,
  double? t4Score,
}) {
  // (weight, score) 쌍으로 관리 — 동일 가중치 항목(T3·T4=0.25)의 키 충돌 방지
  final entries = <(double, double)>[];
  if (t1Score != null) entries.add((_wT1, t1Score));
  if (t2Score != null) entries.add((_wT2, t2Score));
  if (t3Score != null) entries.add((_wT3, t3Score));
  if (t4Score != null) entries.add((_wT4, t4Score));

  if (entries.isEmpty) return null;

  final totalWeight = entries.fold(0.0, (s, e) => s + e.$1);
  final weightedSum = entries.fold(0.0, (s, e) => s + e.$1 * e.$2);
  return weightedSum / totalWeight;
}

// ---------------------------------------------------------------------------
// 단어 세트 관리
// ---------------------------------------------------------------------------

/// 회차(sessionCount)에 따라 A/B 세트를 교대 반환.
///
/// 홀수 회차 → Set A, 짝수 회차 → Set B
String wordSetForSession(int sessionCount) =>
    sessionCount.isOdd ? 'A' : 'B';

const List<String> wordSetA = ['사과', '기차', '하늘', '의자', '연필'];
const List<String> wordSetB = ['바다', '시계', '나무', '구름', '장갑'];

List<String> getWordSet(String setId) =>
    setId == 'B' ? wordSetB : wordSetA;
