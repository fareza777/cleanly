import '../../domain/catalog/cleaning_catalog.dart';

/// Satu langkah seperti yang terjadi di dalam sesi (judul disalin agar riwayat
/// tetap terbaca walau katalog berubah di versi berikutnya).
class SessionTask {
  const SessionTask({
    required this.taskId,
    required this.title,
    required this.room,
    required this.seconds,
    required this.done,
  });

  final String taskId;
  final String title;
  final CleaningRoom room;
  final int seconds;
  final bool done;

  SessionTask copyWith({bool? done}) => SessionTask(
    taskId: taskId,
    title: title,
    room: room,
    seconds: seconds,
    done: done ?? this.done,
  );

  Map<String, Object?> toRow(String sessionId) => {
    'session_id': sessionId,
    'task_id': taskId,
    'title': title,
    'room': room.name,
    'seconds': seconds,
    'done': done ? 1 : 0,
  };

  static SessionTask fromRow(Map<String, Object?> row) => SessionTask(
    taskId: row['task_id']! as String,
    title: row['title']! as String,
    room: _roomFromName(row['room'] as String?),
    seconds: (row['seconds'] as int?) ?? 0,
    done: (row['done'] as int?) == 1,
  );

  Map<String, Object?> toJson() => {
    'task_id': taskId,
    'title': title,
    'room': room.name,
    'seconds': seconds,
    'done': done,
  };

  static SessionTask fromJson(Map<String, Object?> json) => SessionTask(
    taskId: json['task_id']! as String,
    title: json['title']! as String,
    room: _roomFromName(json['room'] as String?),
    seconds: (json['seconds'] as num?)?.toInt() ?? 0,
    done: json['done'] == true,
  );
}

/// Sesi pembersihan yang sudah selesai dan tersimpan di perangkat.
class CleaningSession {
  const CleaningSession({
    required this.id,
    required this.room,
    required this.minutes,
    required this.startedAt,
    required this.endedAt,
    required this.completedTasks,
    required this.totalTasks,
    required this.spentSeconds,
    this.routineId,
    this.routineName,
    this.tasks = const [],
  });

  final String id;
  final CleaningRoom room;
  final int minutes;
  final DateTime startedAt;
  final DateTime endedAt;
  final int completedTasks;
  final int totalTasks;
  final int spentSeconds;
  final String? routineId;
  final String? routineName;
  final List<SessionTask> tasks;

  RoomSpec get roomSpec => CleaningCatalog.specFor(room);

  bool get finishedEverything =>
      totalTasks > 0 && completedTasks >= totalTasks;

  /// Persentase tugas yang selesai, 0–1.
  double get completion => totalTasks == 0 ? 0 : completedTasks / totalTasks;

  int get spentMinutes => (spentSeconds / 60).round();

  Map<String, Object?> toRow() => {
    'id': id,
    'room': room.name,
    'minutes': minutes,
    'started_at': startedAt.millisecondsSinceEpoch,
    'ended_at': endedAt.millisecondsSinceEpoch,
    'completed_tasks': completedTasks,
    'total_tasks': totalTasks,
    'spent_seconds': spentSeconds,
    'routine_id': routineId,
    'routine_name': routineName,
  };

  static CleaningSession fromRow(
    Map<String, Object?> row, {
    List<SessionTask> tasks = const [],
  }) => CleaningSession(
    id: row['id']! as String,
    room: _roomFromName(row['room'] as String?),
    minutes: (row['minutes'] as int?) ?? 0,
    startedAt: DateTime.fromMillisecondsSinceEpoch(
      (row['started_at'] as int?) ?? 0,
    ),
    endedAt: DateTime.fromMillisecondsSinceEpoch(
      (row['ended_at'] as int?) ?? 0,
    ),
    completedTasks: (row['completed_tasks'] as int?) ?? 0,
    totalTasks: (row['total_tasks'] as int?) ?? 0,
    spentSeconds: (row['spent_seconds'] as int?) ?? 0,
    routineId: row['routine_id'] as String?,
    routineName: row['routine_name'] as String?,
    tasks: tasks,
  );
}

/// Ringkasan progres yang ditampilkan di Home dan History.
class CleaningStats {
  const CleaningStats({
    required this.totalSessions,
    required this.totalMinutes,
    required this.currentStreak,
    required this.longestStreak,
    required this.todayMinutes,
    required this.weekMinutes,
    required this.weekMinutesByDay,
    required this.cleanedToday,
    this.minutesByRoom = const {},
    this.sessionsByRoom = const {},
    this.lastSessionAt,
  });

  const CleaningStats.empty()
    : totalSessions = 0,
      totalMinutes = 0,
      currentStreak = 0,
      longestStreak = 0,
      todayMinutes = 0,
      weekMinutes = 0,
      weekMinutesByDay = const [0, 0, 0, 0, 0, 0, 0],
      cleanedToday = false,
      minutesByRoom = const {},
      sessionsByRoom = const {},
      lastSessionAt = null;

  final int totalSessions;
  final int totalMinutes;
  final int currentStreak;
  final int longestStreak;
  final int todayMinutes;
  final int weekMinutes;

  /// Menit per hari untuk minggu berjalan, Senin sampai Minggu.
  final List<int> weekMinutesByDay;
  final bool cleanedToday;

  /// Menit yang dihabiskan per area rumah. Hanya berisi area yang pernah
  /// dibersihkan, sehingga kartu wawasan tidak menampilkan baris kosong.
  final Map<CleaningRoom, int> minutesByRoom;
  final Map<CleaningRoom, int> sessionsByRoom;

  /// Waktu sesi terakhir disimpan, dipakai untuk nada Home ketika pengguna
  /// sudah lama tidak membersihkan.
  final DateTime? lastSessionAt;

  bool get hasHistory => totalSessions > 0;

  /// Hari kalender sejak sesi terakhir, atau `null` bila belum ada sesi.
  int? daysSinceLastSession(DateTime now) {
    final last = lastSessionAt;
    if (last == null) return null;
    return startOfDay(now).difference(startOfDay(last)).inDays;
  }

  /// Area yang paling sering dibersihkan, atau `null` bila belum ada sesi.
  CleaningRoom? get mostCleanedRoom {
    CleaningRoom? best;
    var bestMinutes = -1;
    for (final entry in sessionsByRoom.entries) {
      final minutes = minutesByRoom[entry.key] ?? 0;
      if (entry.value <= 0) continue;
      if (minutes > bestMinutes) {
        bestMinutes = minutes;
        best = entry.key;
      }
    }
    return best;
  }

  /// Hari terbaik dalam minggu ini, 0 bila belum ada sesi.
  int get weekBest =>
      weekMinutesByDay.fold<int>(0, (best, value) => value > best ? value : best);
}

/// Kunci tanggal lokal `yyyy-MM-dd`, dipakai untuk menghitung streak.
String dayKeyOf(DateTime time) {
  final local = time.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

DateTime startOfDay(DateTime time) {
  final local = time.toLocal();
  return DateTime(local.year, local.month, local.day);
}

/// Perhitungan streak dan ringkasan mingguan.
///
/// Fungsi murni supaya bisa diuji tanpa database: masukan sesi apa pun yang
/// urutannya tidak dijamin, keluaran selalu sama.
CleaningStats buildStats(
  Iterable<CleaningSession> sessions, {
  required DateTime now,
}) {
  final today = startOfDay(now);
  final minutesByDay = <String, int>{};
  final sessionsByDay = <String, int>{};
  final minutesByRoom = <CleaningRoom, int>{};
  final sessionsByRoom = <CleaningRoom, int>{};
  var totalMinutes = 0;
  var totalSessions = 0;
  DateTime? lastSessionAt;

  for (final session in sessions) {
    totalSessions += 1;
    final minutes = session.spentMinutes;
    totalMinutes += minutes;
    final key = dayKeyOf(session.startedAt);
    minutesByDay[key] = (minutesByDay[key] ?? 0) + minutes;
    sessionsByDay[key] = (sessionsByDay[key] ?? 0) + 1;
    minutesByRoom[session.room] = (minutesByRoom[session.room] ?? 0) + minutes;
    sessionsByRoom[session.room] = (sessionsByRoom[session.room] ?? 0) + 1;
    if (lastSessionAt == null || session.startedAt.isAfter(lastSessionAt)) {
      lastSessionAt = session.startedAt;
    }
  }

  // Streak berjalan: hari ini bila sudah bersih, atau berakhir kemarin
  // sehingga streak belum dianggap putus sebelum hari berjalan selesai.
  var currentStreak = 0;
  var cursor = sessionsByDay.containsKey(dayKeyOf(today))
      ? today
      : today.subtract(const Duration(days: 1));
  while (sessionsByDay.containsKey(dayKeyOf(cursor))) {
    currentStreak += 1;
    cursor = cursor.subtract(const Duration(days: 1));
  }

  // Streak terpanjang dihitung dari seluruh riwayat tersimpan.
  final activeDays = sessionsByDay.keys.toList()..sort();
  var longestStreak = 0;
  var run = 0;
  DateTime? previous;
  for (final key in activeDays) {
    final date = DateTime.parse(key);
    if (previous != null && date.difference(previous).inDays == 1) {
      run += 1;
    } else {
      run = 1;
    }
    if (run > longestStreak) longestStreak = run;
    previous = date;
  }

  final monday = today.subtract(Duration(days: today.weekday - 1));
  final weekMinutesByDay = <int>[
    for (var offset = 0; offset < 7; offset++)
      minutesByDay[dayKeyOf(monday.add(Duration(days: offset)))] ?? 0,
  ];

  return CleaningStats(
    totalSessions: totalSessions,
    totalMinutes: totalMinutes,
    currentStreak: currentStreak,
    longestStreak: longestStreak,
    todayMinutes: minutesByDay[dayKeyOf(today)] ?? 0,
    weekMinutes: weekMinutesByDay.fold(0, (sum, value) => sum + value),
    weekMinutesByDay: weekMinutesByDay,
    cleanedToday: sessionsByDay.containsKey(dayKeyOf(today)),
    minutesByRoom: minutesByRoom,
    sessionsByRoom: sessionsByRoom,
    lastSessionAt: lastSessionAt,
  );
}

CleaningRoom _roomFromName(String? name) {
  for (final room in CleaningRoom.values) {
    if (room.name == name) return room;
  }
  return CleaningRoom.living;
}
