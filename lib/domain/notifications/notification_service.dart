import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../data/models/cleaning_schedule.dart';

/// Kejadian pengingat berikutnya untuk jam dinding lokal.
///
/// Hari berikutnya dibangun sebagai tanggal kalender, bukan penambahan 24 jam,
/// agar pergantian waktu musiman tidak menggeser jadwal.
tz.TZDateTime nextDailyReminder({
  required tz.TZDateTime now,
  required int hour,
  required int minute,
}) {
  RangeError.checkValueInInterval(hour, 0, 23, 'hour');
  RangeError.checkValueInInterval(minute, 0, 59, 'minute');
  var next = tz.TZDateTime(
    now.location,
    now.year,
    now.month,
    now.day,
    hour,
    minute,
  );
  if (!next.isAfter(now)) {
    next = tz.TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day + 1,
      hour,
      minute,
    );
  }
  return next;
}

/// Jadwal mingguan harus mendarat pada hari yang diminta, bukan sekadar
/// "tujuh hari dari sekarang".
tz.TZDateTime nextWeeklyReminder({
  required tz.TZDateTime now,
  required int weekday,
  required int hour,
  required int minute,
}) {
  RangeError.checkValueInInterval(weekday, 1, 7, 'weekday');
  var next = tz.TZDateTime(
    now.location,
    now.year,
    now.month,
    now.day,
    hour,
    minute,
  );
  while (next.weekday != weekday || !next.isAfter(now)) {
    next = next.add(const Duration(days: 1));
  }
  return next;
}

/// Pengingat lokal pembersihan. Tidak ada server, tidak ada push.
class NotificationService {
  NotificationService();

  static final NotificationService instance = NotificationService();

  // Nama channel harus sama dengan MainActivity.kt (package id aplikasi live).
  static const _deviceTimezone = MethodChannel(
    'id.arunika.arunika_growth/device_timezone',
  );
  static const String channelId = 'cleaning_reminders';
  static const String channelName = 'Cleaning reminders';
  static const String channelDescription =
      'Optional reminders for your daily and weekly cleaning schedules';
  static const int _baseId = 4100;

  /// Id khusus untuk "timer sesi selesai". Letaknya di luar rentang
  /// [_baseId]–[_baseId + 1000) supaya tidak pernah menimpa pengingat jadwal.
  static const int _finishAlertId = 3999;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  Future<void>? _initialization;

  Future<void> init() async {
    if (_initialized) return;
    return _initialization ??= _initialize().whenComplete(() {
      _initialization = null;
    });
  }

  Future<void> _initialize() async {
    tz_data.initializeTimeZones();
    const android = AndroidInitializationSettings('ic_stat_clean');
    const settings = InitializationSettings(android: android);
    final initialized = await _plugin.initialize(settings: settings);
    if (initialized != true) {
      throw StateError('Reminders are not available on this device.');
    }
    _initialized = true;
  }

  /// Meminta izin notifikasi (Android 13+).
  Future<bool> requestPermission() async {
    await init();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final granted = await android?.requestNotificationsPermission();
    return granted == true && await hasPermission();
  }

  /// Membaca izin tanpa memicu dialog; dipakai saat layar dibuka.
  Future<bool> hasPermission() async {
    await init();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (await android?.areNotificationsEnabled() != true) return false;
    final channels = await android?.getNotificationChannels();
    return !(channels ?? <AndroidNotificationChannel>[]).any(
      (channel) =>
          channel.id == channelId && channel.importance == Importance.none,
    );
  }

  Future<void> _refreshDeviceTimezone() async {
    final name = await _deviceTimezone.invokeMethod<String>('getLocalTimezone');
    if (name == null || name.isEmpty) {
      throw StateError('The device time zone could not be read. Try again.');
    }
    tz.setLocalLocation(tz.getLocation(name));
  }

  /// Menjadwalkan satu pengingat berulang untuk [schedule].
  Future<void> scheduleReminder(CleaningSchedule schedule) async {
    await init();
    await _refreshDeviceTimezone();
    final now = tz.TZDateTime.now(tz.local);
    final weekly = schedule.cadence == ScheduleCadence.weekly;
    final next = weekly
        ? nextWeeklyReminder(
            now: now,
            weekday: schedule.weekday,
            hour: schedule.hour,
            minute: schedule.minute,
          )
        : nextDailyReminder(
            now: now,
            hour: schedule.hour,
            minute: schedule.minute,
          );

    await _plugin.zonedSchedule(
      id: notificationIdFor(schedule.id),
      title: schedule.title.isEmpty ? 'Time for a quick reset' : schedule.title,
      body: weekly
          ? '${schedule.roomSpec.label} · ${schedule.minutes} minutes. '
                'Open Cleanly when you are ready.'
          : '${schedule.minutes} minutes in the '
                '${schedule.roomSpec.label.toLowerCase()} — one tap to start.',
      scheduledDate: next,
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: weekly
          ? DateTimeComponents.dayOfWeekAndTime
          : DateTimeComponents.time,
      payload: schedule.id,
    );
  }

  /// Memberi tahu pengguna bahwa hitung mundur sesi sudah habis, walau
  /// aplikasi sedang di latar belakang.
  ///
  /// Izin tidak pernah diminta di sini: bila pengguna belum mengizinkan
  /// notifikasi, panggilan ini hanya tidak melakukan apa pun sehingga sesi
  /// tetap berjalan normal tanpa dialog tambahan di tengah pembersihan.
  Future<void> scheduleFinishAlert({
    required DateTime at,
    required String roomLabel,
  }) async {
    try {
      await init();
      if (!await hasPermission()) return;
      await _refreshDeviceTimezone();
      final earliest = DateTime.now().add(const Duration(seconds: 5));
      final when = at.isBefore(earliest) ? earliest : at;
      await _plugin.zonedSchedule(
        id: _finishAlertId,
        title: 'Time is up',
        body:
            'Your $roomLabel session is done. Open Cleanly to save it and keep '
            'your streak.',
        scheduledDate: tz.TZDateTime.from(when, tz.local),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'session-finish',
      );
    } catch (_) {
      // Notifikasi hanya bonus; kegagalannya tidak boleh menyentuh sesi.
    }
  }

  Future<void> cancelFinishAlert() async {
    try {
      await init();
      await _plugin.cancel(id: _finishAlertId);
    } catch (_) {
      // Tidak ada yang perlu dilaporkan ke pengguna.
    }
  }

  Future<void> cancelReminder(String scheduleId) async {
    await init();
    await _plugin.cancel(id: notificationIdFor(scheduleId));
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  /// Id notifikasi harus stabil antar peluncuran supaya penjadwalan ulang
  /// mengganti pengingat lama, bukan menumpuknya.
  static int notificationIdFor(String scheduleId) {
    var hash = 0;
    for (final unit in scheduleId.codeUnits) {
      hash = (hash * 31 + unit) & 0x7FFFFFFF;
    }
    return _baseId + (hash % 1000);
  }

  NotificationDetails get _details => const NotificationDetails(
    android: AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: 'ic_stat_clean',
      visibility: NotificationVisibility.private,
    ),
  );
}
