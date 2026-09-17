import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/monetization/ad_presentations.dart';
import '../domain/monetization/interstitial_ad_manager.dart';
import '../domain/monetization/interstitial_gate.dart';
import '../domain/monetization/monetization_config.dart';
import '../domain/monetization/rewarded_ad_manager.dart';

class AdsState {
  const AdsState({this.isRewardedBusy = false, this.rewardedMessage});

  final bool isRewardedBusy;
  final String? rewardedMessage;

  AdsState copyWith({
    bool? isRewardedBusy,
    String? rewardedMessage,
    bool clearMessage = false,
  }) => AdsState(
    isRewardedBusy: isRewardedBusy ?? this.isRewardedBusy,
    rewardedMessage: clearMessage ? null : rewardedMessage ?? this.rewardedMessage,
  );
}

final monetizationConfigProvider = Provider<MonetizationConfig>(
  (ref) => MonetizationConfig.fromEnvironment(),
);

/// Kedua manager menerima konfigurasi yang sama dengan UI sehingga hanya ada
/// satu sumber kebenaran: build tanpa iklan tidak pernah memanggil SDK.
final interstitialAdManagerProvider = Provider<InterstitialAdManager>(
  (ref) => InterstitialAdManager(config: ref.watch(monetizationConfigProvider)),
);

final rewardedAdManagerProvider = Provider<RewardedAdManager>(
  (ref) => RewardedAdManager(config: ref.watch(monetizationConfigProvider)),
);

final adsProvider = NotifierProvider<AdsController, AdsState>(
  AdsController.new,
);

/// Satu-satunya tempat yang boleh meminta iklan penuh.
///
/// Banner ditangani widget slotnya sendiri; interstitial hanya boleh muncul
/// setelah sesi selesai, dan rewarded hanya dari aksi eksplisit pengguna.
class AdsController extends Notifier<AdsState> {
  final interstitialGate = InterstitialGate();

  late final RewardedAdManager _rewarded;
  InterstitialAdManager? _interstitial;

  @override
  AdsState build() {
    _rewarded = ref.read(rewardedAdManagerProvider);
    ref.onDispose(() {
      unawaited(_interstitial?.dispose());
      unawaited(_rewarded.dispose());
    });
    final config = ref.read(monetizationConfigProvider);
    if (config.hasAnyAdConfiguration) {
      if (config.isUsingTestUnits) {
        debugPrint(
          'Cleanly ads: Google TEST ad units in use '
          '(banner/interstitial/rewarded). Real revenue is disabled — '
          'expected while testing.',
        );
      }
      // Consent UMP diselesaikan di dalam helper ini sebelum permintaan iklan
      // pertama; bila gagal, slot iklan tetap kosong tanpa mengganggu UI.
      unawaited(
        initializeMobileAds().then((_) {
          // Interstitial dipanaskan sejak awal supaya iklan sudah siap saat
          // sesi pertama selesai tanpa menunggu muat di tengah jalan.
          return _interstitialManager.preload();
        }),
      );
    }
    return const AdsState();
  }

  InterstitialAdManager get _interstitialManager {
    final existing = _interstitial;
    if (existing != null) return existing;
    final created = ref.read(interstitialAdManagerProvider);
    _interstitial = created;
    return created;
  }

  /// Dipanggil saat sesi dimulai supaya iklan sudah siap ketika sesi berakhir
  /// — timer tidak pernah menunggu pemuatan iklan.
  void warmUpInterstitial() {
    unawaited(_interstitialManager.preload());
  }

  /// Dipanggil sekali per sesi yang selesai, tepat setelah pengguna menutup
  /// ringkasan. Aman dipanggil walau iklan belum siap.
  Future<bool> showCompletionInterstitial({
    required bool Function() canPresent,
  }) async {
    interstitialGate.recordSessionFinished();
    return _interstitialManager.showIfEligible(
      gate: interstitialGate,
      canPresent: canPresent,
    );
  }

  /// Rewarded hanya untuk membuka tema atau preset tambahan.
  Future<RewardedAdResult> showRewardedUnlock({
    required bool Function() canPresent,
    required VoidCallback onEarned,
    required String purpose,
  }) async {
    if (state.isRewardedBusy) return RewardedAdResult.canceled;
    if (!_rewarded.isConfigured) {
      state = state.copyWith(
        rewardedMessage: 'Rewarded ads are not available on this build yet.',
      );
      return RewardedAdResult.unavailable;
    }
    state = state.copyWith(
      isRewardedBusy: true,
      rewardedMessage: 'Loading an ad to unlock $purpose…',
    );
    final result = await _rewarded.show(
      canPresent: canPresent,
      onEarned: onEarned,
    );
    if (result == RewardedAdResult.earned) {
      state = state.copyWith(
        isRewardedBusy: false,
        rewardedMessage: '$purpose unlocked. Enjoy!',
      );
      return result;
    }
    state = state.copyWith(
      isRewardedBusy: false,
      rewardedMessage: switch (result) {
        RewardedAdResult.dismissed =>
          'The ad was closed before it finished, so nothing was unlocked yet.',
        RewardedAdResult.canceled => 'Request cancelled — nothing was unlocked.',
        _ =>
          'No ad is available right now. Check your connection and try again later.',
      },
    );
    return result;
  }

  Future<void> showPrivacyOptions() async {
    await showAdPrivacyOptions();
  }
}
