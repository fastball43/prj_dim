/// 라이프스타일 체크인 DAO
library lifestyle_dao;

import 'dart:convert';

import 'package:sqflite/sqflite.dart';

/// 라이프스타일 체크인 모델.
class LifestyleCheckin {
  final int? id;
  final DateTime checkedAt;
  final double? sleepHours;
  final int? sleepQuality;         // 1-5
  final int? exerciseDays;
  final int? exerciseMinutes;
  final int? dietScore;            // 0-10
  final int? socialFreq;           // 0-4
  final int? cognitiveStimFreq;    // 0-4
  final int? systolicBp;           // nullable
  final int? hearingDifficulty;    // 0-3
  final int? alcoholFreq;          // 0-3
  final bool isSmoker;
  final Map<String, double>? subScores; // JSON 저장
  final double? lifestyleScore;
  final double? baselineModifier;

  const LifestyleCheckin({
    this.id,
    required this.checkedAt,
    this.sleepHours,
    this.sleepQuality,
    this.exerciseDays,
    this.exerciseMinutes,
    this.dietScore,
    this.socialFreq,
    this.cognitiveStimFreq,
    this.systolicBp,
    this.hearingDifficulty,
    this.alcoholFreq,
    this.isSmoker = false,
    this.subScores,
    this.lifestyleScore,
    this.baselineModifier,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'checked_at': checkedAt.toIso8601String(),
        'sleep_hours': sleepHours,
        'sleep_quality': sleepQuality,
        'exercise_days': exerciseDays,
        'exercise_minutes': exerciseMinutes,
        'diet_score': dietScore,
        'social_freq': socialFreq,
        'cognitive_stim_freq': cognitiveStimFreq,
        'systolic_bp': systolicBp,
        'hearing_difficulty': hearingDifficulty,
        'alcohol_freq': alcoholFreq,
        'is_smoker': isSmoker ? 1 : 0,
        'sub_scores':
            subScores != null ? jsonEncode(subScores) : null,
        'lifestyle_score': lifestyleScore,
        'baseline_modifier': baselineModifier,
      };

  factory LifestyleCheckin.fromMap(Map<String, dynamic> map) {
    Map<String, double>? subScores;
    final rawSubScores = map['sub_scores'] as String?;
    if (rawSubScores != null) {
      final decoded = jsonDecode(rawSubScores) as Map<String, dynamic>;
      subScores = decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
    }

    return LifestyleCheckin(
      id: map['id'] as int?,
      checkedAt: DateTime.parse(map['checked_at'] as String),
      sleepHours: map['sleep_hours'] as double?,
      sleepQuality: map['sleep_quality'] as int?,
      exerciseDays: map['exercise_days'] as int?,
      exerciseMinutes: map['exercise_minutes'] as int?,
      dietScore: map['diet_score'] as int?,
      socialFreq: map['social_freq'] as int?,
      cognitiveStimFreq: map['cognitive_stim_freq'] as int?,
      systolicBp: map['systolic_bp'] as int?,
      hearingDifficulty: map['hearing_difficulty'] as int?,
      alcoholFreq: map['alcohol_freq'] as int?,
      isSmoker: (map['is_smoker'] as int? ?? 0) == 1,
      subScores: subScores,
      lifestyleScore: map['lifestyle_score'] as double?,
      baselineModifier: map['baseline_modifier'] as double?,
    );
  }
}

/// 라이프스타일 체크인 데이터 접근 객체.
class LifestyleDao {
  final Database db;

  const LifestyleDao(this.db);

  /// 새 체크인 삽입.
  Future<int> insertCheckin(LifestyleCheckin checkin) async {
    return db.insert('lifestyle_checkins', checkin.toMap());
  }

  /// 전체 체크인 조회 (시간순 오름차순).
  Future<List<LifestyleCheckin>> getAllCheckins() async {
    final rows =
        await db.query('lifestyle_checkins', orderBy: 'checked_at ASC');
    return rows.map(LifestyleCheckin.fromMap).toList();
  }

  /// 최근 N개 체크인 조회 (최신순 → 오름차순 반환).
  Future<List<LifestyleCheckin>> getRecentCheckins(int n) async {
    final rows = await db.query(
      'lifestyle_checkins',
      orderBy: 'checked_at DESC',
      limit: n,
    );
    return rows.reversed.map(LifestyleCheckin.fromMap).toList();
  }

  /// 가장 최근 체크인 1개 조회.
  Future<LifestyleCheckin?> getLatestCheckin() async {
    final checkins = await getRecentCheckins(1);
    return checkins.isNotEmpty ? checkins.first : null;
  }

  /// lifestyle_score 시계열 조회 (null 제외, 시간순).
  Future<List<double>> getLifestyleScoreTimeSeries() async {
    final rows = await db.query(
      'lifestyle_checkins',
      columns: ['lifestyle_score'],
      where: 'lifestyle_score IS NOT NULL',
      orderBy: 'checked_at ASC',
    );
    return rows.map((r) => r['lifestyle_score'] as double).toList();
  }
}
