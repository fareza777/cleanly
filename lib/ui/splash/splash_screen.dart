import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app.dart';
import '../../core/theme/app_colors.dart';
import '../../state/app_settings.dart';
import '../../state/reminder_controller.dart';
import '../navigation/main_shell.dart';
import '../onboarding/onboarding_screen.dart';

/// Pembuka singkat: satu kesan merek, lalu langsung ke alur utama.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 900), _next);
    // Android membatalkan alarm lokal setelah aplikasi diperbarui, jadi
    // pengingat yang masih aktif dipasang ulang setiap aplikasi dibuka.
    // Tidak meminta izin dan tidak pernah menghalangi layar pembuka.
    unawaited(ref.read(reminderControllerProvider.notifier).resyncAll());
  }

  void _next() {
    if (!mounted) return;
    final done = ref.read(settingsProvider).onboardingDone;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, _, _) =>
            done ? const MainShell() : const OnboardingScreen(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.cleanly;
    final skin = ref.watch(settingsProvider.select((s) => s.skin));
    final dark = Theme.of(context).brightness == Brightness.dark;
    final gradient = skin.gradient(dark: dark);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.canvas,
              Color.lerp(colors.canvas, gradient.first, 0.16) ?? colors.canvas,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: colors.softShadow(opacity: 0.18, blur: 30, y: 14),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 44,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                AppIdentity.name,
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 6),
              Text(
                AppIdentity.tagline,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: colors.inkFaint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
