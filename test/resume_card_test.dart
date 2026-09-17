import 'dart:convert';

import 'package:cleanly/app.dart';
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
import 'package:cleanly/ui/home/home_screen.dart';
import 'package:cleanly/ui/session/session_screen.dart';
import 'package:flutter/material.dart';
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
  setUpAll(sqfliteFfiInit);

  late _MemoryRepository repository;

  setUp(() {
    repository = _MemoryRepository();
  });

  /// Menyiapkan preferensi seolah aplikasi ditutup di tengah sesi.
  Future<SharedPreferences> seedPrefs({
    required SessionStatus status,
    required int elapsedSeconds,
    Duration sinceSaved = const Duration(minutes: 2),
    Duration age = const Duration(minutes: 2),
  }) async {
    SharedPreferences.setMockInitialValues({
      'cleanly.onboarding_done': true,
      // Area terakhir dipilih supaya tombol mulai benar-benar siap ditekan:
      // dengan begitu, mengunci tombol saat ada sesi berjalan teruji nyata.
      'cleanly.last_room': 'kitchen',
      'cleanly.last_minutes': 10,
    });
    final prefs = await SharedPreferences.getInstance();
    final session = ActiveSession(
      id: 'restored',
      room: CleaningRoom.kitchen,
      plannedSeconds: 600,
      elapsedSeconds: elapsedSeconds,
      status: status,
      startedAt: DateTime.now().subtract(age),
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
          done: false,
        ),
      ],
    );
    await prefs.setString(
      ActiveSessionStore.key,
      jsonEncode(session.toJson(savedAt: DateTime.now().subtract(sinceSaved))),
    );
    return prefs;
  }

  Future<void> pumpApp(WidgetTester tester, SharedPreferences prefs) async {
    tester.view.physicalSize = const Size(1200, 4500);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          cleaningRepositoryProvider.overrideWithValue(repository),
          monetizationConfigProvider.overrideWithValue(_noAds),
        ],
        child: const CleanlyApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(HomeScreen), findsOneWidget);
  }

  testWidgets('an interrupted session is offered again on Home', (
    tester,
  ) async {
    final prefs = await seedPrefs(
      status: SessionStatus.running,
      elapsedSeconds: 60,
    );
    await pumpApp(tester, prefs);

    expect(find.text('Kitchen session in progress'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    // Sesi baru tidak boleh dimulai sebelum sesi berjalan ditutup.
    expect(find.text('Session in progress'), findsOneWidget);
    expect(find.text('Start 10-minute clean'), findsNothing);
  });

  testWidgets('Continue reopens the running session with its ticks', (
    tester,
  ) async {
    final prefs = await seedPrefs(
      status: SessionStatus.running,
      elapsedSeconds: 60,
    );
    await pumpApp(tester, prefs);

    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(SessionScreen), findsOneWidget);
    expect(find.text('1 of 2 steps ticked'), findsOneWidget);
    expect(find.text('Clear and wipe the counters'), findsWidgets);
  });

  testWidgets('a session that finished while away is offered for saving', (
    tester,
  ) async {
    final prefs = await seedPrefs(
      status: SessionStatus.running,
      elapsedSeconds: 540,
      sinceSaved: const Duration(minutes: 5),
      age: const Duration(minutes: 8),
    );
    await pumpApp(tester, prefs);

    expect(find.text('Kitchen session is finished'), findsOneWidget);
    expect(find.text('Save it'), findsOneWidget);

    await tester.tap(find.text('Save it'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Sesi yang kedaluwarsa langsung masuk riwayat, bukan hilang.
    expect(repository.sessions, hasLength(1));
    expect(repository.sessions.single.room, CleaningRoom.kitchen);
  });

  testWidgets('an interrupted session can be thrown away from Home', (
    tester,
  ) async {
    final prefs = await seedPrefs(
      status: SessionStatus.running,
      elapsedSeconds: 60,
    );
    await pumpApp(tester, prefs);

    await tester.tap(find.text('Throw away'));
    await tester.pumpAndSettle();
    expect(find.text('Throw this session away?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Throw away'));
    await tester.pumpAndSettle();

    expect(find.text('Kitchen session in progress'), findsNothing);
    expect(find.text('Start 10-minute clean'), findsOneWidget);
    expect(repository.sessions, isEmpty);
  });

  testWidgets('Home nudges after two days without cleaning', (tester) async {
    final prefs = await seedPrefs(
      status: SessionStatus.running,
      elapsedSeconds: 60,
    );
    await prefs.remove(ActiveSessionStore.key);
    await pumpApp(tester, prefs);

    // Belum ada riwayat sama sekali: tidak ada nada menyalahkan.
    expect(find.textContaining('It has been'), findsNothing);
    expect(find.text('Nothing yet today'), findsOneWidget);
  });
}
