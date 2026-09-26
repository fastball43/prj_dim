import 'package:test/test.dart';
import 'package:prj_dim/core/algorithms/animal_lexicon.dart';

void main() {
  group('isAnimalName', () {
    test('기본 동물 이름 인정', () {
      for (final w in ['고양이', '강아지', '호랑이', '참새', '고등어', '나비', '개구리']) {
        expect(isAnimalName(w), isTrue, reason: w);
      }
    });

    test('한 글자 동물은 정확히 일치할 때 인정', () {
      for (final w in ['개', '소', '말', '곰', '닭']) {
        expect(isAnimalName(w), isTrue, reason: w);
      }
    });

    test('동물이 아닌 단어 거부', () {
      for (final w in ['사과', '자동차', '하늘', 'ㄱ', 'asdf', '책상', '']) {
        expect(isAnimalName(w), isFalse, reason: w);
      }
    });

    test('한 글자 동물로 끝나는 비동물 단어 거부 (무지개, 베개)', () {
      for (final w in ['무지개', '베개', '안개', '두부소']) {
        expect(isAnimalName(w), isFalse, reason: w);
      }
    });

    test('다른 뜻이 흔한 이름은 정확히 일치할 때만 인정 (드라마 ≠ 라마)', () {
      expect(isAnimalName('라마'), isTrue);
      expect(isAnimalName('드라마'), isFalse);
      expect(isAnimalName('당사자'), isFalse);
    });

    test('수식어가 붙은 동물 이름 인정', () {
      for (final w in ['검은고양이', '아기돼지', '바다거북']) {
        expect(isAnimalName(w), isTrue, reason: w);
      }
    });

    test('구두점·복수 접미사 처리', () {
      expect(isAnimalName('고양이!'), isTrue);
      expect(isAnimalName('토끼들'), isTrue);
    });
  });

  group('countValidAnimalNames', () {
    test('쉼표·공백·줄바꿈 구분 입력', () {
      expect(countValidAnimalNames('개, 고양이\n말 토끼'), equals(4));
    });

    test('중복 제외', () {
      expect(countValidAnimalNames('개, 개, 고양이, 고양이'), equals(2));
    });

    test('같은 동물의 수식어 변형은 1개로 셈', () {
      expect(countValidAnimalNames('고양이, 검은고양이, 아기고양이'), equals(1));
    });

    test('품종·종류가 다른 동물은 각각 셈', () {
      expect(countValidAnimalNames('개, 진돗개, 푸들'), equals(3));
    });

    test('비동물·무의미 입력 제외', () {
      expect(countValidAnimalNames('ㄱ ㄴ ㄷ 사과 자동차 무지개 고양이'), equals(1));
    });

    test('빈 입력 → 0', () {
      expect(countValidAnimalNames(''), equals(0));
      expect(countValidAnimalNames('  ,, \n '), equals(0));
    });
  });
}
