import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/theme/app_colors.dart';
import '../data/models/cleaning_session.dart';
import '../data/models/custom_routine.dart';
import '../domain/catalog/cleaning_catalog.dart';
import '../domain/notifications/notification_service.dart';
import 'active_session_store.dart';
import 'app_settings.dart';
import 'cleaning_providers.dart';

enum SessionStatus { running, paused, finished }

/// Sesi yang sedang berjalan. Sisa waktu selalu dihitung dari waktu nyata,
/// bukan dari jumlah detik yang dihitung, sehingga timer tetap benar setelah
/// aplikasi lama berada di latar belakang.
class ActiveSession {
  const ActiveSession({
    required this.id,
    required this.room,
    required this.tasks,
    required this.plannedSeconds,
    required this.startedAt,
    this.elapsedSeconds = 0,
    this.status = SessionStatus.running,
    this.routineId,
    this.routineName,
  });

  final String id;
  final CleaningRoom room;
  final List<SessionTask> tasks;
  final int plannedSeconds;
  final DateTime startedAt;
  final int elapsedSeconds;
  final SessionStatus status;
  final String? routineId;
  final String? routineName;

  RoomSpec get roomSpec => CleaningCatalog.specFor(room);

  AccentFamily accent(CleanlyColors colors) => colors.accentFor(roomSpec.accent);

  int get remainingSeconds =>
      math.max(0, plannedSeconds - elapsedSeconds);

  int get completedCount => tasks.where((task) => task.done).length;

  int get totalCount => tasks.length;

  bool get isPaused => status == SessionStatus.paused;

  bool get allTasksDone => tasks.isNotEmpty && completedCount >= tasks.length;

  /// Bagian waktu yang sudah berjalan, 0–1; dipakai ring timer.
  double get timeProgress => plannedSeconds == 0
      ? 1
      : (elapsedSeconds / plannedSeconds).clamp(0.0, 1.0);

  /// Bagian tugas yang sudah selesai, 0–1; dipakai bilah progres.
  double get taskProgress => tasks.isEmpty ? 0 : completedCount / tasks.length;

  /// Langkah berikutnya yang belum dicentang.
  SessionTask? get nextTask {
    for (final task in tasks) {
      if (!task.done) return task;
    }
    return null;
  }

  String get timeLabel {
    final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Menit sisa yang dibulatkan ke atas, untuk label ringkas.
  int get remainingMinutesCeil => (remainingSeconds / 60).ceil();

  /// Perkiraan waktu berakhir, dipakai untuk notifikasi pengingat.
  DateTime get plannedEnd => startedAt.add(Duration(seconds: plannedSeconds));

  ActiveSession copyWith({
    List<SessionTask>? tasks,
    int? elapsedSeconds,
    SessionStatus? status,
  }) => ActiveSession(
    id: id,
    room: room,
    tasks: tasks ?? this.tasks,
    plannedSeconds: plannedSeconds,
    startedAt: startedAt,
    elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    status: status ?? this.status,
    routineId: routineId,
    routineName: routineName,
  );

  /// Hasil akhir yang disimpan ke riwayat.
  CleaningSession toRecord({required DateTime endedAt, required bool completed}) {
    final spent = elapsedSeconds.clamp(0, plannedSeconds);
    return CleaningSession(
      id: id,
      room: room,
      minutes: (plannedSeconds / 60).round(),
      startedAt: startedAt,
      endedAt: endedAt,
      completedTasks: completedCount,
      totalTasks: tasks.length,
      spentSeconds: completed ? plannedSeconds : spent,
      routineId: routineId,
      routineName: routineName,
      tasks: tasks,
    );
  }

  /// Serialisasi untuk [ActiveSessionStore]. [savedAt] dipakai saat memuat
  /// kembali agar waktu yang berjalan sementara aplikasi tertutup ikut
  /// terhitung — kecuali saat sesi sedang dijeda.
  Map<String, Object?> toJson({required DateTime savedAt}) => {
    'id': id,
    'room': room.name,
    'planned_seconds': plannedSeconds,
    'elapsed_seconds': elapsedSeconds,
    'status': status.name,
    'started_at': startedAt.millisecondsSinceEpoch,
    'saved_at': savedAt.millisecondsSinceEpoch,
    'routine_id': routineId,
    'routine_name': routineName,
    'tasks': [for (final task in tasks) task.toJson()],
  };

  static ActiveSession fromJson(Map<String, Object?> json) => ActiveSession(
    id: json['id']! as String,
    room: parseRoomName(json['room'] as String?),
    plannedSeconds: (json['planned_seconds'] as num?)?.toInt() ?? 0,
    elapsedSeconds: (json['elapsed_seconds'] as num?)?.toInt() ?? 0,
    status: _statusFromName(json['status'] as String?),
    startedAt: DateTime.fromMillisecondsSinceEpoch(
      (json['started_at'] as num?)?.toInt() ?? 0,
    ),
    routineId: json['routine_id'] as String?,
    routineName: json['routine_name'] as String?,
    tasks: [
      for (final raw in (json['tasks'] as List<Object?>? ?? const []))
        SessionTask.fromJson(raw! as Map<String, Object?>),
    ],
  );

  static SessionStatus _statusFromName(String? name) {
    for (final status in SessionStatus.values) {
      if (status.name == name) return status;
    }
    return SessionStatus.running;
  }
}

class SessionController extends Notifier<ActiveSession?> {
  static const _uuid = Uuid();

  /// Sesi yang lebih tua dari ini dianggap sudah tidak relevan dan dibuang
  /// saat aplikasi dibuka kembali.
  static const _maxRestoreAge = Duration(hours: 24);

  Timer? _ticker;
  DateTime? _lastTick;
  var _ticksSinceSave = 0;

  /// Penyimpanan sesi, atau `null` bila preferensi belum tersedia.
  ///
  /// Aplikasi selalu meng-override [sharedPrefsProvider] saat dijalankan;
  /// pada tes unit yang tidak menyediakannya, sesi tetap berjalan penuh di
  /// memori tanpa membuat pengujian gagal.
  ActiveSessionStore? get _store {
    try {
      return ActiveSessionStore(ref.read(sharedPrefsProvider));
    } catch (_) {
      return null;
    }
  }

  @override
  ActiveSession? build() {
    ref.onDispose(_stopTicker);
    final restored = _restore();
    if (restored == null) return null;
    if (restored.status == SessionStatus.running) _startTicker();
    return restored;
  }

  bool get isActive => state != null;

  /// Memuat sesi yang tertinggal dari penyimpanan lokal.
  ///
  /// Waktu yang berjalan sementara aplikasi tertutup ikut dihitung, kecuali
  /// bila sesi sedang dijeda. Sesi yang sudah kedaluwarsa diabaikan.
  ActiveSession? _restore() {
    final store = _store;
    final persisted = store?.load();
    if (persisted == null) return null;
    final raw = persisted.session;
    final now = DateTime.now();
    if (now.difference(raw.startedAt) > _maxRestoreAge) {
      unawaited(store?.clear());
      return null;
    }
    if (raw.status == SessionStatus.paused) return raw;
    final away = now.difference(persisted.savedAt).inSeconds;
    if (away <= 0) return raw;
    final elapsed = math.min(raw.plannedSeconds, raw.elapsedSeconds + away);
    if (elapsed >= raw.plannedSeconds) {
      return raw.copyWith(
        elapsedSeconds: raw.plannedSeconds,
        status: SessionStatus.finished,
      );
    }
    return raw.copyWith(elapsedSeconds: elapsed);
  }

  /// Memulai sesi baru. Daftar langkah dihitung dari katalog kecuali
  /// [routine] diberikan.
  void start({
    required CleaningRoom room,
    required int minutes,
    CustomRoutine? routine,
    bool deepPreset = false,
  }) {
    final specs = routine?.tasks ??
        (deepPreset
            ? CleaningCatalog.deepPreset(room)
            : CleaningCatalog.selectFor(room, minutes: minutes));
    final seconds = minutes * 60;
    state = ActiveSession(
      id: _uuid.v4(),
      room: room,
      tasks: [
        for (final spec in specs)
          SessionTask(
            taskId: spec.id,
            title: spec.title,
            room: spec.room,
            seconds: spec.seconds,
            done: false,
          ),
      ],
      // Timer tetap memakai durasi pilihan pengguna walau perkiraan daftar
      // lebih pendek, supaya "5 menit" benar-benar berarti 5 menit.
      plannedSeconds: seconds,
      startedAt: DateTime.now(),
      routineId: routine?.id,
      routineName: routine?.name,
    );
    _startTicker();
    _persist();
    _scheduleFinishAlert(state!);
  }

  void toggleTask(int index) {
    final current = state;
    if (current == null || index < 0 || index >= current.tasks.length) return;
    final tasks = [...current.tasks];
    tasks[index] = tasks[index].copyWith(done: !tasks[index].done);
    state = current.copyWith(tasks: tasks);
    _persist();
  }

  /// Menambahkan satu langkah ekstra dari katalog area yang sama.
  bool addNextCatalogTask() {
    final current = state;
    if (current == null) return false;
    final existing = {for (final task in current.tasks) task.taskId};
    final pool = CleaningCatalog.tasksFor(current.room);
    for (final spec in pool) {
      if (existing.contains(spec.id)) continue;
      state = current.copyWith(
        tasks: [
          ...current.tasks,
          SessionTask(
            taskId: spec.id,
            title: spec.title,
            room: spec.room,
            seconds: spec.seconds,
            done: false,
          ),
        ],
      );
      _persist();
      return true;
    }
    return false;
  }

  /// Sisa langkah katalog yang belum ada di daftar, untuk pratinjau tombol
  /// "add a step".
  List<CleaningTaskSpec> extraCatalogTasks() {
    final current = state;
    if (current == null) return const [];
    final existing = {for (final task in current.tasks) task.taskId};
    return [
      for (final spec in CleaningCatalog.tasksFor(current.room))
        if (!existing.contains(spec.id)) spec,
    ];
  }

  void pause() {
    final current = state;
    if (current == null || current.status != SessionStatus.running) return;
    state = current.copyWith(status: SessionStatus.paused);
    // Timer dimatikan saat jeda: tidak ada alasan membangunkan perangkat
    // setiap detik untuk hitung mundur yang sedang berhenti.
    _stopTicker();
    _persist();
    unawaited(NotificationService.instance.cancelFinishAlert());
  }

  void resume() {
    final current = state;
    if (current == null || current.status != SessionStatus.paused) return;
    state = current.copyWith(status: SessionStatus.running);
    _startTicker();
    _persist();
    _scheduleFinishAlert(state!);
  }

  /// Menyegerakan hitung mundur dengan jam dinding.
  ///
  /// Dipanggil ketika aplikasi kembali ke depan layar, supaya ring tidak
  /// menunggu satu detik penuh sebelum angkanya benar.
  void syncNow() {
    final current = state;
    if (current == null || current.status != SessionStatus.running) return;
    _lastTick = DateTime.now();
    _tick();
  }

  /// Mengakhiri sesi lebih awal tanpa menyimpan apa pun.
  void discard() {
    _stopTicker();
    state = null;
    unawaited(_store?.clear());
    unawaited(NotificationService.instance.cancelFinishAlert());
  }

  /// Menutup sesi dan menyimpannya ke riwayat.
  Future<CleaningSession?> complete() async {
    final current = state;
    if (current == null) return null;
    _stopTicker();
    final endedAt = DateTime.now();
    final timedOut = current.remainingSeconds == 0;
    final record = current.toRecord(
      endedAt: endedAt,
      completed: timedOut && current.allTasksDone,
    );
    state = null;
    unawaited(_store?.clear());
    unawaited(NotificationService.instance.cancelFinishAlert());
    try {
      await ref.read(cleaningRepositoryProvider).saveSession(record);
    } catch (_) {
      // Riwayat yang gagal disimpan tidak boleh membatalkan ringkasan yang
      // sudah dilihat pengguna; Home akan menampilkan data terakhir.
    }
    refreshCleaningSummary(ref);
    return record;
  }

  void _startTicker() {
    _lastTick = DateTime.now();
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
    _lastTick = null;
  }

  void _tick() {
    final current = state;
    if (current == null) {
      _stopTicker();
      return;
    }
    if (current.status != SessionStatus.running) {
      _lastTick = null;
      return;
    }
    final now = DateTime.now();
    final last = _lastTick ?? now;
    _lastTick = now;
    final delta = now.difference(last).inSeconds;
    if (delta <= 0) return;
    final elapsed = current.elapsedSeconds + delta;
    if (elapsed >= current.plannedSeconds) {
      state = current.copyWith(
        elapsedSeconds: current.plannedSeconds,
        status: SessionStatus.finished,
      );
      _stopTicker();
      _persist(force: true);
      unawaited(NotificationService.instance.cancelFinishAlert());
      return;
    }
    state = current.copyWith(elapsedSeconds: elapsed);
    // Menulis setiap lima detik sudah cukup untuk memulihkan sesi setelah
    // proses dibunuh, tanpa menyentuh disk setiap detik.
    _ticksSinceSave += delta;
    if (_ticksSinceSave >= 5) _persist(force: true);
  }

  void _persist({bool force = false}) {
    final current = state;
    if (current == null) return;
    if (force) _ticksSinceSave = 0;
    final store = _store;
    if (store == null) return;
    unawaited(store.save(current));
  }

  void _scheduleFinishAlert(ActiveSession session) {
    unawaited(
      NotificationService.instance.scheduleFinishAlert(
        at: DateTime.now().add(Duration(seconds: session.remainingSeconds)),
        roomLabel: session.roomSpec.label,
      ),
    );
  }
}

final sessionControllerProvider =
    NotifierProvider<SessionController, ActiveSession?>(SessionController.new);
