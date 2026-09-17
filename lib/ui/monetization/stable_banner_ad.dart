import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/monetization/ad_presentations.dart';
import '../../domain/monetization/ad_retry_policy.dart';
import '../../domain/monetization/monetization_config.dart';
import '../../state/ads_provider.dart';

enum BannerPlacement { home, history }

/// Slot banner berukuran tetap: tinggi tidak berubah sambil iklan dimuat,
/// sehingga daftar di atasnya tidak pernah melompat.
class StableBannerSlot extends StatelessWidget {
  const StableBannerSlot({
    super.key,
    required this.placement,
    this.height = defaultHeight,
    this.adWidget,
    this.hasError = false,
  });

  static const defaultHeight = 54.0;

  final BannerPlacement placement;
  final double height;
  final Widget? adWidget;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final colors = context.cleanly;
    return Semantics(
      label: hasError ? 'Advert unavailable' : 'Advert',
      container: true,
      child: SizedBox(
        key: ValueKey('banner-slot:${placement.name}'),
        width: double.infinity,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(top: BorderSide(color: colors.hairline)),
          ),
          child: adWidget == null
              ? const SizedBox.expand()
              : Center(child: adWidget),
        ),
      ),
    );
  }
}

/// Satu banner adaptif yang bertahan sepanjang siklus hidup shell.
class StableBannerAd extends ConsumerStatefulWidget {
  const StableBannerAd({super.key, required this.placement});

  final BannerPlacement placement;

  @override
  ConsumerState<StableBannerAd> createState() => _StableBannerAdState();
}

class _StableBannerAdState extends ConsumerState<StableBannerAd> {
  /// Konfigurasi dibaca dari provider, bukan langsung dari environment, agar
  /// ada satu sumber kebenaran dan build tanpa iklan tetap tanpa permintaan
  /// ke SDK.
  MonetizationConfig get _config => ref.read(monetizationConfigProvider);

  BannerAd? _ad;
  Timer? _retryTimer;
  var _failureCount = 0;
  var _loading = false;
  var _hasError = false;
  var _adLoaded = false;
  var _generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    // Slot tetap dirender walau iklan gagal: tidak ada lompatan tata letak.
    if (!_config.canUseBanner) return const SizedBox.shrink();
    final ad = _ad;
    return StableBannerSlot(
      placement: widget.placement,
      height: StableBannerSlot.defaultHeight,
      hasError: _hasError,
      adWidget: ad == null || !_adLoaded ? null : AdWidget(ad: ad),
    );
  }

  Future<void> _load() async {
    if (!mounted || _loading || _ad != null) return;

    final mobile =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    if (kIsWeb || !mobile || !_config.canUseBanner) {
      if (mounted) setState(() => _hasError = true);
      return;
    }

    _loading = true;
    final generation = ++_generation;
    if (mounted) setState(() => _hasError = false);

    try {
      if (!await canRequestMobileAds()) {
        _failLoad(generation);
        return;
      }
      // Ukuran 320x50 menjaga strip banner tetap tipis di seluruh perangkat.
      const size = AdSize.banner;
      if (!_isCurrent(generation)) return;

      final ad = BannerAd(
        size: size,
        adUnitId: _config.bannerAdUnitId,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (loaded) {
            if (!_isCurrent(generation)) {
              loaded.dispose();
              return;
            }
            setState(() {
              _ad = loaded as BannerAd;
              _adLoaded = true;
              _loading = false;
              _hasError = false;
              _failureCount = 0;
            });
          },
          onAdFailedToLoad: (failed, _) {
            failed.dispose();
            if (!_isCurrent(generation)) return;
            setState(() {
              _ad = null;
              _loading = false;
              _hasError = true;
              _adLoaded = false;
              _failureCount++;
            });
            _scheduleRetry();
          },
        ),
      );
      _ad = ad;
      await ad.load();
    } catch (_) {
      if (!_isCurrent(generation)) return;
      _ad?.dispose();
      _ad = null;
      _adLoaded = false;
      setState(() {
        _loading = false;
        _hasError = true;
        _failureCount++;
      });
      _scheduleRetry();
    }
  }

  bool _isCurrent(int generation) => mounted && generation == _generation;

  void _failLoad(int generation) {
    if (!_isCurrent(generation)) return;
    setState(() {
      _loading = false;
      _hasError = true;
      _failureCount++;
    });
    _scheduleRetry();
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(AdRetryPolicy.nextDelay(_failureCount - 1), () {
      if (!mounted) return;
      _ad = null;
      unawaited(_load());
    });
  }

  void _disposeAd() {
    _generation++;
    _retryTimer?.cancel();
    _retryTimer = null;
    _ad?.dispose();
    _ad = null;
    _adLoaded = false;
    _loading = false;
  }

  @override
  void dispose() {
    _disposeAd();
    super.dispose();
  }
}
