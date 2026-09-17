import 'package:cleanly/data/db/app_database.dart';
import 'package:cleanly/data/models/cleaning_schedule.dart';
import 'package:cleanly/data/models/cleaning_session.dart';
import 'package:cleanly/data/models/custom_routine.dart';
import 'package:cleanly/data/repo/cleaning_repository.dart';
import 'package:cleanly/domain/catalog/cleaning_catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  late AppDatabase database;
  late CleaningRepository repository;

  setUp(() {
    database = AppDatabase(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    repository = CleaningRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  CleaningSession sessionFixture({
    String id = 'session-1',
    CleaningRoom room = CleaningRoom.kitchen,
    DateTime? startedAt,
    int spentSeconds = 300,
  }) {
    final start = startedAt ?? DateTime(2026, 9, 16, 18);
    return CleaningSession(
      id: id,
      room: room,
      minutes: 10,
      startedAt: start,
      endedAt: start.add(Duration(seconds: spentSeconds)),
      completedTasks: 2,
      totalTasks: 3,
      spentSeconds: spentSeconds,
      tasks: const [
        SessionTask(
          taskId: 'kitchen.counters',
          title: 'Clear and wipe the counters',
          room: CleaningRoom.kitchen,
          seconds: 120,
          done: true,
        ),
        SessionTask(
          taskId: 'kitchen.dishes',
          title: 'Wash the dishes',
          room: CleaningRoom.kitchen,
          seconds: 120,
          done: true,
        ),
        SessionTask(
          taskId: 'kitchen.sink',
          title: 'Wipe the sink and faucet',
          room: CleaningRoom.kitchen,
          seconds: 60,
          done: false,
        ),
      ],
    );
  }

  group('sessions', () {
    test('saves a session with its steps and reads them back', () async {
      await repository.saveSession(sessionFixture());

      final loaded = await repository.sessionWithTasks('session-1');
      expect(loaded, isNotNull);
      expect(loaded!.room, CleaningRoom.kitchen);
      expect(loaded.completedTasks, 2);
      expect(loaded.tasks, hasLength(3));
      expect(loaded.tasks.first.title, 'Clear and wipe the counters');
      expect(loaded.tasks.last.done, isFalse);
    });

    test('lists the newest session first', () async {
      await repository.saveSession(
        sessionFixture(id: 'older', startedAt: DateTime(2026, 9, 10, 9)),
      );
      await repository.saveSession(
        sessionFixture(id: 'newer', startedAt: DateTime(2026, 9, 16, 9)),
      );

      final sessions = await repository.recentSessions();
      expect(sessions.map((session) => session.id), ['newer', 'older']);
    });

    test('re-saving a session replaces its step rows', () async {
      await repository.saveSession(sessionFixture());
      await repository.saveSession(
        CleaningSession(
          id: 'session-1',
          room: CleaningRoom.bathroom,
          minutes: 5,
          startedAt: DateTime(2026, 9, 16, 18),
          endedAt: DateTime(2026, 9, 16, 18, 5),
          completedTasks: 1,
          totalTasks: 1,
          spentSeconds: 300,
          tasks: const [
            SessionTask(
              taskId: 'bathroom.mirror',
              title: 'Squeegee the mirror',
              room: CleaningRoom.bathroom,
              seconds: 60,
              done: true,
            ),
          ],
        ),
      );

      final loaded = await repository.sessionWithTasks('session-1');
      expect(loaded!.room, CleaningRoom.bathroom);
      expect(loaded.tasks, hasLength(1));
    });

    test('deleting a session also removes its steps', () async {
      await repository.saveSession(sessionFixture());
      await repository.deleteSession('session-1');

      expect(await repository.sessionWithTasks('session-1'), isNull);
      final orphans = await (await database.database).query('session_tasks');
      expect(orphans, isEmpty);
    });

    test('stats reflect saved sessions', () async {
      await repository.saveSession(
        sessionFixture(id: 'a', spentSeconds: 300),
      );
      await repository.saveSession(
        sessionFixture(
          id: 'b',
          startedAt: DateTime(2026, 9, 15, 8),
          spentSeconds: 600,
        ),
      );

      final stats = await repository.stats(now: DateTime(2026, 9, 16, 21));
      expect(stats.totalSessions, 2);
      expect(stats.totalMinutes, 15);
      expect(stats.currentStreak, 2);
      expect(stats.cleanedToday, isTrue);
    });

    test('clearHistory keeps routines and schedules', () async {
      await repository.saveSession(sessionFixture());
      await repository.saveRoutine(
        CustomRoutine(
          id: 'routine-1',
          name: 'Sunday reset',
          room: CleaningRoom.wholeHome,
          minutes: 20,
          taskIds: const ['kitchen.counters'],
          createdAt: DateTime(2026, 9, 1),
        ),
      );

      await repository.clearHistory();

      expect(await repository.recentSessions(), isEmpty);
      expect(await repository.listRoutines(), hasLength(1));
    });
  });

  group('routines', () {
    test('round-trips a routine with its steps', () async {
      await repository.saveRoutine(
        CustomRoutine(
          id: 'routine-1',
          name: 'Guest ready',
          room: CleaningRoom.living,
          minutes: 15,
          taskIds: const ['living.cushions', 'living.table', 'unknown.id'],
          createdAt: DateTime(2026, 9, 16),
          isAtHome: true,
        ),
      );

      final routines = await repository.listRoutines();
      expect(routines, hasLength(1));
      expect(routines.first.name, 'Guest ready');
      expect(routines.first.isAtHome, isTrue);
      // Unknown ids are kept in storage but ignored when resolving the steps.
      expect(routines.first.taskIds, hasLength(3));
      expect(routines.first.tasks, hasLength(2));
      expect(routines.first.estimatedSeconds, 210);
    });

    test('only one routine can sit on Home', () async {
      for (final id in ['one', 'two', 'three']) {
        await repository.saveRoutine(
          CustomRoutine(
            id: id,
            name: 'Routine $id',
            room: CleaningRoom.kitchen,
            minutes: 5,
            taskIds: const ['kitchen.sink'],
            createdAt: DateTime(2026, 9, 16),
          ),
        );
      }
      await repository.setHomeRoutine('two');

      final routines = await repository.listRoutines();
      expect(
        routines.where((routine) => routine.isAtHome).map((r) => r.id),
        ['two'],
      );

      await repository.setHomeRoutine(null);
      final cleared = await repository.listRoutines();
      expect(cleared.where((routine) => routine.isAtHome), isEmpty);
    });

    test('deleting a routine removes it', () async {
      await repository.saveRoutine(
        CustomRoutine(
          id: 'routine-1',
          name: 'Temp',
          room: CleaningRoom.bathroom,
          minutes: 5,
          taskIds: const ['bathroom.mirror'],
          createdAt: DateTime(2026, 9, 16),
        ),
      );
      await repository.deleteRoutine('routine-1');
      expect(await repository.listRoutines(), isEmpty);
    });
  });

  group('schedules', () {
    test('round-trips a weekly schedule', () async {
      await repository.saveSchedule(
        CleaningSchedule(
          id: 'schedule-1',
          title: 'Weekend reset',
          room: CleaningRoom.wholeHome,
          minutes: 20,
          cadence: ScheduleCadence.weekly,
          weekday: DateTime.saturday,
          hour: 9,
          minute: 30,
          enabled: true,
        ),
      );

      final schedules = await repository.listSchedules();
      expect(schedules, hasLength(1));
      expect(schedules.first.cadence, ScheduleCadence.weekly);
      expect(schedules.first.weekday, DateTime.saturday);
      expect(schedules.first.timeLabel, '09:30');
      expect(schedules.first.cadenceLabel, 'Every Saturday · 09:30');
      expect(schedules.first.enabled, isTrue);
    });

    test('out-of-range times from storage are clamped', () async {
      final db = await database.database;
      await db.insert('cleaning_schedules', {
        'id': 'legacy',
        'title': 'Legacy row',
        'room': 'kitchen',
        'minutes': 5,
        'cadence': 'daily',
        'weekday': 9,
        'hour': 42,
        'minute': -5,
        'routine_id': null,
        'enabled': 0,
      });

      final schedules = await repository.listSchedules();
      expect(schedules.single.hour, 23);
      expect(schedules.single.minute, 0);
      expect(schedules.single.weekday, 7);
      expect(schedules.single.enabled, isFalse);
    });

    test('deleting a schedule removes it', () async {
      await repository.saveSchedule(
        CleaningSchedule(
          id: 'schedule-1',
          title: 'Daily tidy',
          room: CleaningRoom.kitchen,
          minutes: 5,
          cadence: ScheduleCadence.daily,
          weekday: DateTime.monday,
          hour: 20,
          minute: 0,
        ),
      );
      await repository.deleteSchedule('schedule-1');
      expect(await repository.listSchedules(), isEmpty);
    });
  });

  group('catalog defaults in storage', () {
    test('a stored routine always resolves against the live catalog', () {
      expect(
        CleaningCatalog.taskById('kitchen.counters')?.tier,
        1,
      );
    });
  });
}
