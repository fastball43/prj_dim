import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../core/database/schema.dart';

class AppDatabase {
  AppDatabase._();

  static Database? _db;

  static Future<Database> get instance async {
    _db ??= await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    final path = join(await getDatabasesPath(), kDbName);
    return openDatabase(
      path,
      version: kDbVersion,
      onCreate: (db, _) async {
        for (final sql in allCreateStatements) {
          await db.execute(sql);
        }
      },
    );
  }

  /// 테스트·초기화용 — 모든 테이블 삭제 후 재생성
  static Future<void> reset() async {
    final db = await instance;
    for (final sql in allDropStatements) {
      await db.execute(sql);
    }
    for (final sql in allCreateStatements) {
      await db.execute(sql);
    }
  }
}
