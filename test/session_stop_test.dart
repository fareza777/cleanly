import 'package:cleanly/app.dart';
import 'package:cleanly/data/db/app_database.dart';
import 'package:cleanly/data/models/cleaning_schedule.dart';
import 'package:cleanly/data/models/cleaning_session.dart';
import 'package:cleanly/data/models/custom_routine.dart';
import 'package:cleanly/data/repo/cleaning_repository.dart';
import 'package:cleanly/domain/monetization/monetization_config.dart';
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

/// Repositori in-memory supaya tes tidak menyentuh berkas di disk.
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
  Future<void> deleteSession(String id) async {
    sessions.removeWhere((session) => session.id == id);
  }

  @override
  Future<void> clearHistory() async => sessions.clear();

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

  setUp(() async {
    repository = _MemoryRepository();
  });

  Future<void> startSession(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'cleanly.onboarding_done': true});
    final prefs = await SharedPreferences.getInstance();
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

    await tester.tap(find.text('Kitchen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.ensureVisible(find.text('Start 10-minute clean'));
    await tester.pump();
    await tester.tap(find.text('Start 10-minute clean'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(SessionScreen), findsOneWidget);
  }

  testWidgets('the X button stops the session and returns home', (tester) async {
    await startSession(tester);

    await tester.tap(find.byTooltip('Stop session'));
    await tester.pumpAndSettle();
    expect(find.text('Stop this session?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Stop'));
    await tester.pumpAndSettle();

    expect(find.text('Stop this session?'), findsNothing);
    expect(find.byType(SessionScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(repository.sessions, isEmpty);
  });

  testWidgets('Stop asks for confirmation and can be cancelled', (tester) async {
    await startSession(tester);

    await tester.tap(find.byTooltip('Stop session'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Keep cleaning'));
    await tester.pumpAndSettle();

    expect(find.byType(SessionScreen), findsOneWidget);
    expect(repository.sessions, isEmpty);
  });

  testWidgets('the system back gesture stops instead of losing the session', (
    tester,
  ) async {
    await startSession(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SessionScreen)),
    );
    expect(container.read(sessionControllerProvider), isNotNull);

    final widgetsBinding = tester.binding;
    await widgetsBinding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Stop this session?'), findsOneWidget);
    expect(container.read(sessionControllerProvider), isNotNull);
  });
}
