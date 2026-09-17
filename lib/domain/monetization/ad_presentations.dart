import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Batas tipis ke SDK iklan: seluruh keputusan hadiah dan navigasi tetap
/// berada di kode aplikasi, bukan di dalam callback Google.
abstract interface class RewardedAdPresentation {
  Future<void> show({
    required VoidCallback onEarned,
    required VoidCallback onDismissed,
    required VoidCallback onFailed,
  });
  Future<void> dispose();
}

abstract interface class InterstitialAdPresentation {
  Future<void> show({
    required VoidCallback onShown,
    required VoidCallback onDismissed,
    required VoidCallback onFailed,
  });
  Future<void> dispose();
}

bool get supportsMobileAds =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// Iklan hanya boleh diminta setelah consent UMP selesai. Kegagalan apa pun
/// berarti "jangan minta iklan", bukan "minta saja".
Future<bool> canRequestMobileAds() async {
  try {
    return await ConsentInformation.instance.canRequestAds().timeout(
      const Duration(seconds: 8),
    );
  } catch (_) {
    return false;
  }
}

Future<RewardedAdPresentation> loadRewardedAd(String unitId) async {
  final completed = Completer<RewardedAdPresentation>();
  var expired = false;
  try {
    unawaited(
      RewardedAd.load(
        adUnitId: unitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            if (expired || completed.isCompleted) {
              unawaited(ad.dispose());
            } else {
              completed.complete(_GoogleRewardedAd(ad));
            }
          },
          onAdFailedToLoad: (error) {
            if (!expired && !completed.isCompleted) {
              completed.completeError(error);
            }
          },
        ),
      ).catchError((Object error) {
        if (!expired && !completed.isCompleted) completed.completeError(error);
      }),
    );
    return await completed.future.timeout(const Duration(seconds: 15));
  } finally {
    expired = true;
  }
}

Future<InterstitialAdPresentation> loadInterstitialAd(String unitId) async {
  final completed = Completer<InterstitialAdPresentation>();
  var expired = false;
  try {
    unawaited(
      InterstitialAd.load(
        adUnitId: unitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            if (expired || completed.isCompleted) {
              unawaited(ad.dispose());
            } else {
              completed.complete(_GoogleInterstitialAd(ad));
            }
          },
          onAdFailedToLoad: (error) {
            if (!expired && !completed.isCompleted) {
              completed.completeError(error);
            }
          },
        ),
      ).catchError((Object error) {
        if (!expired && !completed.isCompleted) completed.completeError(error);
      }),
    );
    return await completed.future.timeout(const Duration(seconds: 15));
  } finally {
    expired = true;
  }
}

/// Consent UMP harus selesai sebelum permintaan iklan pertama. Bila layanan
/// consent tidak tersedia, slot iklan tetap ada tetapi tidak ada permintaan.
Future<bool> prepareMobileAdsConsent() async {
  final information = ConsentInformation.instance;
  final completed = Completer<void>();

  void finish() {
    if (!completed.isCompleted) completed.complete();
  }

  try {
    information.requestConsentInfoUpdate(
      ConsentRequestParameters(tagForUnderAgeOfConsent: false),
      () => unawaited(_showConsentFormIfRequired(finish)),
      (error) {
        debugPrint('Cleanly consent update: ${error.message}');
        finish();
      },
    );
    await completed.future.timeout(const Duration(seconds: 8));
  } catch (error) {
    debugPrint('Cleanly consent unavailable: $error');
    finish();
  }

  try {
    return await information.canRequestAds();
  } catch (error) {
    debugPrint('Cleanly consent status unavailable: $error');
    return false;
  }
}

Future<void> _showConsentFormIfRequired(void Function() onFinished) async {
  try {
    await ConsentForm.loadAndShowConsentFormIfRequired((error) {
      if (error != null) {
        debugPrint('Cleanly consent form: ${error.message}');
      }
    });
  } finally {
    onFinished();
  }
}

/// Inisialisasi SDK iklan satu kali. Aman dipanggil berkali-kali.
Future<void> initializeMobileAds() async {
  if (!supportsMobileAds) return;
  try {
    if (!await prepareMobileAdsConsent()) return;
    await MobileAds.instance.initialize();
  } catch (error) {
    debugPrint('Cleanly ads unavailable: $error');
  }
}

Future<void> showAdPrivacyOptions() async {
  final completed = Completer<FormError?>();
  try {
    await ConsentForm.showPrivacyOptionsForm((error) {
      if (!completed.isCompleted) completed.complete(error);
    });
    final error = await completed.future.timeout(const Duration(seconds: 8));
    if (error != null) throw StateError(error.message);
  } catch (error) {
    if (error is StateError) rethrow;
    throw StateError('Privacy options are not available right now.');
  }
}

class _GoogleRewardedAd implements RewardedAdPresentation {
  _GoogleRewardedAd(this._ad);
  final RewardedAd _ad;
  var _disposed = false;

  @override
  Future<void> show({
    required VoidCallback onEarned,
    required VoidCallback onDismissed,
    required VoidCallback onFailed,
  }) {
    _ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdDismissedFullScreenContent: (_) => onDismissed(),
      onAdFailedToShowFullScreenContent: (_, _) => onFailed(),
    );
    return _ad.show(onUserEarnedReward: (_, _) => onEarned());
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _ad.dispose();
  }
}

class _GoogleInterstitialAd implements InterstitialAdPresentation {
  _GoogleInterstitialAd(this._ad);
  final InterstitialAd _ad;
  var _disposed = false;

  @override
  Future<void> show({
    required VoidCallback onShown,
    required VoidCallback onDismissed,
    required VoidCallback onFailed,
  }) {
    _ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdShowedFullScreenContent: (_) => onShown(),
      onAdDismissedFullScreenContent: (_) => onDismissed(),
      onAdFailedToShowFullScreenContent: (_, _) => onFailed(),
    );
    return _ad.show();
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _ad.dispose();
  }
}
