/// 사용자 프로파일 DAO
library profile_dao;

import 'package:sqflite/sqflite.dart';

/// 사용자 프로파일 모델.
class UserProfile {
  final int birthYear;
  final int? educationYears;
  final bool familyHistory;
  final bool hasDiabetes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.birthYear,
    this.educationYears,
    required this.familyHistory,
    required this.hasDiabetes,
    required this.createdAt,
    required this.updatedAt,
  });

  int get age => DateTime.now().year - birthYear;

  Map<String, dynamic> toMap() => {
        'id': 1,
        'birth_year': birthYear,
        'education_years': educationYears,
        'family_history': familyHistory ? 1 : 0,
        'has_diabetes': hasDiabetes ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        birthYear: map['birth_year'] as int,
        educationYears: map['education_years'] as int?,
        familyHistory: (map['family_history'] as int) == 1,
        hasDiabetes: (map['has_diabetes'] as int) == 1,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );
}

/// 사용자 프로파일 데이터 접근 객체.
class ProfileDao {
  final Database db;

  const ProfileDao(this.db);

  /// 프로파일 저장 또는 갱신 (id=1 고정 행).
  Future<void> upsert(UserProfile profile) async {
    await db.insert(
      'user_profile',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 저장된 프로파일 조회. 없으면 null 반환.
  Future<UserProfile?> get() async {
    final rows = await db.query('user_profile', where: 'id = 1');
    if (rows.isEmpty) return null;
    return UserProfile.fromMap(rows.first);
  }

  /// 프로파일 삭제 (재온보딩용).
  Future<void> delete() async {
    await db.delete('user_profile', where: 'id = 1');
  }
}
