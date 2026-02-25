import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast_web/sembast_web.dart';

class AppDatabase {
  AppDatabase._();

  static Database? _db;

  static Future<Database> get instance async {
    _db ??= await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    if (kIsWeb) {
      return databaseFactoryWeb.openDatabase('prj_dim.db');
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final path = join(dir.path, 'prj_dim.db');
      return databaseFactoryIo.openDatabase(path);
    }
  }
}
