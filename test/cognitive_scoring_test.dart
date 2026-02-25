import 'package:test/test.dart';
import 'package:prj_dim/core/algorithms/cognitive_scoring.dart';

void main() {
  // =========================================================================
  // T1. 기억력 (Word Recall)
  // =========================================================================
  group('T1 scoreT1', () {
    test('최대 점수: 5개 모두 회상', () {
      expect(scoreT1(correctDelayed: 5), equals(100.0));
    });

    test('최소 점수: 0개 회상', () {
      expect(scoreT1(correctDelayed: 0), equals(0.0));
    });

    test('중간 점수: 3개 회상 → 60점', () {
      expect(scoreT1(correctDelayed: 3), equals(60.0));
    });

    test('경계값: 1개 회상 → 20점', () {
      expect(scoreT1(correctDelayed: 1), equals(20.0));
    });

    test('경계값: 4개 회상 → 80점', () {
      expect(scoreT1(correctDelayed: 4), equals(80.0));
    });
  });

  // =========================================================================
  // T2. 언어 유창성 (Verbal Fluency)
  // =========================================================================
  group('fluencyAgeNorm', () {
    test('40대 → 18', () => expect(fluencyAgeNorm(45), equals(18)));
    test('50대 → 16', () => expect(fluencyAgeNorm(55), equals(16)));
    test('60대 → 14', () => expect(fluencyAgeNorm(65), equals(14)));
    test('70대 이상 → 12', () => expect(fluencyAgeNorm(75), equals(12)));
    test('경계: 49세 → 18 (40대)', () => expect(fluencyAgeNorm(49), equals(18)));
    test('경계: 50세 → 16 (50대)', () => expect(fluencyAgeNorm(50), equals(16)));
    test('경계: 70세 → 12 (70대+)', () => expect(fluencyAgeNorm(70), equals(12)));
  });

  group('T2 scoreT2', () {
    test('기준값 정확히 맞음 → 100점', () {
      expect(scoreT2(wordCount: 18, age: 45), equals(100.0));
    });

    test('기준값 초과 → 100 clamp', () {
      expect(scoreT2(wordCount: 25, age: 45), equals(100.0));
    });

    test('0개 → 0점', () {
      expect(scoreT2(wordCount: 0, age: 60), equals(0.0));
    });

    test('60대 기준값(14)의 절반(7) → 50점', () {
      expect(scoreT2(wordCount: 7, age: 60),
          closeTo(50.0, 0.01));
    });

    test('70대 기준(12): 12개 → 100점', () {
      expect(scoreT2(wordCount: 12, age: 72), equals(100.0));
    });
  });

  // =========================================================================
  // T3. 주의력 — 숫자 폭 (Digit Span)
  // =========================================================================
  group('T3 scoreT3', () {
    test('최대: forward=7, backward=6 → 130 → clamp 100', () {
      expect(scoreT3(forwardSpan: 7, backwardSpan: 6), equals(100.0));
    });

    test('최소: forward=0, backward=0 → 0', () {
      expect(scoreT3(forwardSpan: 0, backwardSpan: 0), equals(0.0));
    });

    test('전형적: forward=5, backward=4 → 90 clamp 90', () {
      expect(scoreT3(forwardSpan: 5, backwardSpan: 4), equals(90.0));
    });

    test('forward=3, backward=2 → 50', () {
      expect(scoreT3(forwardSpan: 3, backwardSpan: 2), equals(50.0));
    });

    test('forward=4, backward=3 → 70', () {
      expect(scoreT3(forwardSpan: 4, backwardSpan: 3), equals(70.0));
    });
  });

  // =========================================================================
  // T4. 처리 속도 — Trail Making
  // =========================================================================
  group('T4 scoreT4', () {
    test('이상적: A=15초, B=30초 → 100', () {
      expect(scoreT4(timeA: 15, timeB: 30), closeTo(100.0, 0.01));
    });

    test('경계 A: A=55초 → scoreA=0', () {
      // scoreA=0, scoreB=max(0, 100-(30-30)*1.5)=100 → 평균 50
      expect(scoreT4(timeA: 55, timeB: 30), closeTo(50.0, 0.01));
    });

    test('경계 B: B=97초 → scoreB=0', () {
      // scoreA=100 (A=15), scoreB=0 → 평균 50
      expect(scoreT4(timeA: 15, timeB: 97), closeTo(50.0, 0.01));
    });

    test('A=15초 초과: A=35초 → scoreA=50', () {
      // scoreA = 100 - (35-15)*2.5 = 100-50 = 50
      // scoreB = 100 (B=30)
      expect(scoreT4(timeA: 35, timeB: 30), closeTo(75.0, 0.01));
    });

    test('매우 느림: A=100초, B=200초 → 0 clamp', () {
      expect(scoreT4(timeA: 100, timeB: 200), equals(0.0));
    });

    test('B=30초 미만: B=20초 → scoreB=100 clamp', () {
      // scoreB = 100 - (20-30)*1.5 = 100 + 15 = 115 → clamp 100
      expect(scoreT4(timeA: 15, timeB: 20), closeTo(100.0, 0.01));
    });
  });

  // =========================================================================
  // 종합 인지 점수 (compositeScore)
  // =========================================================================
  group('compositeScore', () {
    test('모든 항목 100점 → 100점', () {
      expect(
        compositeScore(
            t1Score: 100, t2Score: 100, t3Score: 100, t4Score: 100),
        closeTo(100.0, 0.01),
      );
    });

    test('모든 항목 0점 → 0점', () {
      expect(
        compositeScore(t1Score: 0, t2Score: 0, t3Score: 0, t4Score: 0),
        closeTo(0.0, 0.01),
      );
    });

    test('가중치 검증: T1=100, 나머지 0 → 30점', () {
      expect(
        compositeScore(t1Score: 100, t2Score: 0, t3Score: 0, t4Score: 0),
        closeTo(30.0, 0.01),
      );
    });

    test('가중치 검증: T2=100, 나머지 0 → 20점', () {
      expect(
        compositeScore(t1Score: 0, t2Score: 100, t3Score: 0, t4Score: 0),
        closeTo(20.0, 0.01),
      );
    });

    test('결측 처리: T1, T2만 있을 때 가중치 재배분', () {
      // T1 0.30, T2 0.20 → totalWeight=0.50
      // T1=100 → weightedSum = 0.30*100 + 0.20*0 = 30
      // result = 30/0.50 = 60
      final score = compositeScore(t1Score: 100, t2Score: 0);
      expect(score, closeTo(60.0, 0.01));
    });

    test('결측 처리: 모든 항목 null → null 반환', () {
      expect(compositeScore(), isNull);
    });

    test('결측 처리: T4만 있을 때 → T4 점수 그대로', () {
      final score = compositeScore(t4Score: 80);
      expect(score, closeTo(80.0, 0.01));
    });
  });

  // =========================================================================
  // 단어 세트 관리
  // =========================================================================
  group('wordSetForSession', () {
    test('1회차 → Set A', () => expect(wordSetForSession(1), equals('A')));
    test('2회차 → Set B', () => expect(wordSetForSession(2), equals('B')));
    test('3회차 → Set A', () => expect(wordSetForSession(3), equals('A')));
    test('10회차 → Set B', () => expect(wordSetForSession(10), equals('B')));
  });

  group('getWordSet', () {
    test('A 세트 반환', () {
      expect(getWordSet('A'), equals(wordSetA));
    });

    test('B 세트 반환', () {
      expect(getWordSet('B'), equals(wordSetB));
    });

    test('알 수 없는 ID → A 기본값', () {
      expect(getWordSet('X'), equals(wordSetA));
    });
  });
}
