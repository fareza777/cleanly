/// Konfigurasi runtime untuk AdMob.
///
/// Tidak ada pembelian dalam aplikasi pada versi ini: monetisasi sepenuhnya
/// dari banner, interstitial setelah sesi selesai, dan rewarded opsional untuk
/// membuka tema/preset tambahan.
///
/// Sumber ID:
/// - Debug profile → selalu ID uji Google, sehingga setiap build pengembangan
///   aman dari pelanggaran kebijakan klik tidak sah.
/// - Release profile → ID produksi via `--dart-define` (ADMOB_APP_ID dll).
///   Selama ID itu belum diisi, rilis OTOMATIS memakai ID uji Google supaya
///   APK uji rilis tetap menampilkan iklan; mendorong ID uji ke produksi
///   tetap dicegah oleh [isValidForRelease].
class MonetizationConfig {
  const MonetizationConfig({
    required this.admobAppId,
    required this.bannerAdUnitId,
    required this.interstitialAdUnitId,
    required this.rewardedAdUnitId,
    required this.enableRewarded,
    required this.isRelease,
  });

  static const testAdmobAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const testInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';

  final String admobAppId;
  final String bannerAdUnitId;
  final String interstitialAdUnitId;
  final String rewardedAdUnitId;
  final bool enableRewarded;
  final bool isRelease;

  factory MonetizationConfig.fromEnvironment({
    bool? isRelease,
    bool? enableRewarded,
  }) {
    final release = isRelease ?? const bool.fromEnvironment('dart.vm.product');
    // Rewarded membuka tema dan preset, jadi aktif secara default dan tetap
    // bisa dimatikan dari dart define saat pengujian.
    final rewards =
        enableRewarded ??
        const bool.fromEnvironment('ENABLE_REWARDED', defaultValue: true);
    if (!release) {
      return MonetizationConfig(
        admobAppId: testAdmobAppId,
        bannerAdUnitId: testBannerAdUnitId,
        interstitialAdUnitId: testInterstitialAdUnitId,
        rewardedAdUnitId: testRewardedAdUnitId,
        enableRewarded: rewards,
        isRelease: false,
      );
    }
    // Rilis memakai ID produksi bila tersedia; sebelum ID asli diisi lewat
    // --dart-define, jatuh ke ID uji Google agar APK uji rilis tetap memuat
    // iklan (konsisten dengan fallback Gradle untuk ADMOB_APP_ID).
    final prodAppId = const String.fromEnvironment('ADMOB_APP_ID');
    final hasProdAppId =
        prodAppId.isNotEmpty && prodAppId != testAdmobAppId;
    String productionOrTest(String prodValue, String testValue) {
      final value = prodValue.trim();
      return value.isNotEmpty && value != testValue ? value : testValue;
    }

    return MonetizationConfig(
      admobAppId: hasProdAppId ? prodAppId : testAdmobAppId,
      bannerAdUnitId: productionOrTest(
        const String.fromEnvironment('ADMOB_BANNER_ID'),
        testBannerAdUnitId,
      ),
      interstitialAdUnitId: productionOrTest(
        const String.fromEnvironment('ADMOB_INTERSTITIAL_ID'),
        testInterstitialAdUnitId,
      ),
      rewardedAdUnitId: productionOrTest(
        const String.fromEnvironment('ADMOB_REWARDED_ID'),
        testRewardedAdUnitId,
      ),
      enableRewarded: rewards,
      isRelease: true,
    );
  }

  /// Konfigurasi produksi yang sah memakai ID asli, bukan ID uji Google.
  /// Dipakai sebagai pengingat saat rilis — bukan untuk menonaktifkan iklan.
  bool get isValidForRelease {
    if (!isRelease) return true;
    return admobAppId != testAdmobAppId &&
        bannerAdUnitId != testBannerAdUnitId &&
        interstitialAdUnitId != testInterstitialAdUnitId &&
        rewardedAdUnitId != testRewardedAdUnitId;
  }

  /// True bila unit yang terpasang masih ID uji Google (termasuk fallback
  /// otomatis di rilis). Berguna untuk catatan konsol debug.
  bool get isUsingTestUnits =>
      admobAppId == testAdmobAppId ||
      bannerAdUnitId == testBannerAdUnitId ||
      interstitialAdUnitId == testInterstitialAdUnitId ||
      rewardedAdUnitId == testRewardedAdUnitId;

  bool get canUseBanner => _hasAppId && _hasUnitId(bannerAdUnitId);
  bool get canUseInterstitial => _hasAppId && _hasUnitId(interstitialAdUnitId);
  bool get canUseRewarded =>
      enableRewarded && _hasAppId && _hasUnitId(rewardedAdUnitId);
  bool get hasAnyAdConfiguration =>
      canUseBanner || canUseInterstitial || canUseRewarded;

  bool get _hasAppId => admobAppId.trim().isNotEmpty;

  bool _hasUnitId(String id) => id.trim().isNotEmpty;
}
