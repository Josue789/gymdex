import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('gym.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE ejercicios(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nombre TEXT,
      grupo TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE rutinas(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nombre TEXT,
      dia TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE rutinas_ejercicios(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      rutina_id INTEGER,
      ejercicio_id INTEGER,
      series INTEGER,
      repeticiones INTEGER
    )
    ''');

    await db.execute('''
    CREATE TABLE entrenamientos(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      fecha TEXT,
      rutinaId INTEGER
    )
    ''');

    await db.execute('''
    CREATE TABLE registro_series(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      entrenamientoId INTEGER,
      ejercicioId INTEGER,
      serie INTEGER,
      repeticiones INTEGER,
      peso REAL
    )
    ''');

    await db.execute('''
    CREATE TABLE record_personal(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      ejercicioId INTEGER,
      pesoMaximo REAL,
      repeticiones INTEGER,
      fecha TEXT
    )
    ''');
  }
}
