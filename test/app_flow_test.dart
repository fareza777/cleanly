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
import 'package:cleanly/ui/onboarding/onboarding_screen.dart';
import 'package:cleanly/ui/session/completion_screen.dart';
import 'package:cleanly/ui/session/session_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Repositori in-memory: seluruh method selesai sebagai microtask sehingga
/// cocok dengan clock palsu milik widget test.
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
  Future<CleaningSession?> sessionWithTasks(String id) async {
    for (final session in sessions) {
      if (session.id == id) return session;
    }
    return null;
  }

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

/// Build tanpa iklan: tidak ada permintaan ke SDK sehingga tidak ada timer
/// jaringan yang menggantung di akhir tes.
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
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repository = _MemoryRepository();
  });

  Future<void> pumpApp(WidgetTester tester, {bool onboarded = false}) async {
    SharedPreferences.setMockInitialValues({
      if (onboarded) 'cleanly.onboarding_done': true,
    });
    prefs = await SharedPreferences.getInstance();
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
  }

  Future<void> settleSplash(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 500));
  }

  /// Layar tinggi supaya seluruh isi Home (termasuk tombol mulai) benar-benar
  /// dibangun; daftar di Home tetap dirender ketika masuk viewport.
  void useTallPhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 4500);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  testWidgets('new install shows onboarding before the shell', (tester) async {
    await pumpApp(tester);
    await settleSplash(tester);

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('Little cleans that actually finish'), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(MainShell), findsOneWidget);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('How long do you have?'), findsOneWidget);
  });

  testWidgets('a finished session reaches the completion screen', (
    tester,
  ) async {
    useTallPhone(tester);

    await pumpApp(tester, onboarded: true);
    await settleSplash(tester);
    expect(find.byType(HomeScreen), findsOneWidget);

    // Tanpa area terpilih, tombol mulai hanya mengarahkan.
    expect(find.text('Pick a room to start'), findsOneWidget);

    await tester.tap(find.text('Kitchen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.textContaining('Kitchen · 5 steps'), findsOneWidget);
    expect(find.text('Start 10-minute clean'), findsOneWidget);

    await tester.ensureVisible(find.text('Start 10-minute clean'));
    await tester.pump();
    await tester.tap(find.text('Start 10-minute clean'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(SessionScreen), findsOneWidget);
    expect(find.text('Clear and wipe the counters'), findsWidgets);
    expect(find.text('0 of 5 steps ticked'), findsOneWidget);

    // Tandai satu langkah; daftar harus melaporkan progres baru.
    await tester.ensureVisible(find.text('Clear and wipe the counters').last);
    await tester.pump();
    await tester.tap(find.text('Clear and wipe the counters').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('1 of 5 steps ticked'), findsOneWidget);

    // Selesaikan lebih awal lewat tombol Finish.
    await tester.ensureVisible(find.text('Finish').last);
    await tester.pump();
    await tester.tap(find.text('Finish').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Finish now?'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Finish'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(CompletionScreen), findsOneWidget);
    expect(find.textContaining('better than before'), findsOneWidget);
    expect(find.text('1/5'), findsOneWidget);

    // Riwayat tersimpan lewat repositori, bukan hanya di layar.
    expect(repository.sessions, hasLength(1));
    expect(repository.sessions.single.completedTasks, 1);

    await tester.tap(find.text('Back home'));
    await tester.pumpAndSettle();

    expect(find.byType(MainShell), findsOneWidget);
    expect(find.text('Cleaned today'), findsOneWidget);
  });

  testWidgets('starting a session with no room is blocked', (tester) async {
    useTallPhone(tester);

    await pumpApp(tester, onboarded: true);
    await settleSplash(tester);

    await tester.ensureVisible(find.text('Pick a room to start'));
    await tester.pump();
    await tester.tap(find.text('Pick a room to start'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(SessionScreen), findsNothing);
    expect(repository.sessions, isEmpty);
  });

  testWidgets('duration pills change the plan and the button label', (
    tester,
  ) async {
    useTallPhone(tester);

    await pumpApp(tester, onboarded: true);
    await settleSplash(tester);

    await tester.tap(find.text('Bathroom'));
    await tester.pump();
    await tester.tap(find.text('20'));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Start 20-minute clean'), findsOneWidget);
    expect(find.textContaining('Bathroom · 7 steps'), findsOneWidget);
  });
}
