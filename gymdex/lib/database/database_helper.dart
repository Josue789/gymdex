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

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Agregar nuevas columnas a la tabla de ejercicios
      await db.execute('ALTER TABLE ejercicios ADD COLUMN gifUrl TEXT;');
      await db.execute('ALTER TABLE ejercicios ADD COLUMN target TEXT;');
      await db.execute('ALTER TABLE ejercicios ADD COLUMN equipment TEXT;');
      await db.execute('ALTER TABLE ejercicios ADD COLUMN instructions TEXT;');
      await db.execute(
        'ALTER TABLE ejercicios ADD COLUMN isTranslated INTEGER DEFAULT 0;',
      );
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE ejercicios(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nombre TEXT,
      grupo TEXT,
      gifUrl TEXT,
      target TEXT,
      equipment TEXT,
      instructions TEXT,
      isTranslated INTEGER DEFAULT 0
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
