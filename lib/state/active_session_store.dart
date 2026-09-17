import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'session_controller.dart';

/// Sesi tersimpan beserta kapan terakhir kali disimpan.
///
/// Stempel waktu itu penting: selisih antara "disimpan" dan "dibuka lagi"
/// adalah waktu yang benar-benar berjalan sementara aplikasi tidak aktif.
class PersistedSession {
  const PersistedSession({required this.session, required this.savedAt});

  final ActiveSession session;
  final DateTime savedAt;
}

/// Menyimpan sesi yang sedang berjalan di penyimpanan lokal.
///
/// Android boleh membunuh proses kapan saja saat aplikasi berada di latar
/// belakang. Tanpa simpanan ini, hitung mundur yang sudah berjalan beberapa
/// menit akan hilang begitu saja. Isinya kecil — satu baris JSON.
class ActiveSessionStore {
  const ActiveSessionStore(this._prefs);

  /// Kunci diberi awalan `cleanly.` supaya tidak bertabrakan dengan
  /// preferensi aplikasi sebelumnya yang memakai package id yang sama.
  static const String key = 'cleanly.active_session';

  final SharedPreferences _prefs;

  Future<void> save(ActiveSession session) async {
    try {
      await _prefs.setString(
        key,
        jsonEncode(session.toJson(savedAt: DateTime.now())),
      );
    } catch (_) {
      // Sesi tetap berjalan di memori walau simpanan gagal.
    }
  }

  Future<void> clear() async {
    try {
      await _prefs.remove(key);
    } catch (_) {
      // Tidak ada yang bisa dilakukan; sesi di memori tetap benar.
    }
  }

  /// Mengembalikan sesi tersimpan, atau `null` bila kosong/rusak.
  PersistedSession? load() {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw) as Map<String, Object?>;
      final session = ActiveSession.fromJson(json);
      final savedAt = DateTime.fromMillisecondsSinceEpoch(
        (json['saved_at'] as num?)?.toInt() ??
            session.startedAt.millisecondsSinceEpoch,
      );
      return PersistedSession(session: session, savedAt: savedAt);
    } catch (_) {
      clear();
      return null;
    }
  }
}
