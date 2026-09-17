import 'dart:convert';

import 'package:cleanly/data/models/cleaning_session.dart';
import 'package:cleanly/domain/catalog/cleaning_catalog.dart';
import 'package:cleanly/state/active_session_store.dart';
import 'package:cleanly/state/session_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

ActiveSession _session({
  SessionStatus status = SessionStatus.running,
  int elapsed = 120,
  int planned = 600,
  DateTime? startedAt,
  List<bool> done = const [true, false, false],
}) {
  return ActiveSession(
    id: 'session-1',
    room: CleaningRoom.kitchen,
    plannedSeconds: planned,
    elapsedSeconds: elapsed,
    status: status,
    startedAt: startedAt ?? DateTime.now(),
    tasks: [
      for (var index = 0; index < done.length; index++)
        SessionTask(
          taskId: 'kitchen.task$index',
          title: 'Step $index',
          room: CleaningRoom.kitchen,
          seconds: 60,
          done: done[index],
        ),
    ],
  );
}

void main() {
  late SharedPreferences prefs;
  late ActiveSessionStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    store = ActiveSessionStore(prefs);
  });

  test('a saved session round-trips with its steps and room', () async {
    await store.save(_session());
    final loaded = store.load();

    expect(loaded, isNotNull);
    expect(loaded!.session.id, 'session-1');
    expect(loaded.session.room, CleaningRoom.kitchen);
    expect(loaded.session.elapsedSeconds, 120);
    expect(loaded.session.tasks, hasLength(3));
    expect(loaded.session.tasks.first.done, isTrue);
    expect(loaded.session.completedCount, 1);
  });

  test('an empty store loads as null', () {
    expect(store.load(), isNull);
  });

  test('corrupt data is discarded instead of crashing the app', () async {
    await prefs.setString(ActiveSessionStore.key, '{not json at all');

    expect(store.load(), isNull);
    expect(prefs.getString(ActiveSessionStore.key), isNull);
  });

  test('clearing removes the stored session', () async {
    await store.save(_session());
    await store.clear();

    expect(store.load(), isNull);
  });

  test('the saved timestamp is kept alongside the session', () async {
    final before = DateTime.now().subtract(const Duration(seconds: 1));
    await store.save(_session());
    final loaded = store.load();

    expect(loaded!.savedAt.isAfter(before), isTrue);
  });

  test('json keeps the paused status so a paused session stays paused', () {
    final json = _session(status: SessionStatus.paused).toJson(
      savedAt: DateTime.now(),
    );
    final decoded = jsonDecode(jsonEncode(json)) as Map<String, Object?>;

    expect(ActiveSession.fromJson(decoded).status, SessionStatus.paused);
  });

  test('an unknown status falls back to running instead of throwing', () {
    final decoded =
        jsonDecode(
              jsonEncode(
                _session().toJson(savedAt: DateTime.now())
                  ..['status'] = 'melting',
              ),
            )
            as Map<String, Object?>;

    expect(ActiveSession.fromJson(decoded).status, SessionStatus.running);
  });
}
