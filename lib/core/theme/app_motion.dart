import 'package:flutter/material.dart';

/// Menghormati pengaturan "kurangi animasi" perangkat maupun pilihan pengguna.
class AppMotion {
  AppMotion._();

  static Duration duration(BuildContext context, Duration normal) {
    final media = MediaQuery.maybeOf(context);
    return media?.disableAnimations == true ? Duration.zero : normal;
  }

  static bool reduced(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations == true;

  static const fast = Duration(milliseconds: 180);
  static const normal = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 520);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve spring = Curves.easeOutBack;
}
