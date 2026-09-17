import 'package:cleanly/data/models/cleaning_schedule.dart';
import 'package:cleanly/domain/catalog/cleaning_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

CleaningSchedule _schedule({
  ScheduleCadence cadence = ScheduleCadence.daily,
  int weekday = DateTime.saturday,
  int hour = 9,
  int minute = 0,
}) => CleaningSchedule(
  id: 'schedule-1',
  title: 'Reset',
  room: CleaningRoom.wholeHome,
  minutes: 10,
  cadence: cadence,
  weekday: weekday,
  hour: hour,
  minute: minute,
);

void main() {
  test('a daily reminder later today keeps the same day', () {
    final now = DateTime(2026, 3, 10, 7, 30);
    final next = _schedule(hour: 9).nextOccurrence(now: now);

    expect(next, DateTime(2026, 3, 10, 9, 0));
    expect(_schedule(hour: 9).nextOccurrenceLabel(now: now), 'Today · 09:00');
  });

  test('a daily reminder already past rolls to tomorrow', () {
    final now = DateTime(2026, 3, 10, 9, 0);
    final next = _schedule(hour: 9).nextOccurrence(now: now);

    expect(next, DateTime(2026, 3, 11, 9, 0));
    expect(_schedule(hour: 9).nextOccurrenceLabel(now: now), 'Tomorrow · 09:00');
  });

  test('the first minute of the day still schedules for the same day', () {
    final now = DateTime(2026, 3, 10, 0, 0);
    final next = _schedule(hour: 0, minute: 5).nextOccurrence(now: now);

    expect(next, DateTime(2026, 3, 10, 0, 5));
  });

  test('a weekly reminder lands on the requested weekday', () {
    // Selasa 10 Maret 2026; jadwal hari Sabtu.
    final now = DateTime(2026, 3, 10, 7, 30);
    final schedule = _schedule(
      cadence: ScheduleCadence.weekly,
      weekday: DateTime.saturday,
      hour: 8,
      minute: 15,
    );
    final next = schedule.nextOccurrence(now: now);

    expect(next, DateTime(2026, 3, 14, 8, 15));
    expect(next.weekday, DateTime.saturday);
    expect(schedule.nextOccurrenceLabel(now: now), 'Saturday · 08:15');
  });

  test('a weekly reminder on the same weekday but later still fires today', () {
    // Jumat 13 Maret 2026 pukul 07:00, jadwal Jumat 18:00.
    final now = DateTime(2026, 3, 13, 7, 0);
    final next = _schedule(
      cadence: ScheduleCadence.weekly,
      weekday: DateTime.friday,
      hour: 18,
      minute: 0,
    ).nextOccurrence(now: now);

    expect(next, DateTime(2026, 3, 13, 18, 0));
  });

  test('the month boundary is crossed without skipping a day', () {
    final now = DateTime(2026, 3, 31, 22, 0);
    final next = _schedule(hour: 9).nextOccurrence(now: now);

    expect(next, DateTime(2026, 4, 1, 9, 0));
  });

  test('a weekly reminder never returns more than seven days out', () {
    final now = DateTime(2026, 3, 10, 7, 30);
    for (var weekday = 1; weekday <= 7; weekday++) {
      final next = _schedule(
        cadence: ScheduleCadence.weekly,
        weekday: weekday,
      ).nextOccurrence(now: now);
      expect(next.difference(now).inDays, lessThanOrEqualTo(7));
      expect(next.isAfter(now), isTrue);
      expect(next.weekday, weekday);
    }
  });
}
