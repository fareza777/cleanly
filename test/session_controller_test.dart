import 'package:cleanly/core/theme/app_colors.dart';
import 'package:cleanly/data/db/app_database.dart';
import 'package:cleanly/data/models/custom_routine.dart';
import 'package:cleanly/domain/catalog/cleaning_catalog.dart';
import 'package:cleanly/state/cleaning_providers.dart';
import 'package:cleanly/state/session_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late AppDatabase database;
  late ProviderContainer container;

  setUp(() {
    database = AppDatabase(
      path: inMemoryDatabasePath,
      factory: databaseFactoryFfi,
    );
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
  });

  tearDown(() async {
    container.dispose();
    await database.close();
  });

  SessionController controller() =>
      container.read(sessionControllerProvider.notifier);

  test('starts with no active session', () {
    expect(container.read(sessionControllerProvider), isNull);
    expect(controller().isActive, isFalse);
  });

  test('start builds a checklist and a full countdown', () {
    controller().start(room: CleaningRoom.kitchen, minutes: 10);
    final session = container.read(sessionControllerProvider)!;

    expect(session.plannedSeconds, 600);
    expect(session.tasks, hasLength(5));
    expect(session.completedCount, 0);
    expect(session.timeLabel, '10:00');
    expect(session.remainingSeconds, 600);
    expect(session.status, SessionStatus.running);
    expect(session.allTasksDone, isFalse);
    expect(session.nextTask?.taskId, 'kitchen.counters');
    expect(session.timeProgress, 0);
    expect(session.taskProgress, 0);
  });

  test('toggling a step updates progress and the next suggestion', () {
    controller().start(room: CleaningRoom.bedroom, minutes: 5);
    controller().toggleTask(0);

    var session = container.read(sessionControllerProvider)!;
    expect(session.completedCount, 1);
    expect(session.taskProgress, closeTo(1 / 3, 0.001));
    expect(session.nextTask?.taskId, 'bedroom.clothes');

    controller().toggleTask(0);
    session = container.read(sessionControllerProvider)!;
    expect(session.completedCount, 0);
  });

  test('toggling an out-of-range index is ignored', () {
    controller().start(room: CleaningRoom.living, minutes: 5);
    controller().toggleTask(99);
    controller().toggleTask(-1);
    expect(container.read(sessionControllerProvider)!.completedCount, 0);
  });

  test('starting from a routine uses the routine checklist', () {
    final routine = CustomRoutine(
      id: 'routine-1',
      name: 'My quick reset',
      room: CleaningRoom.bathroom,
      minutes: 5,
      taskIds: const ['bathroom.mirror', 'bathroom.sink'],
      createdAt: DateTime(2026, 9, 16),
    );

    controller().start(
      room: routine.room,
      minutes: routine.minutes,
      routine: routine,
    );
    final session = container.read(sessionControllerProvider)!;

    expect(session.tasks, hasLength(2));
    expect(session.routineName, 'My quick reset');
    expect(session.roomSpec.label, 'Bathroom');
    // Setiap ruangan punya keluarga aksennya sendiri untuk kartu dan ring.
    expect(
      session.accent(CleanlyColors.light).base,
      CleanlyColors.light.sky.base,
    );
  });

  test('the deep preset returns the full room list', () {
    controller().start(
      room: CleaningRoom.kitchen,
      minutes: CleaningCatalog.deepPresetMinutes,
      deepPreset: true,
    );
    final session = container.read(sessionControllerProvider)!;
    expect(
      session.tasks,
      hasLength(CleaningCatalog.tasksFor(CleaningRoom.kitchen).length),
    );
  });

  test('adding a step pulls the next catalog entry only once', () {
    controller().start(room: CleaningRoom.kitchen, minutes: 5);
    expect(container.read(sessionControllerProvider)!.tasks, hasLength(3));

    expect(controller().addNextCatalogTask(), isTrue);
    expect(container.read(sessionControllerProvider)!.tasks, hasLength(4));
    expect(controller().extraCatalogTasks(), isNotEmpty);

    final ids = [
      for (final task in container.read(sessionControllerProvider)!.tasks)
        task.taskId,
    ];
    expect(ids.toSet(), hasLength(ids.length));
  });

  test('pause and resume keep the elapsed time', () {
    controller().start(room: CleaningRoom.living, minutes: 5);
    controller().pause();
    expect(
      container.read(sessionControllerProvider)!.status,
      SessionStatus.paused,
    );
    expect(container.read(sessionControllerProvider)!.isPaused, isTrue);

    controller().pause();
    expect(container.read(sessionControllerProvider)!.isPaused, isTrue);

    controller().resume();
    expect(
      container.read(sessionControllerProvider)!.status,
      SessionStatus.running,
    );
  });

  test('discarding a session saves nothing', () async {
    controller().start(room: CleaningRoom.living, minutes: 5);
    controller().discard();

    expect(container.read(sessionControllerProvider), isNull);
    expect(
      await container.read(cleaningRepositoryProvider).recentSessions(),
      isEmpty,
    );
  });

  test('completing a session stores it and clears the active state', () async {
    controller().start(room: CleaningRoom.kitchen, minutes: 10);
    controller().toggleTask(0);
    final record = await controller().complete();

    expect(record, isNotNull);
    expect(record!.room, CleaningRoom.kitchen);
    expect(record.completedTasks, 1);
    expect(record.totalTasks, 5);
    expect(container.read(sessionControllerProvider), isNull);

    final saved = await container
        .read(cleaningRepositoryProvider)
        .sessionWithTasks(record.id);
    expect(saved, isNotNull);
    expect(saved!.tasks, hasLength(5));
    expect(saved.tasks.first.done, isTrue);

    final stats = await container.read(cleaningRepositoryProvider).stats();
    expect(stats.totalSessions, 1);
    expect(stats.cleanedToday, isTrue);
  });

  test('completing with no active session is a no-op', () async {
    expect(await controller().complete(), isNull);
    expect(
      await container.read(cleaningRepositoryProvider).recentSessions(),
      isEmpty,
    );
  });
}
