import 'package:flutter/material.dart';

/// Satu keluarga warna aksen: nada dasar, nada gelap untuk teks, dan nada
/// lembut untuk latar chip/kartu.
class AccentFamily {
  const AccentFamily({
    required this.base,
    required this.deep,
    required this.soft,
  });

  final Color base;
  final Color deep;
  final Color soft;
}

/// Token warna Cleanly. Berbeda dari tema generik karena setiap aksen punya
/// tiga tingkat kontras yang dipakai konsisten oleh kartu ruangan, chip
/// durasi, dan ring timer.
@immutable
class CleanlyColors extends ThemeExtension<CleanlyColors> {
  const CleanlyColors({
    required this.canvas,
    required this.surface,
    required this.surfaceMuted,
    required this.surfaceSunk,
    required this.hairline,
    required this.ink,
    required this.inkSoft,
    required this.inkFaint,
    required this.shadow,
    required this.primary,
    required this.primaryDeep,
    required this.primarySoft,
    required this.accent,
    required this.accentDeep,
    required this.accentSoft,
    required this.jade,
    required this.marigold,
    required this.sky,
    required this.iris,
    required this.blossom,
  });

  final Color canvas;
  final Color surface;
  final Color surfaceMuted;
  final Color surfaceSunk;
  final Color hairline;
  final Color ink;
  final Color inkSoft;
  final Color inkFaint;
  final Color shadow;

  /// Warna skin aktif (dapat ditukar pemain lewat rewarded ad).
  final Color primary;
  final Color primaryDeep;
  final Color primarySoft;
  final Color accent;
  final Color accentDeep;
  final Color accentSoft;

  final AccentFamily jade;
  final AccentFamily marigold;
  final AccentFamily sky;
  final AccentFamily iris;
  final AccentFamily blossom;

  static const _jade = AccentFamily(
    base: Color(0xFF12A583),
    deep: Color(0xFF0A7C60),
    soft: Color(0xFFDFF3EC),
  );
  static const _marigold = AccentFamily(
    base: Color(0xFFF0A11C),
    deep: Color(0xFF9C6610),
    soft: Color(0xFFFDEFD8),
  );
  static const _sky = AccentFamily(
    base: Color(0xFF2E9FD6),
    deep: Color(0xFF1B739F),
    soft: Color(0xFFDDEEF9),
  );
  static const _iris = AccentFamily(
    base: Color(0xFF7A6BEE),
    deep: Color(0xFF5244BF),
    soft: Color(0xFFE9E6FD),
  );
  static const _blossom = AccentFamily(
    base: Color(0xFFE9699A),
    deep: Color(0xFFB24270),
    soft: Color(0xFFFCE4EE),
  );

  static const _nightJade = AccentFamily(
    base: Color(0xFF3FCBA6),
    deep: Color(0xFF0F3A2F),
    soft: Color(0xFF1C4C3E),
  );
  static const _nightMarigold = AccentFamily(
    base: Color(0xFFFFC258),
    deep: Color(0xFF3D2C10),
    soft: Color(0xFF4A3617),
  );
  static const _nightSky = AccentFamily(
    base: Color(0xFF65C2EC),
    deep: Color(0xFF11313F),
    soft: Color(0xFF1A4256),
  );
  static const _nightIris = AccentFamily(
    base: Color(0xFFA79AFB),
    deep: Color(0xFF26214A),
    soft: Color(0xFF332C63),
  );
  static const _nightBlossom = AccentFamily(
    base: Color(0xFFFF9CBF),
    deep: Color(0xFF3E1B2A),
    soft: Color(0xFF54253A),
  );

  static const light = CleanlyColors(
    canvas: Color(0xFFF4F8F6),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFEDF3F0),
    surfaceSunk: Color(0xFFE3EBE7),
    hairline: Color(0xFFDEE8E3),
    ink: Color(0xFF0F1F1B),
    inkSoft: Color(0xFF526761),
    inkFaint: Color(0xFF7B8C86),
    shadow: Color(0xFF1E3A31),
    primary: Color(0xFF12A583),
    primaryDeep: Color(0xFF0A7C60),
    primarySoft: Color(0xFFDFF3EC),
    accent: Color(0xFFF0A11C),
    accentDeep: Color(0xFF9C6610),
    accentSoft: Color(0xFFFDEFD8),
    jade: _jade,
    marigold: _marigold,
    sky: _sky,
    iris: _iris,
    blossom: _blossom,
  );

  static const dark = CleanlyColors(
    canvas: Color(0xFF0E1614),
    surface: Color(0xFF172320),
    surfaceMuted: Color(0xFF1E2C28),
    surfaceSunk: Color(0xFF101B18),
    hairline: Color(0xFF2A3B35),
    ink: Color(0xFFEAF5F0),
    inkSoft: Color(0xFFA3B7B0),
    inkFaint: Color(0xFF7C9089),
    shadow: Color(0xFF000000),
    primary: Color(0xFF3FCBA6),
    primaryDeep: Color(0xFF1C4C3E),
    primarySoft: Color(0xFF123A2F),
    accent: Color(0xFFFFC258),
    accentDeep: Color(0xFF4A3617),
    accentSoft: Color(0xFF3D2C10),
    jade: _nightJade,
    marigold: _nightMarigold,
    sky: _nightSky,
    iris: _nightIris,
    blossom: _nightBlossom,
  );

  /// Palet bawaannya jade; skin lain hanya mengganti pasangan primary/accent.
  CleanlyColors withSkin(ThemeSkin skin, {required bool dark}) {
    final base = dark ? CleanlyColors.dark : CleanlyColors.light;
    return base.copyWith(
      primary: skin.primary(dark: dark),
      primaryDeep: skin.primaryDeep(dark: dark),
      primarySoft: skin.primarySoft(dark: dark),
      accent: skin.accent(dark: dark),
      accentDeep: skin.accentDeep(dark: dark),
      accentSoft: skin.accentSoft(dark: dark),
    );
  }

  AccentFamily accentFor(CleanlyAccent accent) => switch (accent) {
    CleanlyAccent.jade => jade,
    CleanlyAccent.marigold => marigold,
    CleanlyAccent.sky => sky,
    CleanlyAccent.iris => iris,
    CleanlyAccent.blossom => blossom,
  };

  /// Bayangan lembut khas Cleanly: lebar dan rendah opacity, bukan drop-shadow
  /// tebal yang membuat kartu terasa template.
  List<BoxShadow> softShadow({
    double opacity = 0.06,
    double blur = 22,
    double y = 8,
  }) {
    return [
      BoxShadow(
        color: shadow.withValues(alpha: opacity),
        blurRadius: blur,
        offset: Offset(0, y),
      ),
    ];
  }

  @override
  CleanlyColors copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceMuted,
    Color? surfaceSunk,
    Color? hairline,
    Color? ink,
    Color? inkSoft,
    Color? inkFaint,
    Color? shadow,
    Color? primary,
    Color? primaryDeep,
    Color? primarySoft,
    Color? accent,
    Color? accentDeep,
    Color? accentSoft,
    AccentFamily? jade,
    AccentFamily? marigold,
    AccentFamily? sky,
    AccentFamily? iris,
    AccentFamily? blossom,
  }) {
    return CleanlyColors(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      surfaceSunk: surfaceSunk ?? this.surfaceSunk,
      hairline: hairline ?? this.hairline,
      ink: ink ?? this.ink,
      inkSoft: inkSoft ?? this.inkSoft,
      inkFaint: inkFaint ?? this.inkFaint,
      shadow: shadow ?? this.shadow,
      primary: primary ?? this.primary,
      primaryDeep: primaryDeep ?? this.primaryDeep,
      primarySoft: primarySoft ?? this.primarySoft,
      accent: accent ?? this.accent,
      accentDeep: accentDeep ?? this.accentDeep,
      accentSoft: accentSoft ?? this.accentSoft,
      jade: jade ?? this.jade,
      marigold: marigold ?? this.marigold,
      sky: sky ?? this.sky,
      iris: iris ?? this.iris,
      blossom: blossom ?? this.blossom,
    );
  }

  @override
  CleanlyColors lerp(ThemeExtension<CleanlyColors>? other, double t) {
    if (other is! CleanlyColors) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t) ?? a;
    AccentFamily mixFamily(AccentFamily a, AccentFamily b) => AccentFamily(
      base: mix(a.base, b.base),
      deep: mix(a.deep, b.deep),
      soft: mix(a.soft, b.soft),
    );
    return CleanlyColors(
      canvas: mix(canvas, other.canvas),
      surface: mix(surface, other.surface),
      surfaceMuted: mix(surfaceMuted, other.surfaceMuted),
      surfaceSunk: mix(surfaceSunk, other.surfaceSunk),
      hairline: mix(hairline, other.hairline),
      ink: mix(ink, other.ink),
      inkSoft: mix(inkSoft, other.inkSoft),
      inkFaint: mix(inkFaint, other.inkFaint),
      shadow: mix(shadow, other.shadow),
      primary: mix(primary, other.primary),
      primaryDeep: mix(primaryDeep, other.primaryDeep),
      primarySoft: mix(primarySoft, other.primarySoft),
      accent: mix(accent, other.accent),
      accentDeep: mix(accentDeep, other.accentDeep),
      accentSoft: mix(accentSoft, other.accentSoft),
      jade: mixFamily(jade, other.jade),
      marigold: mixFamily(marigold, other.marigold),
      sky: mixFamily(sky, other.sky),
      iris: mixFamily(iris, other.iris),
      blossom: mixFamily(blossom, other.blossom),
    );
  }
}

/// Lima keluarga aksen yang bisa dirujuk data (mis. warna kartu ruangan).
enum CleanlyAccent { jade, marigold, sky, iris, blossom }

/// Tema warna aplikasi. Tiga pertama gratis, dua terakhir dibuka lewat
/// rewarded ad.
enum ThemeSkin {
  fresh(
    label: 'Fresh',
    accentKey: CleanlyAccent.jade,
    secondaryKey: CleanlyAccent.marigold,
    rewardedOnly: false,
  ),
  sunset(
    label: 'Sunset',
    accentKey: CleanlyAccent.marigold,
    secondaryKey: CleanlyAccent.blossom,
    rewardedOnly: false,
  ),
  nordic(
    label: 'Nordic',
    accentKey: CleanlyAccent.sky,
    secondaryKey: CleanlyAccent.jade,
    rewardedOnly: false,
  ),
  bloom(
    label: 'Bloom',
    accentKey: CleanlyAccent.blossom,
    secondaryKey: CleanlyAccent.iris,
    rewardedOnly: true,
  ),
  midnight(
    label: 'Midnight',
    accentKey: CleanlyAccent.iris,
    secondaryKey: CleanlyAccent.sky,
    rewardedOnly: true,
  );

  const ThemeSkin({
    required this.label,
    required this.accentKey,
    required this.secondaryKey,
    required this.rewardedOnly,
  });

  final String label;
  final CleanlyAccent accentKey;
  final CleanlyAccent secondaryKey;
  final bool rewardedOnly;

  static const defaultSkin = ThemeSkin.fresh;

  static ThemeSkin fromName(String? name) {
    return ThemeSkin.values.firstWhere(
      (skin) => skin.name == name,
      orElse: () => defaultSkin,
    );
  }

  Color primary({required bool dark}) => _family(accentKey, dark: dark).base;

  Color primaryDeep({required bool dark}) =>
      _family(accentKey, dark: dark).deep;

  Color primarySoft({required bool dark}) =>
      _family(accentKey, dark: dark).soft;

  Color accent({required bool dark}) =>
      _family(secondaryKey, dark: dark).base;

  Color accentDeep({required bool dark}) =>
      _family(secondaryKey, dark: dark).deep;

  Color accentSoft({required bool dark}) =>
      _family(secondaryKey, dark: dark).soft;

  AccentFamily _family(CleanlyAccent key, {required bool dark}) {
    return (dark ? CleanlyColors.dark : CleanlyColors.light).accentFor(key);
  }

  /// Gradien khas tiap skin untuk header dan tombol utama.
  List<Color> gradient({required bool dark}) => [
    primary(dark: dark),
    Color.lerp(primary(dark: dark), accent(dark: dark), 0.55) ?? primary(dark: dark),
  ];
}

extension CleanlyColorsX on BuildContext {
  CleanlyColors get cleanly =>
      Theme.of(this).extension<CleanlyColors>() ?? CleanlyColors.light;
}
