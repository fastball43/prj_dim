/// 라이프스타일 위험도 점수 알고리즘
///
/// 8개 항목 sub-score(0-10) → 가중합 → 기저 보정 → 0-100 종합 점수
library lifestyle_scoring;

// ---------------------------------------------------------------------------
// Sub-score 계산 함수 (각 항목 0-10점)
// ---------------------------------------------------------------------------

/// 1. 수면 점수
///
/// [sleepHours]: 평균 수면 시간
/// [sleepQuality]: 주관적 수면 질 (1-5)
/// Returns: 0-10
double scoreSleep({required double sleepHours, required int sleepQuality}) {
  assert(sleepQuality >= 1 && sleepQuality <= 5,
      'sleepQuality must be 1-5, got $sleepQuality');

  // 수면 시간 기본 점수
  double hourScore;
  if (sleepHours >= 7 && sleepHours <= 8) {
    hourScore = 10.0;
  } else if ((sleepHours >= 6 && sleepHours < 7) || sleepHours > 8) {
    hourScore = 7.0;
  } else if (sleepHours >= 5 && sleepHours < 6) {
    hourScore = 4.0;
  } else {
    hourScore = 0.0; // ≤4h
  }

  // 수면 질 가중 20%
  final qualityScore = (sleepQuality - 1) / 4 * 10; // 1→0, 5→10
  return (hourScore * 0.80 + qualityScore * 0.20).clamp(0.0, 10.0);
}

/// 2. 신체 활동 점수
///
/// [exerciseDays]: 주당 중강도 운동 일수
/// [exerciseMinutes]: 1회 평균 운동 시간(분)
/// Returns: 0-10
double scoreExercise(
    {required int exerciseDays, required int exerciseMinutes}) {
  assert(exerciseDays >= 0 && exerciseDays <= 7);
  assert(exerciseMinutes >= 0);

  if (exerciseDays >= 5 && exerciseMinutes >= 30) return 10.0;
  if (exerciseDays >= 3) return 7.0;
  if (exerciseDays >= 1) return 4.0;
  return 0.0;
}

/// 3. 식습관 점수 (MIND diet)
///
/// [checkedItems]: MIND diet 10개 항목 중 해당 항목 수 (0-10)
/// Returns: 0-10
double scoreDiet({required int checkedItems}) {
  assert(checkedItems >= 0 && checkedItems <= 10,
      'checkedItems must be 0-10, got $checkedItems');
  return checkedItems.toDouble(); // 1:1 매핑
}

/// 사회 활동·정신 자극 빈도 코드 → 점수 매핑.
///
/// [freqCode]: 0=거의없음, 1=주1, 2=주2-3, 3=주4-6, 4=매일
double _freqToScore(int freqCode) {
  switch (freqCode) {
    case 4:
      return 10.0; // 매일
    case 3:
      return 8.0;  // 주4-6
    case 2:
      return 5.0;  // 주2-3
    case 1:
      return 3.0;  // 주1
    default:
      return 0.0;  // 거의없음
  }
}

/// 4. 사회 활동 점수
///
/// [freqCode]: 0=거의없음, 1=주1, 2=주2-3, 3=주4-6, 4=매일
/// Returns: 0-10
double scoreSocial({required int freqCode}) {
  assert(freqCode >= 0 && freqCode <= 4, 'freqCode must be 0-4');
  return _freqToScore(freqCode);
}

/// 5. 정신 자극 점수
///
/// [freqCode]: 0=거의없음, 1=주1, 2=주2-3, 3=주4-6, 4=매일
/// Returns: 0-10
double scoreCognitiveStim({required int freqCode}) {
  assert(freqCode >= 0 && freqCode <= 4, 'freqCode must be 0-4');
  return _freqToScore(freqCode);
}

/// 6. 혈관 건강 점수
///
/// [systolicBp]: 수축기 혈압 (mmHg). null이면 중간값 적용
/// [hasDiabetes]: 당뇨 여부 (당뇨 시 -2점 패널티)
/// Returns: 0-10
double scoreVascular({int? systolicBp, required bool hasDiabetes}) {
  double bpScore;
  if (systolicBp == null) {
    bpScore = 6.0; // 미입력 시 중간값
  } else if (systolicBp < 120) {
    bpScore = 10.0;
  } else if (systolicBp < 140) {
    bpScore = 6.0;
  } else {
    bpScore = 2.0;
  }

  final penalty = hasDiabetes ? 2.0 : 0.0;
  return (bpScore - penalty).clamp(0.0, 10.0);
}

/// 7. 청각 점수
///
/// [hearingDifficulty]: 0=없음, 1=가끔, 2=자주, 3=심각(보청기 미사용)
/// Returns: 0-10
double scoreHearing({required int hearingDifficulty}) {
  assert(hearingDifficulty >= 0 && hearingDifficulty <= 3);
  switch (hearingDifficulty) {
    case 0:
      return 10.0;
    case 1:
      return 6.0;
    case 2:
      return 2.0;
    default:
      return 0.0; // 3: 심각·보청기 미사용
  }
}

/// 8. 음주/흡연 점수
///
/// [alcoholFreq]: 0=없음, 1=월1-3, 2=주1-2, 3=주3+
/// [isSmoker]: 흡연 여부
/// Returns: 0-10
double scoreSubstance(
    {required int alcoholFreq, required bool isSmoker}) {
  assert(alcoholFreq >= 0 && alcoholFreq <= 3);

  double score = 10.0;
  if (isSmoker) score -= 4.0;

  switch (alcoholFreq) {
    case 3:
      score -= 3.0;
      break;
    case 2:
      score -= 1.0;
      break;
    default:
      break; // 0,1: 패널티 없음
  }

  return score.clamp(0.0, 10.0);
}

// ---------------------------------------------------------------------------
// 8개 항목 sub-score 일괄 계산
// ---------------------------------------------------------------------------

/// 라이프스타일 입력 데이터 모델.
class LifestyleInput {
  final double sleepHours;
  final int sleepQuality;         // 1-5
  final int exerciseDays;
  final int exerciseMinutes;
  final int dietCheckedItems;     // 0-10
  final int socialFreqCode;       // 0-4
  final int cognitiveStimFreqCode; // 0-4
  final int? systolicBp;          // null = 미입력
  final bool hasDiabetes;
  final int hearingDifficulty;    // 0-3
  final int alcoholFreq;          // 0-3
  final bool isSmoker;

  const LifestyleInput({
    required this.sleepHours,
    required this.sleepQuality,
    required this.exerciseDays,
    required this.exerciseMinutes,
    required this.dietCheckedItems,
    required this.socialFreqCode,
    required this.cognitiveStimFreqCode,
    this.systolicBp,
    required this.hasDiabetes,
    required this.hearingDifficulty,
    required this.alcoholFreq,
    required this.isSmoker,
  });
}

/// 8개 항목 이름 상수 (Map key).
enum LifestyleItem {
  sleep,
  exercise,
  diet,
  social,
  cognitiveStim,
  vascular,
  substance,
  hearing,
}

/// [LifestyleInput]으로부터 8개 항목 sub-score Map 계산.
///
/// 항목 순서: sleep(0), exercise(1), diet(2), social(3),
///           cognitiveStim(4), vascular(5), substance(6), hearing(7)
/// Returns: {항목 인덱스 → 0-10 점수}
Map<int, double> computeSubScores(LifestyleInput input) {
  return {
    0: scoreSleep(
        sleepHours: input.sleepHours, sleepQuality: input.sleepQuality),
    1: scoreExercise(
        exerciseDays: input.exerciseDays,
        exerciseMinutes: input.exerciseMinutes),
    2: scoreDiet(checkedItems: input.dietCheckedItems),
    3: scoreSocial(freqCode: input.socialFreqCode),
    4: scoreCognitiveStim(freqCode: input.cognitiveStimFreqCode),
    5: scoreVascular(
        systolicBp: input.systolicBp, hasDiabetes: input.hasDiabetes),
    6: scoreSubstance(
        alcoholFreq: input.alcoholFreq, isSmoker: input.isSmoker),
    7: scoreHearing(hearingDifficulty: input.hearingDifficulty),
  };
}

// ---------------------------------------------------------------------------
// 가중합 계산
// ---------------------------------------------------------------------------

/// Lancet 2024 기반 항목별 가중치.
/// 순서: sleep, exercise, diet, social, cognitiveStim, vascular, substance, hearing
/// (주의: 인덱스 5=vascular, 6=substance, 7=hearing)
const List<double> lifestyleWeights = [
  0.15, // 0: sleep
  0.18, // 1: exercise
  0.12, // 2: diet
  0.13, // 3: social
  0.13, // 4: cognitiveStim
  0.15, // 5: vascular
  0.08, // 6: substance
  0.06, // 7: hearing
];

/// sub-score(0-10) 가중합 → 0-100 raw score 계산.
///
/// [subScores]: {항목 인덱스 → 0-10 점수}. 결측 항목은 제외 후 가중치 재배분.
/// Returns: 0-100 raw score (기저 보정 전)
double weightedLifestyleScore(Map<int, double> subScores) {
  assert(subScores.isNotEmpty, 'subScores must not be empty');

  double weightedSum = 0;
  double totalWeight = 0;

  for (int i = 0; i < lifestyleWeights.length; i++) {
    if (subScores.containsKey(i)) {
      weightedSum += subScores[i]! * lifestyleWeights[i];
      totalWeight += lifestyleWeights[i];
    }
  }

  // sub-score가 0-10 스케일이므로 × 10 → 0-100
  return (weightedSum / totalWeight) * 10;
}

// ---------------------------------------------------------------------------
// 기저 위험 보정
// ---------------------------------------------------------------------------

/// 온보딩 데이터 기반 기저 위험 보정값 계산.
///
/// [age]: 사용자 나이
/// [familyHistory]: 1촌 치매 가족력
/// [educationYears]: 총 교육 연수
/// Returns: 0.7-1.0 보정 계수
double computeBaselineModifier({
  required int age,
  required bool familyHistory,
  required int educationYears,
}) {
  double mod = 1.0;
  if (familyHistory) mod -= 0.08;
  if (age >= 75) {
    mod -= 0.10;
  } else if (age >= 65) {
    mod -= 0.05;
  }
  if (educationYears < 9) mod -= 0.05; // 중졸 이하
  return mod.clamp(0.70, 1.0);
}

// ---------------------------------------------------------------------------
// 종합 라이프스타일 점수
// ---------------------------------------------------------------------------

/// 종합 라이프스타일 점수 계산.
///
/// [subScores]: {항목 인덱스 → 0-10 점수}
/// [baselineModifier]: [computeBaselineModifier] 결과
/// Returns: 0-100 점수
double lifestyleScore({
  required Map<int, double> subScores,
  required double baselineModifier,
}) {
  final raw = weightedLifestyleScore(subScores);
  return (raw * baselineModifier).clamp(0.0, 100.0);
}

// ---------------------------------------------------------------------------
// 점수 해석
// ---------------------------------------------------------------------------

/// 라이프스타일 점수 등급.
enum LifestyleTier { good, caution, needsAttention }

/// 점수 → 등급 매핑.
LifestyleTier lifestyleTier(double score) {
  if (score >= 75) return LifestyleTier.good;
  if (score >= 50) return LifestyleTier.caution;
  return LifestyleTier.needsAttention;
}

/// 등급별 한국어 메시지.
String lifestyleMessage(LifestyleTier tier) {
  switch (tier) {
    case LifestyleTier.good:
      return '현재 생활 습관이 뇌 건강을 잘 지키고 있어요';
    case LifestyleTier.caution:
      return '일부 영역에서 개선하면 위험을 낮출 수 있어요';
    case LifestyleTier.needsAttention:
      return '전문가 상담과 함께 생활 습관 개선을 권장해요';
  }
}

// ---------------------------------------------------------------------------
// 대시보드 통합 점수
// ---------------------------------------------------------------------------

/// 대시보드 통합 건강 점수.
///
/// [cognitiveScore]: 최근 종합 인지 점수 (0-100). null이면 라이프스타일만 사용.
/// [lifestyleScoreValue]: 최근 라이프스타일 점수 (0-100)
/// Returns: 0-100 통합 점수
double integratedHealthScore({
  double? cognitiveScore,
  required double lifestyleScoreValue,
}) {
  if (cognitiveScore == null) return lifestyleScoreValue;
  return cognitiveScore * 0.40 + lifestyleScoreValue * 0.60;
}
