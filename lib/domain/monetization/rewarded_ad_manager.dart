import 'dart:async';

import 'package:flutter/foundation.dart';

import 'ad_presentations.dart';
import 'monetization_config.dart';

enum RewardedAdResult { earned, dismissed, unavailable, canceled }

/// Setiap permintaan eksplisit hanya bisa memberi hadiah satu kali, dan hanya
/// dari callback `onUserEarnedReward`. Memuat atau menutup iklan tidak pernah
/// membuka konten.
class RewardedAdManager {
  RewardedAdManager({
    MonetizationConfig? config,
    bool? isSupported,
    Future<bool> Function()? canRequestAds,
    Future<RewardedAdPresentation> Function(String)? loadAd,
  }) : _config = config ?? MonetizationConfig.fromEnvironment(),
       _isSupported = isSupported ?? supportsMobileAds,
       _canRequestAds = canRequestAds ?? canRequestMobileAds,
       _loadAd = loadAd ?? loadRewardedAd;

  final MonetizationConfig _config;
  final bool _isSupported;
  final Future<bool> Function() _canRequestAds;
  final Future<RewardedAdPresentation> Function(String) _loadAd;
  Completer<RewardedAdResult>? _completion;
  var _disposed = false;
  var _busy = false;

  bool get isConfigured => _isSupported && _config.canUseRewarded;
  bool get isEnabled => _config.enableRewarded;
  bool get isBusy => _busy;

  Future<RewardedAdResult> show({
    required bool Function() canPresent,
    required VoidCallback onEarned,
  }) async {
    if (_disposed || _busy || !isConfigured) {
      return RewardedAdResult.unavailable;
    }
    _busy = true;
    var earned = false;
    var finished = false;
    RewardedAdPresentation? ad;
    try {
      if (!canPresent()) return RewardedAdResult.canceled;
      if (!await _canRequestAds()) return RewardedAdResult.unavailable;
      if (_disposed || !canPresent()) return RewardedAdResult.canceled;
      ad = await _loadAd(_config.rewardedAdUnitId);
      if (_disposed || !canPresent()) return RewardedAdResult.canceled;
      final completed = Completer<RewardedAdResult>();
      _completion = completed;
      void finish(RewardedAdResult result) {
        if (finished) return;
        finished = true;
        if (!completed.isCompleted) {
          completed.complete(earned ? RewardedAdResult.earned : result);
        }
      }

      await ad.show(
        onEarned: () {
          if (_disposed || earned || finished || completed.isCompleted) return;
          earned = true;
          onEarned();
        },
        onDismissed: () => finish(RewardedAdResult.dismissed),
        onFailed: () => finish(RewardedAdResult.unavailable),
      );
      return await completed.future;
    } catch (_) {
      return earned ? RewardedAdResult.earned : RewardedAdResult.unavailable;
    } finally {
      finished = true;
      _completion = null;
      _busy = false;
      await ad?.dispose();
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    final completed = _completion;
    if (completed != null && !completed.isCompleted) {
      // Blok finally milik permintaan yang berjalan yang membuang iklannya.
      completed.complete(RewardedAdResult.canceled);
    }
  }
}
