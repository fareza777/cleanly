import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Penyimpanan lokal Cleanly. Seluruh fitur bekerja tanpa internet, sehingga
/// SQLite di perangkat adalah satu-satunya sumber data.
class AppDatabase {
  AppDatabase({this.path, this.factory});

  static final AppDatabase instance = AppDatabase();

  final String? path;
  final DatabaseFactory? factory;
  Future<Database>? _opening;

  static const schemaVersion = 1;

  Future<Database> get database => _opening ??= _open();

  Future<Database> _open() async {
    try {
      final selectedFactory = factory ?? databaseFactory;
      final selectedPath =
          path ??
          p.join(await selectedFactory.getDatabasesPath(), 'cleanly.db');
      return await selectedFactory.openDatabase(
        selectedPath,
        options: OpenDatabaseOptions(
          version: schemaVersion,
          onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    } catch (_) {
      // Biarkan percobaan berikutnya membuka ulang dari nol, bukan menyimpan
      // kegagalan selamanya.
      _opening = null;
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cleaning_sessions (
        id TEXT PRIMARY KEY,
        room TEXT NOT NULL,
        minutes INTEGER NOT NULL,
        started_at INTEGER NOT NULL,
        ended_at INTEGER NOT NULL,
        completed_tasks INTEGER NOT NULL DEFAULT 0,
        total_tasks INTEGER NOT NULL DEFAULT 0,
        spent_seconds INTEGER NOT NULL DEFAULT 0,
        routine_id TEXT,
        routine_name TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_sessions_started ON cleaning_sessions (started_at DESC)',
    );

    await db.execute('''
      CREATE TABLE session_tasks (
        session_id TEXT NOT NULL,
        task_id TEXT NOT NULL,
        title TEXT NOT NULL,
        room TEXT NOT NULL,
        seconds INTEGER NOT NULL DEFAULT 0,
        done INTEGER NOT NULL DEFAULT 0,
        position INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (session_id, task_id, position),
        FOREIGN KEY (session_id) REFERENCES cleaning_sessions (id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE custom_routines (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        room TEXT NOT NULL,
        minutes INTEGER NOT NULL DEFAULT 10,
        task_ids TEXT NOT NULL DEFAULT '',
        is_at_home INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE cleaning_schedules (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        room TEXT NOT NULL,
        minutes INTEGER NOT NULL DEFAULT 10,
        cadence TEXT NOT NULL DEFAULT 'daily',
        weekday INTEGER NOT NULL DEFAULT 1,
        hour INTEGER NOT NULL DEFAULT 9,
        minute INTEGER NOT NULL DEFAULT 0,
        routine_id TEXT,
        enabled INTEGER NOT NULL DEFAULT 1
      )
    ''');
  }

  /// Langkah migrasi antar versi skema.
  ///
  /// Tanpa ini, menaikkan [schemaVersion] di rilis berikutnya akan membuat
  /// sqflite melempar galat saat pengguna membuka aplikasi yang sudah punya
  /// basis data lama — jadi kerangkanya sudah disiapkan sejak versi 1.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Versi 1 adalah skema pertama; belum ada langkah yang perlu dijalankan.
    // Migrasi berikutnya ditulis di sini, satu blok per versi.
  }

  Future<void> close() async {
    final opening = _opening;
    _opening = null;
    if (opening != null) await (await opening).close();
  }
}
