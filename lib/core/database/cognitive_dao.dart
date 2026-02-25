/// 인지 테스트 세션 DAO
library cognitive_dao;

import 'package:sqflite/sqflite.dart';

/// 인지 테스트 세션 모델.
class CognitiveSession {
  final int? id;
  final DateTime testedAt;
  final int? t1Immediate;
  final int? t1Delayed;
  final double? t1Score;
  final int? t2WordCount;
  final double? t2Score;
  final int? t3ForwardSpan;
  final int? t3BackwardSpan;
  final double? t3Score;
  final double? t4TimeA;
  final double? t4TimeB;
  final double? t4Score;
  final double? compositeScore;
  final String wordSet;

  const CognitiveSession({
    this.id,
    required this.testedAt,
    this.t1Immediate,
    this.t1Delayed,
    this.t1Score,
    this.t2WordCount,
    this.t2Score,
    this.t3ForwardSpan,
    this.t3BackwardSpan,
    this.t3Score,
    this.t4TimeA,
    this.t4TimeB,
    this.t4Score,
    this.compositeScore,
    this.wordSet = 'A',
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'tested_at': testedAt.toIso8601String(),
        't1_immediate': t1Immediate,
        't1_delayed': t1Delayed,
        't1_score': t1Score,
        't2_word_count': t2WordCount,
        't2_score': t2Score,
        't3_forward_span': t3ForwardSpan,
        't3_backward_span': t3BackwardSpan,
        't3_score': t3Score,
        't4_time_a': t4TimeA,
        't4_time_b': t4TimeB,
        't4_score': t4Score,
        'composite_score': compositeScore,
        'word_set': wordSet,
      };

  factory CognitiveSession.fromMap(Map<String, dynamic> map) =>
      CognitiveSession(
        id: map['id'] as int?,
        testedAt: DateTime.parse(map['tested_at'] as String),
        t1Immediate: map['t1_immediate'] as int?,
        t1Delayed: map['t1_delayed'] as int?,
        t1Score: map['t1_score'] as double?,
        t2WordCount: map['t2_word_count'] as int?,
        t2Score: map['t2_score'] as double?,
        t3ForwardSpan: map['t3_forward_span'] as int?,
        t3BackwardSpan: map['t3_backward_span'] as int?,
        t3Score: map['t3_score'] as double?,
        t4TimeA: map['t4_time_a'] as double?,
        t4TimeB: map['t4_time_b'] as double?,
        t4Score: map['t4_score'] as double?,
        compositeScore: map['composite_score'] as double?,
        wordSet: map['word_set'] as String? ?? 'A',
      );
}

/// 인지 기준선 모델.
class CognitiveBaseline {
  final double? baselineComposite;
  final DateTime? calculatedAt;
  final int? sessionCountUsed;

  const CognitiveBaseline({
    this.baselineComposite,
    this.calculatedAt,
    this.sessionCountUsed,
  });

  Map<String, dynamic> toMap() => {
        'id': 1,
        'baseline_composite': baselineComposite,
        'baseline_calculated_at': calculatedAt?.toIso8601String(),
        'session_count_used': sessionCountUsed,
      };

  factory CognitiveBaseline.fromMap(Map<String, dynamic> map) =>
      CognitiveBaseline(
        baselineComposite: map['baseline_composite'] as double?,
        calculatedAt: map['baseline_calculated_at'] != null
            ? DateTime.parse(map['baseline_calculated_at'] as String)
            : null,
        sessionCountUsed: map['session_count_used'] as int?,
      );
}

/// 인지 테스트 세션 데이터 접근 객체.
class CognitiveDao {
  final Database db;

  const CognitiveDao(this.db);

  // ---- 세션 CRUD ----

  /// 새 테스트 세션 삽입.
  Future<int> insertSession(CognitiveSession session) async {
    return db.insert('cognitive_sessions', session.toMap());
  }

  /// 전체 세션 조회 (시간순 오름차순).
  Future<List<CognitiveSession>> getAllSessions() async {
    final rows =
        await db.query('cognitive_sessions', orderBy: 'tested_at ASC');
    return rows.map(CognitiveSession.fromMap).toList();
  }

  /// 최근 N개 세션 조회 (최신순).
  Future<List<CognitiveSession>> getRecentSessions(int n) async {
    final rows = await db.query(
      'cognitive_sessions',
      orderBy: 'tested_at DESC',
      limit: n,
    );
    // 시간순 오름차순으로 반환
    return rows.reversed.map(CognitiveSession.fromMap).toList();
  }

  /// 가장 최근 세션 1개 조회.
  Future<CognitiveSession?> getLatestSession() async {
    final sessions = await getRecentSessions(1);
    return sessions.isNotEmpty ? sessions.first : null;
  }

  /// 세션 총 개수 조회.
  Future<int> sessionCount() async {
    final result =
        await db.rawQuery('SELECT COUNT(*) as cnt FROM cognitive_sessions');
    return result.first['cnt'] as int;
  }

  // ---- Baseline CRUD ----

  /// baseline 저장 또는 갱신 (id=1 고정 행).
  Future<void> upsertBaseline(CognitiveBaseline baseline) async {
    await db.insert(
      'cognitive_baseline',
      baseline.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 저장된 baseline 조회. 없으면 null 반환.
  Future<CognitiveBaseline?> getBaseline() async {
    final rows =
        await db.query('cognitive_baseline', where: 'id = 1');
    if (rows.isEmpty) return null;
    return CognitiveBaseline.fromMap(rows.first);
  }

  // ---- Composite score 시계열 ----

  /// composite_score 시계열 조회 (null 제외, 시간순).
  Future<List<double>> getCompositeScoreTimeSeries() async {
    final rows = await db.query(
      'cognitive_sessions',
      columns: ['composite_score'],
      where: 'composite_score IS NOT NULL',
      orderBy: 'tested_at ASC',
    );
    return rows
        .map((r) => r['composite_score'] as double)
        .toList();
  }
}
