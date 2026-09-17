import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_colors.dart';
import '../domain/catalog/cleaning_catalog.dart';

/// Preferensi yang tersimpan di perangkat. Semuanya lokal sehingga aplikasi
/// tetap berfungsi penuh tanpa internet.
class AppSettings {
  const AppSettings({
    this.onboardingDone = false,
    this.darkMode = false,
    this.reducedMotion = false,
    this.skin = ThemeSkin.defaultSkin,
    this.unlockedSkins = const <ThemeSkin>[],
    this.deepPresetUnlocked = false,
    this.remindersEnabled = false,
    this.lastRoom,
    this.lastMinutes = 10,
  });

  final bool onboardingDone;
  final bool darkMode;
  final bool reducedMotion;
  final ThemeSkin skin;

  /// Tema yang sudah dibuka lewat rewarded ad.
  final List<ThemeSkin> unlockedSkins;
  final bool deepPresetUnlocked;
  final bool remindersEnabled;

  /// Pilihan terakhir dipakai sebagai nilai awal agar sesi berikutnya bisa
  /// dimulai dengan satu ketukan.
  final String? lastRoom;
  final int lastMinutes;

  bool isSkinUnlocked(ThemeSkin value) =>
      !value.rewardedOnly || unlockedSkins.contains(value);

  AppSettings copyWith({
    bool? onboardingDone,
    bool? darkMode,
    bool? reducedMotion,
    ThemeSkin? skin,
    List<ThemeSkin>? unlockedSkins,
    bool? deepPresetUnlocked,
    bool? remindersEnabled,
    String? lastRoom,
    int? lastMinutes,
  }) {
    return AppSettings(
      onboardingDone: onboardingDone ?? this.onboardingDone,
      darkMode: darkMode ?? this.darkMode,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      skin: skin ?? this.skin,
      unlockedSkins: unlockedSkins ?? this.unlockedSkins,
      deepPresetUnlocked: deepPresetUnlocked ?? this.deepPresetUnlocked,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      lastRoom: lastRoom ?? this.lastRoom,
      lastMinutes: lastMinutes ?? this.lastMinutes,
    );
  }
}

final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPrefsProvider belum di-override'),
);

class SettingsNotifier extends Notifier<AppSettings> {
  /// Semua kunci diberi awalan `cleanly.`.
  ///
  /// Aplikasi ini di-update di atas aplikasi sebelumnya yang memakai package
  /// id yang sama, dan SharedPreferences disimpan per package id — jadi kunci
  /// tanpa awalan seperti `dark_mode` akan terbaca dari aplikasi lama dan
  /// membuat pengaturan warisan tanpa disengaja.
  static const String _prefix = 'cleanly.';
  static const _kOnboarding = '${_prefix}onboarding_done';
  static const _kDarkMode = '${_prefix}dark_mode';
  static const _kReducedMotion = '${_prefix}reduced_motion';
  static const _kSkin = '${_prefix}theme_skin';
  static const _kUnlockedSkins = '${_prefix}unlocked_skins';
  static const _kDeepPreset = '${_prefix}deep_preset_unlocked';
  static const _kReminders = '${_prefix}reminders_enabled';
  static const _kLastRoom = '${_prefix}last_room';
  static const _kLastMinutes = '${_prefix}last_minutes';

  /// Kunci versi aplikasi sebelumnya untuk preferensi tampilan. Nilainya tetap
  /// dihormati sekali agar pengguna lama tidak kehilangan mode gelapnya, lalu
  /// disalin ke kunci baru.
  static const _legacyDarkMode = 'dark_mode';
  static const _legacyReducedMotion = 'reduced_motion';

  SharedPreferences get _prefs => ref.read(sharedPrefsProvider);

  @override
  AppSettings build() {
    final minutes = _prefs.getInt(_kLastMinutes) ?? 10;
    return AppSettings(
      // Onboarding sengaja tidak diwarisi: aplikasinya sudah berganti wajah,
      // jadi pengguna lama pun pantas melihat pengantarnya sekali.
      onboardingDone: _prefs.getBool(_kOnboarding) ?? false,
      darkMode: _inheritedBool(_kDarkMode, _legacyDarkMode),
      reducedMotion: _inheritedBool(_kReducedMotion, _legacyReducedMotion),
      skin: ThemeSkin.fromName(_prefs.getString(_kSkin)),
      unlockedSkins: [
        for (final name in _prefs.getStringList(_kUnlockedSkins) ?? const [])
          if (ThemeSkin.values.any((skin) => skin.name == name))
            ThemeSkin.fromName(name),
      ],
      deepPresetUnlocked: _prefs.getBool(_kDeepPreset) ?? false,
      remindersEnabled: _prefs.getBool(_kReminders) ?? false,
      lastRoom: _normalizedRoom(_prefs.getString(_kLastRoom)),
      lastMinutes: minutes >= 1 && minutes <= 60 ? minutes : 10,
    );
  }

  /// Membaca kunci baru; bila belum ada, nilai dari versi sebelumnya dipakai
  /// sekali dan disalin ke kunci baru di latar belakang.
  bool _inheritedBool(String key, String legacyKey) {
    final current = _prefs.getBool(key);
    if (current != null) return current;
    final legacy = _prefs.getBool(legacyKey);
    if (legacy == null) return false;
    unawaited(_prefs.setBool(key, legacy));
    return legacy;
  }

  String? _normalizedRoom(String? name) {
    if (name == null) return null;
    for (final room in CleaningRoom.values) {
      if (room.name == name) return room.name;
    }
    return null;
  }

  Future<void> update(AppSettings next) async {
    RangeError.checkValueInInterval(next.lastMinutes, 1, 60, 'lastMinutes');
    final values = <String, Object>{
      _kOnboarding: next.onboardingDone,
      _kDarkMode: next.darkMode,
      _kReducedMotion: next.reducedMotion,
      _kSkin: next.skin.name,
      _kDeepPreset: next.deepPresetUnlocked,
      _kReminders: next.remindersEnabled,
      _kLastMinutes: next.lastMinutes,
      _kUnlockedSkins: [for (final skin in next.unlockedSkins) skin.name],
    };
    final previous = <String, Object?>{};
    try {
      for (final entry in values.entries) {
        if (_prefs.get(entry.key) == entry.value) continue;
        previous[entry.key] = _prefs.get(entry.key);
        await _write(entry.key, entry.value);
      }
      if (next.lastRoom != null && _prefs.getString(_kLastRoom) != next.lastRoom) {
        previous[_kLastRoom] = _prefs.getString(_kLastRoom);
        await _write(_kLastRoom, next.lastRoom!);
      }
    } catch (_) {
      // Perubahan preferensi tidak boleh dianggap berhasil sebelum perangkat
      // mengonfirmasi penyimpanannya; kembalikan ke nilai sebelumnya.
      for (final entry in previous.entries.toList().reversed) {
        try {
          await _write(entry.key, entry.value);
        } catch (_) {
          // Kegagalan asli tetap diteruskan ke pemanggil.
        }
      }
      rethrow;
    }
    state = next;
  }

  Future<void> _write(String key, Object? value) async {
    final saved = await switch (value) {
      bool value => _prefs.setBool(key, value),
      int value => _prefs.setInt(key, value),
      String value => _prefs.setString(key, value),
      List<String> value => _prefs.setStringList(key, value),
      null => _prefs.remove(key),
      _ => throw ArgumentError.value(value, key),
    };
    if (!saved) throw StateError('Settings could not be saved.');
  }

  Future<void> completeOnboarding() =>
      update(state.copyWith(onboardingDone: true));

  Future<void> unlockSkin(ThemeSkin skin) async {
    if (state.isSkinUnlocked(skin)) return;
    await update(
      state.copyWith(
        unlockedSkins: [...state.unlockedSkins, skin],
        skin: skin,
      ),
    );
  }

  Future<void> unlockDeepPreset() async {
    if (state.deepPresetUnlocked) return;
    await update(state.copyWith(deepPresetUnlocked: true));
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

/// Dipakai memastikan nama ruangan pada preferensi dikenal aplikasi.
CleaningRoom? roomFromSettings(String? name) {
  if (name == null) return null;
  for (final room in CleaningRoom.values) {
    if (room.name == name) return room;
  }
  return null;
}
