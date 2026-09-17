import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/models/cleaning_schedule.dart';
import '../domain/catalog/cleaning_catalog.dart';
import '../domain/notifications/notification_service.dart';
import 'app_settings.dart';
import 'cleaning_providers.dart';

/// Hasil aksi pengingat, dipetakan ke pesan oleh UI.
enum ReminderResult {
  scheduled,
  savedWithoutPermission,
  disabled,
  removed,
  failed,
}

class ReminderController extends Notifier<ReminderResult?> {
  static const _uuid = Uuid();

  @override
  ReminderResult? build() => null;

  /// Jadwal default yang dipakai saat pengingat baru dibuat.
  CleaningSchedule draftSchedule({CleaningSchedule? initial}) {
    return initial ??
        CleaningSchedule(
          id: _uuid.v4(),
          title: 'Time for a quick reset',
          room: CleaningRoom.wholeHome,
          minutes: 10,
          cadence: ScheduleCadence.daily,
          weekday: DateTime.saturday,
          hour: 9,
          minute: 0,
          enabled: true,
        );
  }

  /// Menyimpan jadwal lalu menjadwalkan notifikasinya.
  ///
  /// Jadwal tetap tersimpan walau izin notifikasi ditolak supaya pengguna
  /// tidak kehilangan pengaturannya.
  Future<ReminderResult> saveSchedule(CleaningSchedule schedule) async {
    final repo = ref.read(cleaningRepositoryProvider);
    try {
      await repo.saveSchedule(schedule);
      ref.invalidate(schedulesProvider);
      if (!schedule.enabled) {
        await NotificationService.instance.cancelReminder(schedule.id);
        await _rememberEnabledFlag();
        state = ReminderResult.disabled;
        return ReminderResult.disabled;
      }

      final notifications = NotificationService.instance;
      final granted = await notifications.hasPermission() ||
          await notifications.requestPermission();
      if (!granted) {
        state = ReminderResult.savedWithoutPermission;
        return ReminderResult.savedWithoutPermission;
      }
      await notifications.scheduleReminder(schedule);
      await _rememberEnabledFlag();
      state = ReminderResult.scheduled;
      return ReminderResult.scheduled;
    } catch (_) {
      state = ReminderResult.failed;
      return ReminderResult.failed;
    }
  }

  /// Menyalakan kembali notifikasi untuk jadwal yang sudah aktif.
  ///
  /// Dipakai sakelar "Reminders on": jadwalnya sudah tersimpan, jadi yang
  /// perlu dilakukan hanyalah meminta izin sekali lalu memasang ulang alarm.
  Future<ReminderResult> enableAll() async {
    try {
      final schedules = await ref
          .read(cleaningRepositoryProvider)
          .listSchedules();
      final enabled = [
        for (final schedule in schedules)
          if (schedule.enabled) schedule,
      ];
      if (enabled.isEmpty) {
        state = ReminderResult.disabled;
        return ReminderResult.disabled;
      }
      final notifications = NotificationService.instance;
      final granted =
          await notifications.hasPermission() ||
          await notifications.requestPermission();
      if (!granted) {
        state = ReminderResult.savedWithoutPermission;
        return ReminderResult.savedWithoutPermission;
      }
      for (final schedule in enabled) {
        await notifications.scheduleReminder(schedule);
      }
      await _rememberEnabledFlag();
      state = ReminderResult.scheduled;
      return ReminderResult.scheduled;
    } catch (_) {
      state = ReminderResult.failed;
      return ReminderResult.failed;
    }
  }

  /// Memasang ulang alarm untuk semua jadwal aktif tanpa meminta izin.
  ///
  /// Dipanggil sekali saat aplikasi dibuka; kegagalannya tidak pernah
  /// ditampilkan karena tidak ada yang bisa dilakukan pengguna.
  Future<void> resyncAll() async {
    try {
      final schedules = await ref
          .read(cleaningRepositoryProvider)
          .listSchedules();
      final enabled = [
        for (final schedule in schedules)
          if (schedule.enabled) schedule,
      ];
      if (enabled.isEmpty) return;
      final notifications = NotificationService.instance;
      if (!await notifications.hasPermission()) return;
      for (final schedule in enabled) {
        await notifications.scheduleReminder(schedule);
      }
    } catch (_) {
      // Best effort: pengingat hanya nilai tambah, bukan alur utama.
    }
  }

  Future<ReminderResult> deleteSchedule(String id) async {
    try {
      await ref.read(cleaningRepositoryProvider).deleteSchedule(id);
      ref.invalidate(schedulesProvider);
      await NotificationService.instance.cancelReminder(id);
      await _rememberEnabledFlag();
      state = ReminderResult.removed;
      return ReminderResult.removed;
    } catch (_) {
      state = ReminderResult.failed;
      return ReminderResult.failed;
    }
  }

  /// Membatalkan semua pengingat ketika pengguna mematikan sakelar utama.
  Future<ReminderResult> disableAll() async {
    try {
      await NotificationService.instance.cancelAll();
      final settings = ref.read(settingsProvider);
      await ref
          .read(settingsProvider.notifier)
          .update(settings.copyWith(remindersEnabled: false));
      state = ReminderResult.disabled;
      return ReminderResult.disabled;
    } catch (_) {
      state = ReminderResult.failed;
      return ReminderResult.failed;
    }
  }

  Future<void> _rememberEnabledFlag() async {
    final schedules = await ref.read(cleaningRepositoryProvider).listSchedules();
    final anyEnabled = schedules.any((schedule) => schedule.enabled);
    final settings = ref.read(settingsProvider);
    if (settings.remindersEnabled == anyEnabled) return;
    try {
      await ref
          .read(settingsProvider.notifier)
          .update(settings.copyWith(remindersEnabled: anyEnabled));
    } catch (_) {
      // Sakelar utama hanya penanda tampilan; jadwal tetap tersimpan.
    }
  }

  String messageFor(ReminderResult result) => switch (result) {
    ReminderResult.scheduled => 'Reminder set.',
    ReminderResult.savedWithoutPermission =>
      'Schedule saved, but notifications are off for Cleanly in system settings.',
    ReminderResult.disabled => 'Reminder turned off.',
    ReminderResult.removed => 'Schedule deleted.',
    ReminderResult.failed => 'That did not save on this device. Try again.',
  };
}

final reminderControllerProvider =
    NotifierProvider<ReminderController, ReminderResult?>(
      ReminderController.new,
    );
