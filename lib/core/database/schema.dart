/// SQLite 스키마 정의 (sqflite 사용)
///
/// 모든 데이터는 기기 내 SQLite에만 저장 (로컬 우선 원칙).
library schema;

const int kDbVersion = 1;
const String kDbName = 'dementia_prevention.db';

// ---------------------------------------------------------------------------
// CREATE TABLE 문
// ---------------------------------------------------------------------------

/// 사용자 프로파일 (온보딩 시 1회, 이후 수정 가능)
const String sqlCreateUserProfile = '''
CREATE TABLE IF NOT EXISTS user_profile (
  id INTEGER PRIMARY KEY DEFAULT 1,
  birth_year INTEGER NOT NULL,
  education_years INTEGER,
  family_history INTEGER NOT NULL DEFAULT 0,
  has_diabetes INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''';

/// 인지 테스트 세션
const String sqlCreateCognitiveSessions = '''
CREATE TABLE IF NOT EXISTS cognitive_sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  tested_at TEXT NOT NULL,
  t1_immediate INTEGER,
  t1_delayed INTEGER,
  t1_score REAL,
  t2_word_count INTEGER,
  t2_score REAL,
  t3_forward_span INTEGER,
  t3_backward_span INTEGER,
  t3_score REAL,
  t4_time_a REAL,
  t4_time_b REAL,
  t4_score REAL,
  composite_score REAL,
  word_set TEXT NOT NULL DEFAULT 'A'
)
''';

/// 라이프스타일 체크인
const String sqlCreateLifestyleCheckins = '''
CREATE TABLE IF NOT EXISTS lifestyle_checkins (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  checked_at TEXT NOT NULL,
  sleep_hours REAL,
  sleep_quality INTEGER,
  exercise_days INTEGER,
  exercise_minutes INTEGER,
  diet_score INTEGER,
  social_freq INTEGER,
  cognitive_stim_freq INTEGER,
  systolic_bp INTEGER,
  hearing_difficulty INTEGER,
  alcohol_freq INTEGER,
  is_smoker INTEGER NOT NULL DEFAULT 0,
  sub_scores TEXT,
  lifestyle_score REAL,
  baseline_modifier REAL
)
''';

/// 인지 점수 기준선 (자동 계산, 단일 행)
const String sqlCreateCognitiveBaseline = '''
CREATE TABLE IF NOT EXISTS cognitive_baseline (
  id INTEGER PRIMARY KEY DEFAULT 1,
  baseline_composite REAL,
  baseline_calculated_at TEXT,
  session_count_used INTEGER
)
''';

/// 전체 테이블 생성 순서 (외래 키 의존성 없음).
const List<String> allCreateStatements = [
  sqlCreateUserProfile,
  sqlCreateCognitiveSessions,
  sqlCreateLifestyleCheckins,
  sqlCreateCognitiveBaseline,
];

// ---------------------------------------------------------------------------
// DROP TABLE 문 (테스트·초기화용)
// ---------------------------------------------------------------------------

const String sqlDropUserProfile = 'DROP TABLE IF EXISTS user_profile';
const String sqlDropCognitiveSessions =
    'DROP TABLE IF EXISTS cognitive_sessions';
const String sqlDropLifestyleCheckins =
    'DROP TABLE IF EXISTS lifestyle_checkins';
const String sqlDropCognitiveBaseline =
    'DROP TABLE IF EXISTS cognitive_baseline';

const List<String> allDropStatements = [
  sqlDropUserProfile,
  sqlDropCognitiveSessions,
  sqlDropLifestyleCheckins,
  sqlDropCognitiveBaseline,
];
