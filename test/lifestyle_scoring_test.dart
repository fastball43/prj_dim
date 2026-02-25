import 'package:test/test.dart';
import 'package:prj_dim/core/algorithms/lifestyle_scoring.dart';

void main() {
  // =========================================================================
  // 1. 수면 점수
  // =========================================================================
  group('scoreSleep', () {
    test('이상적: 7.5시간, 질=5 → 10점', () {
      expect(
          scoreSleep(sleepHours: 7.5, sleepQuality: 5), closeTo(10.0, 0.01));
    });

    test('7-8시간, 질=3 → hourScore=10, qualityScore=5 → 8*0.8+5*0.2=7.4', () {
      // 10*0.8 + 5.0*0.2 = 8.0 + 1.0 = 9.0 (quality=(3-1)/4*10=5)
      expect(
          scoreSleep(sleepHours: 7.5, sleepQuality: 3), closeTo(9.0, 0.01));
    });

    test('6시간, 질=1 → hourScore=7, qualityScore=0 → 5.6', () {
      // 7*0.8 + 0*0.2 = 5.6
      expect(
          scoreSleep(sleepHours: 6.0, sleepQuality: 1), closeTo(5.6, 0.01));
    });

    test('5시간, 질=1 → hourScore=4 → 3.2', () {
      // 4*0.8 + 0*0.2 = 3.2
      expect(
          scoreSleep(sleepHours: 5.0, sleepQuality: 1), closeTo(3.2, 0.01));
    });

    test('4시간 이하, 질=1 → 0점', () {
      expect(
          scoreSleep(sleepHours: 4.0, sleepQuality: 1), closeTo(0.0, 0.01));
    });

    test('9시간 초과(과수면), 질=5 → hourScore=7', () {
      // 7*0.8 + 10*0.2 = 5.6 + 2.0 = 7.6
      expect(
          scoreSleep(sleepHours: 10.0, sleepQuality: 5), closeTo(7.6, 0.01));
    });
  });

  // =========================================================================
  // 2. 신체 활동
  // =========================================================================
  group('scoreExercise', () {
    test('주5일 이상, 30분 이상 → 10점', () {
      expect(scoreExercise(exerciseDays: 5, exerciseMinutes: 30), equals(10.0));
      expect(scoreExercise(exerciseDays: 7, exerciseMinutes: 60), equals(10.0));
    });

    test('주5일이지만 30분 미만 → 7점', () {
      expect(scoreExercise(exerciseDays: 5, exerciseMinutes: 20), equals(7.0));
    });

    test('주3-4일 → 7점', () {
      expect(scoreExercise(exerciseDays: 3, exerciseMinutes: 0), equals(7.0));
      expect(
          scoreExercise(exerciseDays: 4, exerciseMinutes: 45), equals(7.0));
    });

    test('주1-2일 → 4점', () {
      expect(scoreExercise(exerciseDays: 1, exerciseMinutes: 60), equals(4.0));
      expect(scoreExercise(exerciseDays: 2, exerciseMinutes: 10), equals(4.0));
    });

    test('운동 없음 → 0점', () {
      expect(scoreExercise(exerciseDays: 0, exerciseMinutes: 0), equals(0.0));
    });
  });

  // =========================================================================
  // 3. 식습관 (MIND diet)
  // =========================================================================
  group('scoreDiet', () {
    test('10개 체크 → 10점', () => expect(scoreDiet(checkedItems: 10), equals(10.0)));
    test('0개 체크 → 0점', () => expect(scoreDiet(checkedItems: 0), equals(0.0)));
    test('5개 체크 → 5점', () => expect(scoreDiet(checkedItems: 5), equals(5.0)));
  });

  // =========================================================================
  // 4 & 5. 사회 활동 / 정신 자극 (공통 로직)
  // =========================================================================
  group('scoreSocial / scoreCognitiveStim', () {
    final testCases = [
      (code: 4, expected: 10.0, label: '매일'),
      (code: 3, expected: 8.0, label: '주4-6'),
      (code: 2, expected: 5.0, label: '주2-3'),
      (code: 1, expected: 3.0, label: '주1'),
      (code: 0, expected: 0.0, label: '거의없음'),
    ];

    for (final tc in testCases) {
      test('social: ${tc.label}(${tc.code}) → ${tc.expected}점', () {
        expect(scoreSocial(freqCode: tc.code), equals(tc.expected));
      });
      test('cogStim: ${tc.label}(${tc.code}) → ${tc.expected}점', () {
        expect(scoreCognitiveStim(freqCode: tc.code), equals(tc.expected));
      });
    }
  });

  // =========================================================================
  // 6. 혈관 건강
  // =========================================================================
  group('scoreVascular', () {
    test('정상 혈압(<120), 당뇨없음 → 10점', () {
      expect(scoreVascular(systolicBp: 110, hasDiabetes: false), equals(10.0));
    });

    test('정상 혈압, 당뇨있음 → 8점', () {
      expect(scoreVascular(systolicBp: 115, hasDiabetes: true), equals(8.0));
    });

    test('주의 혈압(120-139), 당뇨없음 → 6점', () {
      expect(scoreVascular(systolicBp: 130, hasDiabetes: false), equals(6.0));
    });

    test('주의 혈압, 당뇨있음 → 4점', () {
      expect(scoreVascular(systolicBp: 130, hasDiabetes: true), equals(4.0));
    });

    test('고혈압(≥140), 당뇨없음 → 2점', () {
      expect(scoreVascular(systolicBp: 150, hasDiabetes: false), equals(2.0));
    });

    test('고혈압, 당뇨있음 → 0 clamp', () {
      expect(scoreVascular(systolicBp: 160, hasDiabetes: true), equals(0.0));
    });

    test('혈압 미입력(null) → 중간값 6', () {
      expect(scoreVascular(hasDiabetes: false), equals(6.0));
    });
  });

  // =========================================================================
  // 7. 청각
  // =========================================================================
  group('scoreHearing', () {
    test('없음(0) → 10점', () => expect(scoreHearing(hearingDifficulty: 0), equals(10.0)));
    test('가끔(1) → 6점', () => expect(scoreHearing(hearingDifficulty: 1), equals(6.0)));
    test('자주(2) → 2점', () => expect(scoreHearing(hearingDifficulty: 2), equals(2.0)));
    test('심각(3) → 0점', () => expect(scoreHearing(hearingDifficulty: 3), equals(0.0)));
  });

  // =========================================================================
  // 8. 음주/흡연
  // =========================================================================
  group('scoreSubstance', () {
    test('비음주·비흡연 → 10점', () {
      expect(scoreSubstance(alcoholFreq: 0, isSmoker: false), equals(10.0));
    });

    test('흡연만 → 6점 (10-4)', () {
      expect(scoreSubstance(alcoholFreq: 0, isSmoker: true), equals(6.0));
    });

    test('주1-2음주, 비흡연 → 9점 (10-1)', () {
      expect(scoreSubstance(alcoholFreq: 2, isSmoker: false), equals(9.0));
    });

    test('주3+음주, 비흡연 → 7점 (10-3)', () {
      expect(scoreSubstance(alcoholFreq: 3, isSmoker: false), equals(7.0));
    });

    test('주3+음주, 흡연 → 3점 (10-4-3)', () {
      expect(scoreSubstance(alcoholFreq: 3, isSmoker: true), equals(3.0));
    });

    test('월1-3음주(1), 흡연 → 6점 (10-4-0=6, freqCode=1 패널티없음)', () {
      expect(scoreSubstance(alcoholFreq: 1, isSmoker: true), equals(6.0));
    });
  });

  // =========================================================================
  // computeBaselineModifier
  // =========================================================================
  group('computeBaselineModifier', () {
    test('위험 인자 없음, 65세 미만 → 1.0', () {
      expect(
        computeBaselineModifier(
            age: 50, familyHistory: false, educationYears: 12),
        closeTo(1.0, 0.001),
      );
    });

    test('가족력 있음 → 0.92', () {
      expect(
        computeBaselineModifier(
            age: 50, familyHistory: true, educationYears: 12),
        closeTo(0.92, 0.001),
      );
    });

    test('65세 이상 → -0.05', () {
      expect(
        computeBaselineModifier(
            age: 67, familyHistory: false, educationYears: 12),
        closeTo(0.95, 0.001),
      );
    });

    test('75세 이상 → -0.10', () {
      expect(
        computeBaselineModifier(
            age: 78, familyHistory: false, educationYears: 12),
        closeTo(0.90, 0.001),
      );
    });

    test('교육연수 8년 이하 → -0.05', () {
      expect(
        computeBaselineModifier(
            age: 50, familyHistory: false, educationYears: 8),
        closeTo(0.95, 0.001),
      );
    });

    test('모든 위험 인자: 75세+, 가족력, 저교육 → 0.77 → clamp 0.77', () {
      // 1.0 - 0.10 - 0.08 - 0.05 = 0.77
      expect(
        computeBaselineModifier(
            age: 80, familyHistory: true, educationYears: 6),
        closeTo(0.77, 0.001),
      );
    });

    test('최솟값 clamp: 극단적 조합 → 0.70 최솟값', () {
      // 이론상 하한이 0.70
      final mod = computeBaselineModifier(
          age: 80, familyHistory: true, educationYears: 6);
      expect(mod, greaterThanOrEqualTo(0.70));
    });
  });

  // =========================================================================
  // weightedLifestyleScore / lifestyleScore
  // =========================================================================
  group('weightedLifestyleScore', () {
    test('모든 항목 10점 → 100점', () {
      final subScores = {
        for (int i = 0; i < 8; i++) i: 10.0,
      };
      expect(weightedLifestyleScore(subScores), closeTo(100.0, 0.01));
    });

    test('모든 항목 0점 → 0점', () {
      final subScores = {
        for (int i = 0; i < 8; i++) i: 0.0,
      };
      expect(weightedLifestyleScore(subScores), closeTo(0.0, 0.01));
    });

    test('모든 항목 5점 → 50점', () {
      final subScores = {
        for (int i = 0; i < 8; i++) i: 5.0,
      };
      expect(weightedLifestyleScore(subScores), closeTo(50.0, 0.01));
    });

    test('결측 처리: exercise(1)만 10점, 나머지 결측 → 100점', () {
      // totalWeight=0.18, weightedSum=10*0.18=1.8 → 1.8/0.18*10 = 100
      expect(weightedLifestyleScore({1: 10.0}), closeTo(100.0, 0.01));
    });
  });

  group('lifestyleScore', () {
    test('완벽 입력, 보정=1.0 → 100점', () {
      final subScores = {for (int i = 0; i < 8; i++) i: 10.0};
      expect(lifestyleScore(subScores: subScores, baselineModifier: 1.0),
          closeTo(100.0, 0.01));
    });

    test('완벽 입력, 보정=0.92 → 92점', () {
      final subScores = {for (int i = 0; i < 8; i++) i: 10.0};
      expect(lifestyleScore(subScores: subScores, baselineModifier: 0.92),
          closeTo(92.0, 0.01));
    });

    test('50점 raw, 보정=0.80 → 40점', () {
      final subScores = {for (int i = 0; i < 8; i++) i: 5.0};
      expect(lifestyleScore(subScores: subScores, baselineModifier: 0.80),
          closeTo(40.0, 0.01));
    });
  });

  // =========================================================================
  // 점수 해석 (lifestyleTier / lifestyleMessage)
  // =========================================================================
  group('lifestyleTier', () {
    test('75점 → good', () => expect(lifestyleTier(75), equals(LifestyleTier.good)));
    test('100점 → good', () => expect(lifestyleTier(100), equals(LifestyleTier.good)));
    test('74점 → caution', () => expect(lifestyleTier(74), equals(LifestyleTier.caution)));
    test('50점 → caution', () => expect(lifestyleTier(50), equals(LifestyleTier.caution)));
    test('49점 → needsAttention', () => expect(lifestyleTier(49), equals(LifestyleTier.needsAttention)));
    test('0점 → needsAttention', () => expect(lifestyleTier(0), equals(LifestyleTier.needsAttention)));
  });

  // =========================================================================
  // 대시보드 통합 점수
  // =========================================================================
  group('integratedHealthScore', () {
    test('인지 100, 라이프 100 → 100', () {
      expect(
          integratedHealthScore(
              cognitiveScore: 100, lifestyleScoreValue: 100),
          closeTo(100.0, 0.01));
    });

    test('인지 0, 라이프 100 → 60', () {
      expect(
          integratedHealthScore(
              cognitiveScore: 0, lifestyleScoreValue: 100),
          closeTo(60.0, 0.01));
    });

    test('인지 100, 라이프 0 → 40', () {
      expect(
          integratedHealthScore(
              cognitiveScore: 100, lifestyleScoreValue: 0),
          closeTo(40.0, 0.01));
    });

    test('인지 null → 라이프 점수만 사용', () {
      expect(
          integratedHealthScore(lifestyleScoreValue: 70),
          closeTo(70.0, 0.01));
    });

    test('인지 80, 라이프 60 → 68', () {
      // 80*0.4 + 60*0.6 = 32 + 36 = 68
      expect(
          integratedHealthScore(
              cognitiveScore: 80, lifestyleScoreValue: 60),
          closeTo(68.0, 0.01));
    });
  });

  // =========================================================================
  // computeSubScores 통합
  // =========================================================================
  group('computeSubScores', () {
    test('최적 입력 → 모든 항목 높은 점수', () {
      final input = LifestyleInput(
        sleepHours: 7.5,
        sleepQuality: 5,
        exerciseDays: 5,
        exerciseMinutes: 45,
        dietCheckedItems: 10,
        socialFreqCode: 4,
        cognitiveStimFreqCode: 4,
        systolicBp: 110,
        hasDiabetes: false,
        hearingDifficulty: 0,
        alcoholFreq: 0,
        isSmoker: false,
      );
      final scores = computeSubScores(input);
      expect(scores.length, equals(8));
      scores.forEach((_, v) => expect(v, greaterThanOrEqualTo(8.0)));
    });

    test('최악 입력 → 모든 항목 낮은 점수', () {
      final input = LifestyleInput(
        sleepHours: 3.0,
        sleepQuality: 1,
        exerciseDays: 0,
        exerciseMinutes: 0,
        dietCheckedItems: 0,
        socialFreqCode: 0,
        cognitiveStimFreqCode: 0,
        systolicBp: 160,
        hasDiabetes: true,
        hearingDifficulty: 3,
        alcoholFreq: 3,
        isSmoker: true,
      );
      final scores = computeSubScores(input);
      expect(scores.length, equals(8));
      scores.forEach((_, v) => expect(v, lessThanOrEqualTo(3.0)));
    });
  });
}
