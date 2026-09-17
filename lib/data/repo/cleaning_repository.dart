import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../models/cleaning_schedule.dart';
import '../models/cleaning_session.dart';
import '../models/custom_routine.dart';

/// Semua akses data Cleanly melewati kelas ini sehingga UI tidak pernah
/// menyentuh SQLite secara langsung.
class CleaningRepository {
  CleaningRepository(this._database);

  final AppDatabase _database;

  Future<Database> get _db => _database.database;

  // ── Sesi ───────────────────────────────────────────────────────────────

  /// Menyimpan sesi beserta daftar langkahnya dalam satu transaksi supaya
  /// riwayat tidak pernah setengah tertulis.
  Future<void> saveSession(CleaningSession session) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.insert(
        'cleaning_sessions',
        session.toRow(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.delete(
        'session_tasks',
        where: 'session_id = ?',
        whereArgs: [session.id],
      );
      for (var position = 0; position < session.tasks.length; position++) {
        await txn.insert('session_tasks', {
          ...session.tasks[position].toRow(session.id),
          'position': position,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<CleaningSession>> recentSessions({int limit = 40}) async {
    final db = await _db;
    final rows = await db.query(
      'cleaning_sessions',
      orderBy: 'started_at DESC',
      limit: limit,
    );
    return [for (final row in rows) CleaningSession.fromRow(row)];
  }

  Future<CleaningSession?> sessionWithTasks(String id) async {
    final db = await _db;
    final rows = await db.query(
      'cleaning_sessions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final taskRows = await db.query(
      'session_tasks',
      where: 'session_id = ?',
      whereArgs: [id],
      orderBy: 'position ASC',
    );
    return CleaningSession.fromRow(
      rows.first,
      tasks: [for (final row in taskRows) SessionTask.fromRow(row)],
    );
  }

  Future<void> deleteSession(String id) async {
    final db = await _db;
    await db.delete('cleaning_sessions', where: 'id = ?', whereArgs: [id]);
  }

  /// Menghapus seluruh riwayat. Rutinitas dan jadwal tetap dipertahankan.
  Future<void> clearHistory() async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('session_tasks');
      await txn.delete('cleaning_sessions');
    });
  }

  /// Ringkasan Home dan History. Dihitung di Dart agar aturan streak bisa
  /// diuji langsung tanpa database.
  Future<CleaningStats> stats({DateTime? now}) async {
    final db = await _db;
    final rows = await db.query('cleaning_sessions');
    return buildStats(
      [for (final row in rows) CleaningSession.fromRow(row)],
      now: now ?? DateTime.now(),
    );
  }

  // ── Rutinitas kustom ──────────────────────────────────────────────────

  Future<List<CustomRoutine>> listRoutines() async {
    final db = await _db;
    final rows = await db.query('custom_routines', orderBy: 'created_at DESC');
    return [for (final row in rows) CustomRoutine.fromRow(row)];
  }

  Future<void> saveRoutine(CustomRoutine routine) async {
    final db = await _db;
    await db.insert(
      'custom_routines',
      routine.toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteRoutine(String id) async {
    final db = await _db;
    await db.delete('custom_routines', where: 'id = ?', whereArgs: [id]);
  }

  /// Hanya satu rutinitas yang boleh menjadi aksi cepat di Home.
  Future<void> setHomeRoutine(String? id) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.update('custom_routines', {'is_at_home': 0});
      if (id != null) {
        await txn.update(
          'custom_routines',
          {'is_at_home': 1},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    });
  }

  // ── Jadwal ────────────────────────────────────────────────────────────

  Future<List<CleaningSchedule>> listSchedules() async {
    final db = await _db;
    final rows = await db.query(
      'cleaning_schedules',
      orderBy: 'hour ASC, minute ASC',
    );
    return [for (final row in rows) CleaningSchedule.fromRow(row)];
  }

  Future<void> saveSchedule(CleaningSchedule schedule) async {
    final db = await _db;
    await db.insert(
      'cleaning_schedules',
      schedule.toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteSchedule(String id) async {
    final db = await _db;
    await db.delete('cleaning_schedules', where: 'id = ?', whereArgs: [id]);
  }
}
