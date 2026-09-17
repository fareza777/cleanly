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
import 'package:cleanly/ui/home/home_screen.dart';
import 'package:cleanly/ui/navigation/main_shell.dart';
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

/// Menggulir daftar di dalam [screen] sampai [target] benar-benar dibangun.
Future<void> scrollTo(
  WidgetTester tester,
  Finder screen,
  Finder target,
) async {
  await tester.scrollUntilVisible(
    target,
    140,
    scrollable: find.descendant(of: screen, matching: find.byType(Scrollable)).first,
    maxScrolls: 40,
  );
  await tester.pump();
}

/// Ukuran layar yang benar-benar dijual di pasaran, dari yang paling kecil.
const _viewports = <String, Size>{
  'compact 320x568': Size(320, 568),
  'small 360x640': Size(360, 640),
  'tall 412x915': Size(412, 915),
};

void main() {
  setUpAll(sqfliteFfiInit);

  late _MemoryRepository repository;

  setUp(() {
    repository = _MemoryRepository();
  });

  for (final entry in _viewports.entries) {
    testWidgets('the whole flow fits on ${entry.key}', (tester) async {
      SharedPreferences.setMockInitialValues({
        'cleanly.onboarding_done': true,
        'cleanly.last_room': 'kitchen',
        'cleanly.last_minutes': 10,
      });
      final prefs = await SharedPreferences.getInstance();
      tester.view.physicalSize = entry.value * 3;
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

      // Setiap tab harus bisa dirender tanpa meluap.
      for (final tab in ['Routines', 'History', 'Settings', 'Clean']) {
        await tester.tap(find.text(tab));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
      }
      expect(find.byType(MainShell), findsOneWidget);

      // Lalu seluruh layar sesi, termasuk overlay jeda. Pada layar pendek
      // tombol mulai berada di luar viewport, jadi digulir dulu — persis
      // seperti yang dilakukan pengguna.
      await scrollTo(tester, find.byType(HomeScreen), find.text('Start 10-minute clean'));
      await tester.tap(find.text('Start 10-minute clean'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(SessionScreen), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Pause'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('PAUSED'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Resume'), findsOneWidget);

      await scrollTo(tester, find.byType(SessionScreen), find.text('Add another step'));
      await tester.tap(find.text('Add another step'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }
}
