import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'state/ads_provider.dart';
import 'state/app_settings.dart';
import 'ui/splash/splash_screen.dart';

/// Identitas aplikasi. Ubah di sini untuk rebrand.
class AppIdentity {
  AppIdentity._();
  static const String name = 'Cleanly';
  static const String tagline = 'Cleaning Checklist';
  static const String fullName = 'Cleanly: Cleaning Checklist';
  static const String version = '1.5.1';
}

class CleanlyApp extends ConsumerWidget {
  const CleanlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Kontroler iklan menyiapkan consent dan interstitial sekali di awal;
    // tidak ada layar yang menunggu hasilnya.
    ref.watch(adsProvider);
    final settings = ref.watch(settingsProvider);
    final dark = settings.darkMode;

    return MaterialApp(
      title: AppIdentity.fullName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(skin: settings.skin),
      darkTheme: AppTheme.build(skin: settings.skin, brightness: Brightness.dark),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      supportedLocales: const [Locale('en'), Locale('id')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final theme = Theme.of(context);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations:
                MediaQuery.of(context).disableAnimations ||
                settings.reducedMotion,
          ),
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: theme.brightness == Brightness.dark
                ? SystemUiOverlayStyle.light.copyWith(
                    systemNavigationBarColor: theme.scaffoldBackgroundColor,
                  )
                : SystemUiOverlayStyle.dark.copyWith(
                    systemNavigationBarColor: theme.scaffoldBackgroundColor,
                  ),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      home: const SplashScreen(),
    );
  }
}
