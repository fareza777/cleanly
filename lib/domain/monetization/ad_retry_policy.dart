/// Jeda muat ulang banner yang makin panjang. Kegagalan iklan tidak pernah
/// menghalangi pengguna, hanya membuat slot tetap kosong.
class AdRetryPolicy {
  AdRetryPolicy._();

  static const _delays = [
    Duration(seconds: 15),
    Duration(seconds: 30),
    Duration(minutes: 1),
    Duration(minutes: 5),
  ];

  static Duration nextDelay(int failureCount) {
    final index = failureCount.clamp(0, _delays.length - 1);
    return _delays[index];
  }
}
