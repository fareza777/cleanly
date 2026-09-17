import 'package:cleanly/domain/monetization/interstitial_gate.dart';
import 'package:cleanly/domain/monetization/monetization_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MonetizationConfig', () {
    test('debug builds always use Google test ad units', () {
      final config = MonetizationConfig.fromEnvironment(isRelease: false);
      expect(config.admobAppId, MonetizationConfig.testAdmobAppId);
      expect(config.bannerAdUnitId, MonetizationConfig.testBannerAdUnitId);
      expect(
        config.interstitialAdUnitId,
        MonetizationConfig.testInterstitialAdUnitId,
      );
      expect(config.rewardedAdUnitId, MonetizationConfig.testRewardedAdUnitId);
      expect(config.isUsingTestUnits, isTrue);
      // Test units are valid to ship in a debug/testing build.
      expect(config.canUseBanner, isTrue);
      expect(config.canUseInterstitial, isTrue);
      expect(config.canUseRewarded, isTrue);
    });

    test('release build without dart-defines falls back to test units', () {
      // The `flutter test` runner compiles without ADMOB_* defines, so this
      // exercises the same path as a release APK built before real IDs exist.
      final config = MonetizationConfig.fromEnvironment(isRelease: true);
      expect(config.admobAppId, MonetizationConfig.testAdmobAppId);
      expect(config.bannerAdUnitId, MonetizationConfig.testBannerAdUnitId);
      expect(config.isUsingTestUnits, isTrue);
      expect(config.isValidForRelease, isFalse,
          reason: 'Shipping test units to production must be flagged.');
      // Ads still work in the fallback build instead of being disabled.
      expect(config.canUseBanner, isTrue);
      expect(config.canUseInterstitial, isTrue);
      expect(config.canUseRewarded, isTrue);
    });

    test('real production units pass the release validation', () {
      const config = MonetizationConfig(
        admobAppId: 'ca-app-pub-1234567890123456~1234567890',
        bannerAdUnitId: 'ca-app-pub-1234567890123456/1111111111',
        interstitialAdUnitId: 'ca-app-pub-1234567890123456/2222222222',
        rewardedAdUnitId: 'ca-app-pub-1234567890123456/3333333333',
        enableRewarded: true,
        isRelease: true,
      );
      expect(config.isUsingTestUnits, isFalse);
      expect(config.isValidForRelease, isTrue);
    });

    test('a single leaked test unit fails release validation', () {
      const config = MonetizationConfig(
        admobAppId: 'ca-app-pub-1234567890123456~1234567890',
        bannerAdUnitId: 'ca-app-pub-1234567890123456/1111111111',
        interstitialAdUnitId: MonetizationConfig.testInterstitialAdUnitId,
        rewardedAdUnitId: 'ca-app-pub-1234567890123456/3333333333',
        enableRewarded: true,
        isRelease: true,
      );
      expect(config.isUsingTestUnits, isTrue);
      expect(config.isValidForRelease, isFalse);
    });
  });

  group('InterstitialGate', () {
    test('blocks until the required number of sessions finished', () {
      final gate = InterstitialGate();
      final now = DateTime(2026, 9, 17, 9);
      expect(gate.canShow(now), isFalse);
      gate.recordSessionFinished();
      expect(gate.canShow(now), isFalse);
      gate.recordSessionFinished();
      expect(gate.canShow(now), isFalse,
          reason: 'default cadence is every third session');
      gate.recordSessionFinished();
      expect(gate.canShow(now), isTrue);
    });

    test('cooldown blocks a second ad even after more sessions', () {
      final gate = InterstitialGate();
      var now = DateTime(2026, 9, 17, 9);
      for (var i = 0; i < 3; i++) {
        gate.recordSessionFinished();
      }
      expect(gate.canShow(now), isTrue);
      gate.recordShown(now);

      now = now.add(const Duration(minutes: 3));
      for (var i = 0; i < 3; i++) {
        gate.recordSessionFinished();
      }
      expect(gate.canShow(now), isFalse, reason: 'still inside the cooldown');

      now = now.add(const Duration(minutes: 4));
      expect(gate.canShow(now), isTrue, reason: 'cooldown is six minutes');
    });

    test('recordShown resets the finished-session counter', () {
      final gate = InterstitialGate();
      final now = DateTime(2026, 9, 17, 9);
      for (var i = 0; i < 3; i++) {
        gate.recordSessionFinished();
      }
      gate.recordShown(now);
      expect(gate.canShow(now), isFalse);
    });
  });
}
