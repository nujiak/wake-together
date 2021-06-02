import 'package:flutter/cupertino.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'models/alarm.dart';

class DatabaseProvider {

  /// SQLite table name for local alarms.
  static const String LOCAL_ALARMS_TABLE = "local_alarms";

  /// Private constructor to prevent initialisation outside of class.
  DatabaseProvider._();

  /// Singleton instance of this DatabaseProvider.
  static final DatabaseProvider _instance = DatabaseProvider._();

  factory DatabaseProvider() => _instance;

  /// Instance of Database.
  static Database? _database;

  /// Singleton getter for _database.
  ///
  /// Initialises _database if it is called for the first time.
  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await initDatabase();
    return _database!;
  }

  /// Initialises the database for access.
  Future<Database> initDatabase() async {
    WidgetsFlutterBinding.ensureInitialized();

    return openDatabase(join(await getDatabasesPath(), 'alarms_database.db'),
        version: 1, onCreate: (db, version) {
      return db.execute(
          "CREATE TABLE $LOCAL_ALARMS_TABLE(id INTEGER PRIMARY KEY AUTOINCREMENT, description TEXT, hour INTEGER, minute INTEGER, days INTEGER, activated INTEGER)");
    });
  }

  /// Inserts an alarm into the database.
  ///
  /// If the alarm id is null, provides a new auto-incremented unique id
  /// for the alarm.
  Future<void> insertAlarm(Alarm alarm) async {
    Database db = await database;
    await db.insert(LOCAL_ALARMS_TABLE, alarm.toMap());
  }

  /// Fetches all alarms from the database.
  Future<List<Alarm>> getAlarms() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(LOCAL_ALARMS_TABLE);

    // Convert maps to alarms
    List<Alarm> alarms =
        List.generate(maps.length, (index) => Alarm.fromMap(maps[index]));

    // Sort alarms
    alarms.sort((Alarm a, Alarm b) => a.time.hour != b.time.hour
        ? a.time.hour - b.time.hour
        : a.time.minute - b.time.minute);

    // Return alarms
    return alarms;
  }

  /// Updates an existing alarm in the database.
  Future<void> updateAlarm(Alarm alarm) async {
    Database db = await database;
    await db.update(
      LOCAL_ALARMS_TABLE,
      alarm.toMap(),
      where: 'id = ?',
      whereArgs: [alarm.id],
    );
  }

  /// Deletes an alarm in the database through its id.
  Future<void> deleteAlarm(int id) async {
    Database db = await database;
    await db.delete(
      LOCAL_ALARMS_TABLE,
      where: "id = ?",
      whereArgs: [id],
    );
  }
}
