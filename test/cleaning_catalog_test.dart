import 'package:cleanly/domain/catalog/cleaning_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('selectFor', () {
    test('5 minutes gives the three quick wins', () {
      final tasks = CleaningCatalog.selectFor(
        CleaningRoom.kitchen,
        minutes: 5,
      );
      expect(tasks, hasLength(3));
      expect(tasks.every((task) => task.tier == 1), isTrue);
      expect(
        tasks.map((task) => task.id),
        contains('kitchen.counters'),
      );
    });

    test('10 minutes adds two standard steps', () {
      final tasks = CleaningCatalog.selectFor(
        CleaningRoom.bathroom,
        minutes: 10,
      );
      expect(tasks, hasLength(5));
      expect(tasks.where((task) => task.tier == 2), hasLength(2));
    });

    test('20 minutes completes the standard list', () {
      final tasks = CleaningCatalog.selectFor(
        CleaningRoom.bedroom,
        minutes: 20,
      );
      expect(tasks.where((task) => task.tier == 1), hasLength(3));
      expect(tasks.where((task) => task.tier == 2), hasLength(4));
      expect(tasks.where((task) => task.tier == 3), isEmpty);
    });

    test('30 minutes reaches the deep clean steps', () {
      final tasks = CleaningCatalog.selectFor(
        CleaningRoom.living,
        minutes: 30,
      );
      expect(tasks.where((task) => task.tier == 3), hasLength(3));
      expect(tasks.length, greaterThan(8));
    });

    test('each room always returns a short list for tiny sessions', () {
      for (final spec in CleaningCatalog.rooms) {
        final tasks = CleaningCatalog.selectFor(spec.room, minutes: 2);
        expect(tasks, isNotEmpty, reason: '${spec.label} had no 2-min steps');
        expect(tasks, hasLength(1));
      }
    });
  });

  group('estimates', () {
    test('a 5-minute plan stays close to five minutes of work', () {
      for (final spec in CleaningCatalog.rooms) {
        final seconds = CleaningCatalog.totalSeconds(
          CleaningCatalog.selectFor(spec.room, minutes: 5),
        );
        expect(
          seconds,
          inInclusiveRange(240, 420),
          reason: '${spec.label} planned $seconds seconds for a 5-minute slot',
        );
      }
    });

    test('session plans grow with the chosen duration', () {
      for (final spec in CleaningCatalog.rooms) {
        var previous = 0;
        for (final minutes in CleaningCatalog.durations) {
          final seconds = CleaningCatalog.totalSeconds(
            CleaningCatalog.selectFor(spec.room, minutes: minutes),
          );
          expect(seconds, greaterThanOrEqualTo(previous));
          previous = seconds;
        }
      }
    });
  });

  group('homeReset', () {
    test('touches every room', () {
      final tasks = CleaningCatalog.homeReset(minutes: 20);
      final rooms = {for (final task in tasks) task.room};
      expect(rooms, hasLength(4));
      expect(tasks.every((task) => task.room != CleaningRoom.wholeHome), isTrue);
    });

    test('a 10 minute reset keeps one step per room', () {
      final tasks = CleaningCatalog.homeReset(minutes: 10);
      expect(tasks, hasLength(4));
    });

    test('planning through the whole-home room matches the helper', () {
      final direct = CleaningCatalog.homeReset(minutes: 20);
      final viaRoom = CleaningCatalog.selectFor(
        CleaningRoom.wholeHome,
        minutes: 20,
      );
      expect(viaRoom.map((task) => task.id), direct.map((task) => task.id));
    });
  });

  group('catalog integrity', () {
    test('task ids are unique', () {
      final ids = [for (final task in CleaningCatalog.tasks) task.id];
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('every real room has three quick wins, four standard and deep steps', () {
      for (final spec in CleaningCatalog.rooms) {
        final tasks = CleaningCatalog.tasksFor(spec.room);
        expect(tasks.where((task) => task.tier == 1), hasLength(3));
        expect(tasks.where((task) => task.tier == 2), hasLength(4));
        expect(
          tasks.where((task) => task.tier == 3).length,
          greaterThanOrEqualTo(3),
        );
        expect(tasks.every((task) => task.seconds > 0), isTrue);
        expect(tasks.every((task) => task.hint.trim().isNotEmpty), isTrue);
      }
    });

    test('the deep preset covers every step of a room', () {
      for (final spec in CleaningCatalog.rooms) {
        expect(
          CleaningCatalog.deepPreset(spec.room),
          hasLength(CleaningCatalog.tasksFor(spec.room).length),
        );
      }
    });
  });
}
