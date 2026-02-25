# prj_dim — 치매 예방 자가 관리 앱 알고리즘

인지 기능 테스트와 라이프스타일 위험도 점수 산출 알고리즘 구현체입니다.
Flutter/Dart + sqflite 기반이며, 모든 데이터는 기기 내 SQLite에만 저장됩니다.

---

## 프로젝트 구조

```
lib/
  core/
    algorithms/
      cognitive_scoring.dart   # T1~T4 점수 계산, 종합 인지 점수
      lifestyle_scoring.dart   # 8개 항목 점수 + 가중합 + 통합 점수
      change_detection.dart    # 기준선 계산, 변화 감지, 공백 탐지
    database/
      schema.dart              # SQLite CREATE TABLE 정의
      cognitive_dao.dart       # 인지 테스트 세션 DAO
      lifestyle_dao.dart       # 라이프스타일 체크인 DAO
      profile_dao.dart         # 사용자 프로파일 DAO
test/
  cognitive_scoring_test.dart
  lifestyle_scoring_test.dart
  change_detection_test.dart
```

---

## 테스트 실행

### 사전 요구사항

- [Dart SDK](https://dart.dev/get-dart) 3.0 이상

```bash
# macOS (Homebrew)
brew install dart-sdk
```

### 의존성 설치

```bash
dart pub get
```

### 전체 테스트 실행

```bash
dart test
```

### 파일별 실행

```bash
dart test test/cognitive_scoring_test.dart
dart test test/lifestyle_scoring_test.dart
dart test test/change_detection_test.dart
```

### 실행 결과 예시

```
142 tests passed in 0.1s
```

---

## 알고리즘 개요

### 인지 기능 테스트 (월 1회)

| 테스트 | 측정 영역 | 가중치 |
|--------|----------|--------|
| T1. 단어 회상 | 기억력 | 30% |
| T2. 동물 이름 유창성 | 언어 유창성 | 20% |
| T3. 숫자 폭 (Forward/Backward) | 주의력 | 25% |
| T4. 연결 잇기 (Trail Making 변형) | 처리 속도 | 25% |

- 기준선: 첫 2회 평균
- 경고 조건: 기준선 대비 -15점 이상 × 2회 연속 하락

### 라이프스타일 위험도 점수 (주 1~2회)

Lancet 2024 치매 위험 인자 기여도 기반 8개 항목:

| 항목 | 가중치 |
|------|--------|
| 신체 활동 | 18% |
| 수면 | 15% |
| 혈관 건강 | 15% |
| 사회 활동 | 13% |
| 정신 자극 | 13% |
| 식습관 (MIND diet) | 12% |
| 음주/흡연 | 8% |
| 청각 | 6% |

### 대시보드 통합 점수

```
통합 점수 = 인지 점수 × 0.40 + 라이프스타일 점수 × 0.60
```

> ⚠️ 이 앱의 점수는 의학적 진단이 아닙니다.
