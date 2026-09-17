import 'package:cleanly/data/models/cleaning_session.dart';
import 'package:cleanly/domain/catalog/cleaning_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

CleaningSession _session({
  required CleaningRoom room,
  required DateTime startedAt,
  int spentSeconds = 600,
  int completed = 3,
  int total = 3,
}) => CleaningSession(
  id: 'session-${startedAt.millisecondsSinceEpoch}-${room.name}',
  room: room,
  minutes: 10,
  startedAt: startedAt,
  endedAt: startedAt.add(Duration(seconds: spentSeconds)),
  completedTasks: completed,
  totalTasks: total,
  spentSeconds: spentSeconds,
);

void main() {
  final now = DateTime(2026, 3, 12, 20, 0);

  test('minutes and sessions are grouped per room', () {
    final stats = buildStats([
      _session(room: CleaningRoom.kitchen, startedAt: now, spentSeconds: 600),
      _session(
        room: CleaningRoom.kitchen,
        startedAt: now.subtract(const Duration(days: 1)),
        spentSeconds: 300,
      ),
      _session(
        room: CleaningRoom.bathroom,
        startedAt: now.subtract(const Duration(days: 2)),
        spentSeconds: 900,
      ),
    ], now: now);

    expect(stats.minutesByRoom[CleaningRoom.kitchen], 15);
    expect(stats.minutesByRoom[CleaningRoom.bathroom], 15);
    expect(stats.sessionsByRoom[CleaningRoom.kitchen], 2);
    expect(stats.sessionsByRoom[CleaningRoom.bedroom], isNull);
    expect(stats.mostCleanedRoom, anyOf(CleaningRoom.kitchen, CleaningRoom.bathroom));
  });

  test('the favourite room is the one with the most minutes', () {
    final stats = buildStats([
      _session(room: CleaningRoom.bedroom, startedAt: now, spentSeconds: 1800),
      _session(
        room: CleaningRoom.living,
        startedAt: now.subtract(const Duration(days: 1)),
        spentSeconds: 600,
      ),
    ], now: now);

    expect(stats.mostCleanedRoom, CleaningRoom.bedroom);
  });

  test('no history means no favourite room and no day count', () {
    final stats = buildStats(const [], now: now);

    expect(stats.minutesByRoom, isEmpty);
    expect(stats.mostCleanedRoom, isNull);
    expect(stats.daysSinceLastSession(now), isNull);
  });

  test('days since the last session counts calendar days, not hours', () {
    // Sesi terakhir kemarin pukul 23:00, sekarang pukul 20:00 — hanya 21 jam,
    // tetapi tetap satu hari kalender yang terlewat.
    final stats = buildStats([
      _session(
        room: CleaningRoom.kitchen,
        startedAt: DateTime(2026, 3, 11, 23, 0),
        spentSeconds: 600,
      ),
    ], now: now);

    expect(stats.daysSinceLastSession(now), 1);
    expect(stats.cleanedToday, isFalse);
  });

  test('the newest session wins regardless of input order', () {
    final stats = buildStats([
      _session(
        room: CleaningRoom.kitchen,
        startedAt: now.subtract(const Duration(days: 4)),
      ),
      _session(room: CleaningRoom.bathroom, startedAt: now),
      _session(
        room: CleaningRoom.living,
        startedAt: now.subtract(const Duration(days: 2)),
      ),
    ], now: now);

    expect(stats.daysSinceLastSession(now), 0);
    expect(stats.cleanedToday, isTrue);
    expect(stats.currentStreak, 1);
  });
}
