import '../core/database/profile_dao.dart';
import '../data/app_database.dart';

class ProfileService {
  static Future<UserProfile?> getProfile() async {
    final db = await AppDatabase.instance;
    return ProfileDao(db).get();
  }

  static Future<void> saveProfile(UserProfile profile) async {
    final db = await AppDatabase.instance;
    await ProfileDao(db).upsert(profile);
  }
}
