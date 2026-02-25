/// 사용자 프로파일 DAO
library profile_dao;

import 'package:sembast/sembast.dart';

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
  static final _store = intMapStoreFactory.store('user_profile');
  static const _key = 1;

  final Database db;

  const ProfileDao(this.db);

  /// 프로파일 저장 또는 갱신.
  Future<void> upsert(UserProfile profile) async {
    await _store.record(_key).put(db, profile.toMap().cast<String, Object?>());
  }

  /// 저장된 프로파일 조회. 없으면 null 반환.
  Future<UserProfile?> get() async {
    final record = await _store.record(_key).get(db);
    if (record == null) return null;
    return UserProfile.fromMap(Map<String, dynamic>.from(record));
  }

  /// 프로파일 삭제 (재온보딩용).
  Future<void> delete() async {
    await _store.record(_key).delete(db);
  }
}
