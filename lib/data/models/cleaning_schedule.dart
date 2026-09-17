import '../../domain/catalog/cleaning_catalog.dart';
import 'custom_routine.dart';

enum ScheduleCadence { daily, weekly }

/// Jadwal pembersihan berulang beserta jam pengingatnya.
///
/// Jadwal hanya memicu notifikasi lokal; tidak ada server dan tidak ada
/// sinkronisasi, sesuai sifat offline-first aplikasi.
class CleaningSchedule {
  const CleaningSchedule({
    required this.id,
    required this.title,
    required this.room,
    required this.minutes,
    required this.cadence,
    required this.weekday,
    required this.hour,
    required this.minute,
    this.routineId,
    this.enabled = true,
  });

  const CleaningSchedule.defaults()
    : id = '',
      title = '',
      room = CleaningRoom.wholeHome,
      minutes = 10,
      cadence = ScheduleCadence.daily,
      weekday = DateTime.saturday,
      hour = 9,
      minute = 0,
      routineId = null,
      enabled = false;

  final String id;
  final String title;
  final CleaningRoom room;
  final int minutes;
  final ScheduleCadence cadence;

  /// 1 = Senin sampai 7 = Minggu, mengikuti `DateTime.weekday`.
  final int weekday;
  final int hour;
  final int minute;
  final String? routineId;
  final bool enabled;

  RoomSpec get roomSpec => CleaningCatalog.specFor(room);

  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  static const weekdayNames = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  String get weekdayLabel =>
      weekdayNames[(weekday - 1).clamp(0, weekdayNames.length - 1)];

  String get cadenceLabel => cadence == ScheduleCadence.daily
      ? 'Every day · $timeLabel'
      : 'Every $weekdayLabel · $timeLabel';

  String get summary =>
      '${roomSpec.label} · $minutes min · $cadenceLabel';

  /// Kejadian berikutnya menurut jam dinding lokal.
  ///
  /// Tanggal dibangun ulang per hari (bukan penambahan 24 jam) supaya
  /// pergantian waktu musiman tidak menggeser jamnya.
  DateTime nextOccurrence({required DateTime now}) {
    for (var offset = 0; offset <= 7; offset++) {
      final candidate = DateTime(
        now.year,
        now.month,
        now.day + offset,
        hour,
        minute,
      );
      if (cadence == ScheduleCadence.weekly && candidate.weekday != weekday) {
        continue;
      }
      if (candidate.isAfter(now)) return candidate;
    }
    return DateTime(now.year, now.month, now.day + 1, hour, minute);
  }

  /// Label ringkas untuk kartu jadwal: "Today · 09:00", "Tomorrow · 18:30".
  String nextOccurrenceLabel({required DateTime now}) {
    final next = nextOccurrence(now: now);
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(next.year, next.month, next.day);
    final days = day.difference(today).inDays;
    final clock =
        '${next.hour.toString().padLeft(2, '0')}:'
        '${next.minute.toString().padLeft(2, '0')}';
    if (days == 0) return 'Today · $clock';
    if (days == 1) return 'Tomorrow · $clock';
    return '${weekdayNames[next.weekday - 1]} · $clock';
  }

  CleaningSchedule copyWith({
    String? title,
    CleaningRoom? room,
    int? minutes,
    ScheduleCadence? cadence,
    int? weekday,
    int? hour,
    int? minute,
    String? routineId,
    bool clearRoutine = false,
    bool? enabled,
  }) => CleaningSchedule(
    id: id,
    title: title ?? this.title,
    room: room ?? this.room,
    minutes: minutes ?? this.minutes,
    cadence: cadence ?? this.cadence,
    weekday: weekday ?? this.weekday,
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
    routineId: clearRoutine ? null : routineId ?? this.routineId,
    enabled: enabled ?? this.enabled,
  );

  Map<String, Object?> toRow() => {
    'id': id,
    'title': title,
    'room': room.name,
    'minutes': minutes,
    'cadence': cadence.name,
    'weekday': weekday,
    'hour': hour,
    'minute': minute,
    'routine_id': routineId,
    'enabled': enabled ? 1 : 0,
  };

  static CleaningSchedule fromRow(Map<String, Object?> row) {
    final cadenceName = row['cadence'] as String?;
    return CleaningSchedule(
      id: row['id']! as String,
      title: (row['title'] as String?) ?? 'Cleaning reminder',
      room: parseRoomName(row['room'] as String?),
      minutes: (row['minutes'] as int?) ?? 10,
      cadence: cadenceName == ScheduleCadence.weekly.name
          ? ScheduleCadence.weekly
          : ScheduleCadence.daily,
      weekday: ((row['weekday'] as int?) ?? 1).clamp(1, 7),
      hour: ((row['hour'] as int?) ?? 9).clamp(0, 23),
      minute: ((row['minute'] as int?) ?? 0).clamp(0, 59),
      routineId: row['routine_id'] as String?,
      enabled: (row['enabled'] as int?) == 1,
    );
  }
}
