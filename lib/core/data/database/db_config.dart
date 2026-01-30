import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class LocalDatabaseConfig {
  static final LocalDatabaseConfig _instance = LocalDatabaseConfig._internal();
  static Database? _database;

  factory LocalDatabaseConfig() {
    return _instance;
  }

  LocalDatabaseConfig._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "local_database.db");

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE user (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        email TEXT,
        password TEXT,
        phone TEXT,
        profileImage TEXT,
        status TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < newVersion) {
      // Handle database migration logic if needed
    }
  }

  Future<int> insertUser(Map<String, dynamic> userData) async {
    final db = await database;
    try {
      return await db.insert('user', userData);
    } catch (e) {
      print('Error inserting user: $e');
      return 0;
    }
  }
}
