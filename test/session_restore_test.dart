import 'dart:convert';

import 'package:cleanly/data/db/app_database.dart';
import 'package:cleanly/data/models/cleaning_schedule.dart';
import 'package:cleanly/data/models/cleaning_session.dart';
import 'package:cleanly/data/models/custom_routine.dart';
import 'package:cleanly/data/repo/cleaning_repository.dart';
import 'package:cleanly/domain/catalog/cleaning_catalog.dart';
import 'package:cleanly/domain/monetization/monetization_config.dart';
import 'package:cleanly/state/active_session_store.dart';
import 'package:cleanly/state/ads_provider.dart';
import 'package:cleanly/state/app_settings.dart';
import 'package:cleanly/state/cleaning_providers.dart';
import 'package:cleanly/state/session_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _MemoryRepository extends CleaningRepository {
  _MemoryRepository()
    : super(AppDatabase(path: inMemoryDatabasePath, factory: databaseFactoryFfi));

  final sessions = <CleaningSession>[];

  @override
  Future<CleaningStats> stats({DateTime? now}) async =>
      buildStats(sessions, now: now ?? DateTime.now());

  @override
  Future<List<CleaningSession>> recentSessions({int limit = 40}) async =>
      sessions.reversed.take(limit).toList();

  @override
  Future<void> saveSession(CleaningSession session) async {
    sessions.add(session);
  }

  @override
  Future<List<CustomRoutine>> listRoutines() async => const [];

  @override
  Future<List<CleaningSchedule>> listSchedules() async => const [];
}

const _noAds = MonetizationConfig(
  admobAppId: '',
  bannerAdUnitId: '',
  interstitialAdUnitId: '',
  rewardedAdUnitId: '',
  enableRewarded: false,
  isRelease: false,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(sqfliteFfiInit);

  late SharedPreferences prefs;
  late _MemoryRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repository = _MemoryRepository();
  });

  ProviderContainer buildContainer() {
    final container = ProviderContainer(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        cleaningRepositoryProvider.overrideWithValue(repository),
        monetizationConfigProvider.overrideWithValue(_noAds),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Menulis sesi langsung ke penyimpanan, dengan stempel waktu yang bisa
  /// ditentukan supaya "aplikasi tertutup sekian lama" bisa diuji.
  Future<void> seed({
    required int elapsedSeconds,
    required Duration sinceSaved,
    SessionStatus status = SessionStatus.running,
    int plannedSeconds = 600,
    Duration age = const Duration(minutes: 1),
  }) async {
    final session = ActiveSession(
      id: 'seeded',
      room: CleaningRoom.bathroom,
      plannedSeconds: plannedSeconds,
      elapsedSeconds: elapsedSeconds,
      status: status,
      startedAt: DateTime.now().subtract(age),
      tasks: const [
        SessionTask(
          taskId: 'bathroom.sink',
          title: 'Wipe the sink and counter',
          room: CleaningRoom.bathroom,
          seconds: 120,
          done: true,
        ),
      ],
    );
    await prefs.setString(
      ActiveSessionStore.key,
      jsonEncode(
        session.toJson(savedAt: DateTime.now().subtract(sinceSaved)),
      ),
    );
  }

  test('time that passed while the app was closed is counted', () async {
    await seed(elapsedSeconds: 60, sinceSaved: const Duration(minutes: 3));

    final restored = buildContainer().read(sessionControllerProvider);

    expect(restored, isNotNull);
    expect(restored!.elapsedSeconds, greaterThanOrEqualTo(240));
    expect(restored.room, CleaningRoom.bathroom);
    expect(restored.status, SessionStatus.running);
  });

  test('a paused session does not advance while the app is away', () async {
    await seed(
      elapsedSeconds: 120,
      sinceSaved: const Duration(minutes: 30),
      status: SessionStatus.paused,
    );

    final restored = buildContainer().read(sessionControllerProvider);

    expect(restored!.elapsedSeconds, 120);
    expect(restored.status, SessionStatus.paused);
  });

  test('a session that ran out while away comes back finished', () async {
    await seed(elapsedSeconds: 300, sinceSaved: const Duration(minutes: 30));

    final restored = buildContainer().read(sessionControllerProvider);

    expect(restored!.status, SessionStatus.finished);
    expect(restored.remainingSeconds, 0);
  });

  test('a session older than a day is dropped and cleaned up', () async {
    await seed(
      elapsedSeconds: 60,
      sinceSaved: const Duration(hours: 30),
      age: const Duration(hours: 30),
    );

    final restored = buildContainer().read(sessionControllerProvider);

    expect(restored, isNull);
    expect(prefs.getString(ActiveSessionStore.key), isNull);
  });

  test('starting a session writes it to storage', () async {
    final container = buildContainer();
    container
        .read(sessionControllerProvider.notifier)
        .start(room: CleaningRoom.kitchen, minutes: 5);
    await container.pump();

    expect(prefs.getString(ActiveSessionStore.key), isNotNull);
  });

  test('discarding clears storage', () async {
    final container = buildContainer();
    final controller = container.read(sessionControllerProvider.notifier);
    controller.start(room: CleaningRoom.kitchen, minutes: 5);
    await container.pump();

    controller.discard();
    await container.pump();

    expect(container.read(sessionControllerProvider), isNull);
    expect(prefs.getString(ActiveSessionStore.key), isNull);
  });

  test('completing saves the record and clears the stored session', () async {
    final container = buildContainer();
    final controller = container.read(sessionControllerProvider.notifier);
    controller.start(room: CleaningRoom.kitchen, minutes: 5);
    controller.toggleTask(0);
    await container.pump();

    final record = await controller.complete();
    await container.pump();

    expect(record, isNotNull);
    expect(record!.completedTasks, 1);
    expect(repository.sessions, hasLength(1));
    expect(prefs.getString(ActiveSessionStore.key), isNull);
  });

  test('ticking a step updates the stored copy', () async {
    final container = buildContainer();
    final controller = container.read(sessionControllerProvider.notifier);
    controller.start(room: CleaningRoom.kitchen, minutes: 5);
    controller.toggleTask(0);
    await container.pump();

    final stored = ActiveSessionStore(prefs).load();
    expect(stored!.session.tasks.first.done, isTrue);
  });

  test('pausing stops the countdown from advancing on its own', () async {
    final container = buildContainer();
    final controller = container.read(sessionControllerProvider.notifier);
    controller.start(room: CleaningRoom.kitchen, minutes: 5);
    await container.pump();

    controller.pause();
    final paused = container.read(sessionControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    expect(container.read(sessionControllerProvider)!.elapsedSeconds,
        paused!.elapsedSeconds);

    controller.resume();
    expect(container.read(sessionControllerProvider)!.isPaused, isFalse);
  });
}
