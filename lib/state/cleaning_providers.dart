import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/models/cleaning_schedule.dart';
import '../data/models/cleaning_session.dart';
import '../data/models/custom_routine.dart';
import '../data/repo/cleaning_repository.dart';
import '../domain/catalog/cleaning_catalog.dart';
import 'app_settings.dart';

final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => AppDatabase.instance,
);

final cleaningRepositoryProvider = Provider<CleaningRepository>(
  (ref) => CleaningRepository(ref.watch(appDatabaseProvider)),
);

final statsProvider = FutureProvider<CleaningStats>(
  (ref) => ref.watch(cleaningRepositoryProvider).stats(),
);

final recentSessionsProvider = FutureProvider<List<CleaningSession>>(
  (ref) => ref.watch(cleaningRepositoryProvider).recentSessions(),
);

final routinesProvider = FutureProvider<List<CustomRoutine>>(
  (ref) => ref.watch(cleaningRepositoryProvider).listRoutines(),
);

final schedulesProvider = FutureProvider<List<CleaningSchedule>>(
  (ref) => ref.watch(cleaningRepositoryProvider).listSchedules(),
);

/// Rutinitas yang dipasang sebagai aksi cepat di Home, bila ada.
final homeRoutineProvider = Provider<CustomRoutine?>((ref) {
  final routines = ref.watch(routinesProvider).valueOrNull ?? const [];
  for (final routine in routines) {
    if (routine.isAtHome) return routine;
  }
  return null;
});

/// Menyegarkan ringkasan setelah sesi tersimpan.
void refreshCleaningSummary(Ref ref) {
  ref.invalidate(statsProvider);
  ref.invalidate(recentSessionsProvider);
}

/// Pilihan di Home sebelum sesi dimulai.
class SessionDraft {
  const SessionDraft({required this.minutes, this.room, this.deepPreset = false});

  final int minutes;
  final CleaningRoom? room;

  /// Preset 45 menit yang dibuka lewat rewarded ad.
  final bool deepPreset;

  bool get canStart => room != null;

  /// Perkiraan waktu daftar yang akan dijalankan, dipakai untuk label
  /// "runs about N min".
  int get plannedSeconds => CleaningCatalog.totalSeconds(plannedTasks);

  List<CleaningTaskSpec> get plannedTasks {
    final selected = room;
    if (selected == null) return const [];
    if (deepPreset) return CleaningCatalog.deepPreset(selected);
    return CleaningCatalog.selectFor(selected, minutes: minutes);
  }

  SessionDraft copyWith({
    int? minutes,
    CleaningRoom? room,
    bool? deepPreset,
  }) => SessionDraft(
    minutes: minutes ?? this.minutes,
    room: room ?? this.room,
    deepPreset: deepPreset ?? this.deepPreset,
  );
}

class SessionDraftNotifier extends Notifier<SessionDraft> {
  @override
  SessionDraft build() {
    final settings = ref.read(settingsProvider);
    return SessionDraft(
      minutes: settings.lastMinutes,
      room: roomFromSettings(settings.lastRoom),
    );
  }

  void selectMinutes(int minutes) {
    RangeError.checkValueInInterval(minutes, 1, 60, 'minutes');
    state = state.copyWith(minutes: minutes);
    _remember(minutes: minutes);
  }

  void selectRoom(CleaningRoom room) {
    state = state.copyWith(room: room);
    _remember(room: room);
  }

  /// Mengaktifkan preset 45 menit; hanya dipakai bila sudah dibuka.
  void useDeepPreset({required bool unlocked}) {
    if (!unlocked) return;
    state = SessionDraft(
      minutes: CleaningCatalog.deepPresetMinutes,
      room: state.room,
      deepPreset: true,
    );
  }

  void clearDeepPreset() {
    state = SessionDraft(minutes: state.minutes, room: state.room);
  }

  /// Pilihan terakhir bersifat best-effort: kegagalan menyimpan preferensi
  /// tidak boleh menghalangi pengguna memulai sesi dari Home.
  void _remember({int? minutes, CleaningRoom? room}) {
    unawaited(() async {
      final settings = ref.read(settingsProvider);
      try {
        await ref
            .read(settingsProvider.notifier)
            .update(
              settings.copyWith(
                lastMinutes: minutes ?? settings.lastMinutes,
                lastRoom: room?.name ?? settings.lastRoom,
              ),
            );
      } catch (_) {
        // Diabaikan dengan sengaja; layar Pengaturan yang melaporkan error.
      }
    }());
  }
}

final sessionDraftProvider = NotifierProvider<SessionDraftNotifier, SessionDraft>(
  SessionDraftNotifier.new,
);
