# prj_dim — 치매 예방 자가 관리 앱

인지 기능 테스트와 라이프스타일 위험도 점수를 측정하는 치매 예방 자가 관리 앱입니다.
Flutter/Dart + sqflite 기반이며, 모든 데이터는 기기 내 SQLite에만 저장됩니다.

---

## 앱 실행

### 사전 요구사항

- [Flutter SDK](https://flutter.dev/docs/get-started/install) 3.10 이상

### Flutter 프로젝트 초기화 (최초 1회)

```bash
# 플랫폼별 네이티브 파일 생성 (기존 Dart 파일은 유지됨)
flutter create --project-name prj_dim .
flutter pub get
```

### 앱 실행

```bash
flutter run
```

---

## 화면 구성

| 화면 | 설명 |
|------|------|
| 온보딩 | 출생연도·학력·가족력·당뇨 4단계 입력 |
| 대시보드 | 통합 점수, 인지/라이프스타일 점수, 경고 배너 |
| 인지 기능 테스트 | T1→T2→T3→T4→T1 지연 회상 순서로 진행 (~5분) |
| 라이프스타일 체크인 | 8개 항목 입력 후 즉시 점수 산출 |

---

## 프로젝트 구조

```
lib/
  main.dart
  app.dart
  data/
    app_database.dart          # SQLite 싱글턴 초기화
  services/
    profile_service.dart       # 사용자 프로파일 저장/조회
    cognitive_service.dart     # 인지 테스트 저장 + 변화 감지
    lifestyle_service.dart     # 라이프스타일 저장 + 점수 계산
  models/
    dashboard_state.dart       # 대시보드 뷰 모델
  ui/
    theme/
      app_theme.dart           # Material 3 테마
    screens/
      onboarding_screen.dart   # 4단계 온보딩
      dashboard_screen.dart    # 메인 대시보드
      cognitive_test_screen.dart  # 인지 테스트 전체 플로우
      lifestyle_checkin_screen.dart  # 라이프스타일 체크인 폼
    widgets/
      score_ring.dart          # 원형 점수 위젯
      alert_banner.dart        # 변화 감지 경고 배너
      t4_trail_canvas.dart     # Trail Making 캔버스
  core/
    algorithms/
      cognitive_scoring.dart   # T1~T4 점수 계산, 종합 인지 점수
      animal_lexicon.dart      # T2 동물 이름 사전·입력 검증
      lifestyle_scoring.dart   # 8개 항목 점수 + 가중합 + 통합 점수
      change_detection.dart    # 기준선 계산, 변화 감지, 공백 탐지
    database/
      schema.dart              # SQLite CREATE TABLE 정의
      cognitive_dao.dart       # 인지 테스트 세션 DAO
      lifestyle_dao.dart       # 라이프스타일 체크인 DAO
      profile_dao.dart         # 사용자 프로파일 DAO
test/
  cognitive_scoring_test.dart
  animal_lexicon_test.dart
  lifestyle_scoring_test.dart
  change_detection_test.dart
```

---

## 알고리즘 단위 테스트

알고리즘 파일(`core/algorithms/`)은 Flutter 없이 순수 Dart로 테스트 가능합니다.

### 사전 요구사항

- [Dart SDK](https://dart.dev/get-dart) 3.0 이상 (Flutter에 포함됨)

```bash
# macOS (Homebrew, Flutter 미설치 시)
brew install dart-sdk
```

### 의존성 설치 (알고리즘 테스트 전용)

> pubspec.yaml을 Flutter 의존성 없이 실행하려면 아래와 같이 임시 변경 후 테스트

```bash
dart pub get
dart test test/cognitive_scoring_test.dart test/animal_lexicon_test.dart test/lifestyle_scoring_test.dart test/change_detection_test.dart
```

또는 Flutter 설치 후:

```bash
flutter test
```

### 실행 결과

```
166 tests passed in 0.1s
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
- T1 회상: 보기 중 선택 방식이므로 오답 선택 1개당 1점 감점 (정답 수 − 오답 수)
- T2 유창성: 동물 이름 사전으로 검증, 같은 동물은 한 번만 인정
- 경고 조건: 기준선 이후 최근 2회 세션이 모두 기준선 대비 15점 이상 낮을 때

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
