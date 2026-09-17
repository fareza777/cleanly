/// Menjaga interstitial agar tidak pernah mengganggu timer atau muncul terlalu
/// sering.
///
/// Aturan Cleanly: satu iklan penuh hanya boleh muncul setelah sesi selesai,
/// minimal pada sesi ketiga sejak iklan terakhir, dan tidak dua kali dalam
/// [cooldown] yang sama. Dengan sesi tipikal 5–30 menit, ini berarti satu
/// interstitial kira-kira setiap 20–30 menit membersihkan — cukup jarang agar
/// tidak mengganggu, cukup sering untuk pendapatan.
class InterstitialGate {
  InterstitialGate({this.sessionsPerAd = 3, this.cooldown = const Duration(minutes: 6)});

  final int sessionsPerAd;
  final Duration cooldown;

  DateTime? _lastShown;
  var _finishedSessions = 0;

  bool canShow(DateTime now) {
    if (_finishedSessions < sessionsPerAd) return false;
    final lastShown = _lastShown;
    if (lastShown == null) return true;
    return now.difference(lastShown) >= cooldown;
  }

  void recordShown(DateTime now) {
    _lastShown = now;
    _finishedSessions = 0;
  }

  /// Dipanggil setiap kali sesi pembersihan selesai — termasuk sesi yang
  /// dihentikan lebih awal, karena pengguna tetap mendapat ringkasan.
  void recordSessionFinished() {
    _finishedSessions += 1;
  }
}
