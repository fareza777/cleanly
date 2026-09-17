import 'dart:io';
import 'dart:ui' as ui;
import 'package:cleanly/core/theme/app_theme.dart';
import 'package:cleanly/core/theme/app_colors.dart';
import 'package:cleanly/data/db/app_database.dart';
import 'package:cleanly/data/models/cleaning_schedule.dart';
import 'package:cleanly/data/models/cleaning_session.dart';
import 'package:cleanly/data/models/custom_routine.dart';
import 'package:cleanly/data/repo/cleaning_repository.dart';
import 'package:cleanly/domain/catalog/cleaning_catalog.dart';
import 'package:cleanly/domain/monetization/monetization_config.dart';
import 'package:cleanly/state/ads_provider.dart';
import 'package:cleanly/state/app_settings.dart';
import 'package:cleanly/state/cleaning_providers.dart';
import 'package:cleanly/state/session_controller.dart';
import 'package:cleanly/ui/navigation/main_shell.dart';
import 'package:cleanly/ui/schedule/schedule_screen.dart';
import 'package:cleanly/ui/session/session_screen.dart';
import 'package:cleanly/ui/session/completion_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Marketing captures use real production widgets and fictional local data.
// No network requests, live ads, customer data, or application code changes.
class DemoRepository extends CleaningRepository {
  DemoRepository()
    : super(
        AppDatabase(path: inMemoryDatabasePath, factory: databaseFactoryFfi),
      );
  final sessions = List.generate(12, (i) {
    final day = DateTime.now().subtract(Duration(days: i));
    final room = CleaningRoom.values[i % 4];
    final specs = CleaningCatalog.selectFor(room, minutes: 10);
    return CleaningSession(
      id: 'demo-$i',
      room: room,
      minutes: 10,
      startedAt: day.subtract(const Duration(minutes: 10)),
      endedAt: day,
      completedTasks: specs.length,
      totalTasks: specs.length,
      spentSeconds: 600,
      tasks: [
        for (final s in specs)
          SessionTask(
            taskId: s.id,
            title: s.title,
            room: s.room,
            seconds: s.seconds,
            done: true,
          ),
      ],
    );
  });
  @override
  Future<CleaningStats> stats({DateTime? now}) async =>
      buildStats(sessions, now: now ?? DateTime.now());
  @override
  Future<List<CleaningSession>> recentSessions({int limit = 40}) async =>
      sessions.take(limit).toList();
  @override
  Future<List<CustomRoutine>> listRoutines() async => [
    for (final entry in [
      (CleaningRoom.kitchen, 'After-dinner reset'),
      (CleaningRoom.bedroom, 'A calmer morning'),
      (CleaningRoom.living, 'Sunday fresh start'),
    ])
      CustomRoutine(
        id: entry.$2,
        name: entry.$2,
        room: entry.$1,
        minutes: 10,
        taskIds: CleaningCatalog.selectFor(
          entry.$1,
          minutes: 10,
        ).map((t) => t.id).toList(),
        createdAt: DateTime(2026, 9, 1),
      ),
  ];
  @override
  Future<List<CleaningSchedule>> listSchedules() async => const [
    CleaningSchedule(
      id: 'dinner',
      title: 'After-dinner reset',
      room: CleaningRoom.kitchen,
      minutes: 10,
      cadence: ScheduleCadence.daily,
      weekday: 1,
      hour: 19,
      minute: 30,
    ),
    CleaningSchedule(
      id: 'weekend',
      title: 'Weekend fresh start',
      room: CleaningRoom.wholeHome,
      minutes: 20,
      cadence: ScheduleCadence.weekly,
      weekday: 6,
      hour: 9,
      minute: 0,
    ),
  ];
}

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    final font = FontLoader('PlusJakartaSans');
    for (final weight in [
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
      'ExtraBold',
    ]) {
      font.addFont(rootBundle.load('assets/fonts/PlusJakartaSans-$weight.ttf'));
    }
    await font.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final name in [
    'home',
    'rooms',
    'session',
    'completion',
    'routines',
    'schedule',
    'history',
    'dark',
  ]) {
    testWidgets('store capture $name', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({
        'cleanly.onboarding_done': true,
        'cleanly.last_room': 'kitchen',
        'cleanly.last_minutes': 10,
        'cleanly.dark_mode': name == 'dark',
      });
      final prefs = await SharedPreferences.getInstance();
      final repo = DemoRepository();
      final container = ProviderContainer(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          cleaningRepositoryProvider.overrideWithValue(repo),
          monetizationConfigProvider.overrideWithValue(
            const MonetizationConfig(
              admobAppId: '',
              bannerAdUnitId: '',
              interstitialAdUnitId: '',
              rewardedAdUnitId: '',
              enableRewarded: false,
              isRelease: false,
            ),
          ),
        ],
      );
      final key = GlobalKey();
      Widget page = MainShell(
        initialIndex: name == 'routines'
            ? 1
            : name == 'history'
            ? 2
            : 0,
      );
      if (name == 'schedule') page = const ScheduleScreen();
      if (name == 'completion') {
        page = CompletionScreen(session: repo.sessions.first);
      }
      if (name == 'session') {
        container
            .read(sessionControllerProvider.notifier)
            .start(room: CleaningRoom.kitchen, minutes: 10);
        container.read(sessionControllerProvider.notifier).toggleTask(0);
        container.read(sessionControllerProvider.notifier).toggleTask(1);
        page = const SessionScreen();
      }
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.build(
              skin: ThemeSkin.defaultSkin,
              brightness: name == 'dark' ? Brightness.dark : Brightness.light,
            ),
            home: RepaintBoundary(key: key, child: page),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1200));
      if (name == 'rooms') {
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -345));
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(tester.takeException(), isNull);
      if (const bool.fromEnvironment('STORE_CAPTURES')) {
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final picture = await boundary.toImage(pixelRatio: 3);
          final data = await picture.toByteData(format: ui.ImageByteFormat.png);
          final dir = Directory('store/creative-2026-09/source-captures')
            ..createSync(recursive: true);
          File(
            '${dir.path}/$name.png',
          ).writeAsBytesSync(data!.buffer.asUint8List());
          picture.dispose();
        });
      }
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      await tester.pump();
    });
  }
}
