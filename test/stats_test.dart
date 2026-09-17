import 'package:cleanly/data/models/cleaning_session.dart';
import 'package:cleanly/domain/catalog/cleaning_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

CleaningSession _session(
  DateTime startedAt, {
  int spentSeconds = 300,
  CleaningRoom room = CleaningRoom.kitchen,
  int completed = 3,
  int total = 3,
}) {
  return CleaningSession(
    id: 'session-${startedAt.millisecondsSinceEpoch}-${startedAt.hour}',
    room: room,
    minutes: 5,
    startedAt: startedAt,
    endedAt: startedAt.add(Duration(seconds: spentSeconds)),
    completedTasks: completed,
    totalTasks: total,
    spentSeconds: spentSeconds,
  );
}

void main() {
  group('buildStats', () {
    test('empty history reports zeroes', () {
      final stats = buildStats(const [], now: DateTime(2026, 9, 16, 20));
      expect(stats.totalSessions, 0);
      expect(stats.totalMinutes, 0);
      expect(stats.currentStreak, 0);
      expect(stats.longestStreak, 0);
      expect(stats.cleanedToday, isFalse);
      expect(stats.hasHistory, isFalse);
      expect(stats.weekMinutesByDay, everyElement(0));
    });

    test('counts a streak that ends today', () {
      final stats = buildStats([
        _session(DateTime(2026, 9, 16, 9)),
        _session(DateTime(2026, 9, 15, 9)),
        _session(DateTime(2026, 9, 14, 9)),
        _session(DateTime(2026, 9, 11, 9)),
      ], now: DateTime(2026, 9, 16, 21));

      expect(stats.currentStreak, 3);
      expect(stats.longestStreak, 3);
      expect(stats.cleanedToday, isTrue);
      expect(stats.totalSessions, 4);
    });

    test('keeps the streak alive before today is cleaned', () {
      final stats = buildStats([
        _session(DateTime(2026, 9, 15, 9)),
        _session(DateTime(2026, 9, 14, 9)),
      ], now: DateTime(2026, 9, 16, 9));

      // Today is still open, so yesterday's run is not broken yet.
      expect(stats.currentStreak, 2);
      expect(stats.cleanedToday, isFalse);
    });

    test('a missed day resets the running streak but not the best one', () {
      final stats = buildStats([
        _session(DateTime(2026, 9, 16, 9)),
        _session(DateTime(2026, 9, 14, 9)),
        _session(DateTime(2026, 9, 13, 9)),
        _session(DateTime(2026, 9, 12, 9)),
      ], now: DateTime(2026, 9, 16, 21));

      expect(stats.currentStreak, 1);
      expect(stats.longestStreak, 3);
    });

    test('several sessions on one day count once toward the streak', () {
      final stats = buildStats([
        _session(DateTime(2026, 9, 16, 7), spentSeconds: 300),
        _session(DateTime(2026, 9, 16, 19), spentSeconds: 600),
        _session(DateTime(2026, 9, 15, 9), spentSeconds: 300),
      ], now: DateTime(2026, 9, 16, 22));

      expect(stats.currentStreak, 2);
      expect(stats.todayMinutes, 15);
      expect(stats.totalMinutes, 20);
    });

    test('weekly buckets start on Monday', () {
      // 16 September 2026 is a Wednesday, so Monday is the 14th.
      final stats = buildStats([
        _session(DateTime(2026, 9, 14, 9), spentSeconds: 300),
        _session(DateTime(2026, 9, 16, 9), spentSeconds: 600),
        // Previous week — must not land in this week's buckets.
        _session(DateTime(2026, 9, 13, 9), spentSeconds: 900),
      ], now: DateTime(2026, 9, 16, 21));

      expect(stats.weekMinutesByDay, [5, 0, 10, 0, 0, 0, 0]);
      expect(stats.weekMinutes, 15);
      expect(stats.weekBest, 10);
      expect(stats.totalMinutes, 30);
    });

    test('handles unsorted input', () {
      final stats = buildStats([
        _session(DateTime(2026, 9, 14, 9)),
        _session(DateTime(2026, 9, 16, 9)),
        _session(DateTime(2026, 9, 15, 9)),
      ], now: DateTime(2026, 9, 16, 21));

      expect(stats.currentStreak, 3);
      expect(stats.longestStreak, 3);
    });
  });

  group('session model', () {
    test('completion and minute rounding', () {
      final session = _session(
        DateTime(2026, 9, 16, 9),
        spentSeconds: 330,
        completed: 2,
        total: 4,
      );
      expect(session.completion, 0.5);
      expect(session.spentMinutes, 6);
      expect(session.finishedEverything, isFalse);
    });

    test('a session with no tasks never counts as finished', () {
      final session = _session(
        DateTime(2026, 9, 16, 9),
        completed: 0,
        total: 0,
      );
      expect(session.finishedEverything, isFalse);
      expect(session.completion, 0);
    });

    test('day keys use the local calendar day', () {
      expect(dayKeyOf(DateTime(2026, 9, 3, 23, 59)), '2026-09-03');
      expect(dayKeyOf(DateTime(2026, 1, 1, 0, 1)), '2026-01-01');
    });
  });
}
