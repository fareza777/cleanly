import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

/// Tema Cleanly: lapang, tegas, dan tenang.
///
/// Ciri visualnya bukan "kartu putih + shadow tebal" yang generik, melainkan
/// kanvas mint yang lembut, kartu dengan garis rambut 1 px, sudut besar, dan
/// angka besar bertabular untuk timer. Semua teks memakai Plus Jakarta Sans
/// yang dibundel lokal sehingga tetap bekerja tanpa internet.
class AppTheme {
  AppTheme._();

  static const family = 'PlusJakartaSans';

  static TextStyle sans({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color? color,
    double? height,
    double letterSpacing = 0,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontFamily: family,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// Angka besar untuk countdown dan statistik.
  static TextStyle numeric({
    double size = 44,
    FontWeight weight = FontWeight.w800,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: family,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.05,
      letterSpacing: -1.2,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// Label mikro huruf besar, dipakai sebagai penanda seksi.
  static TextStyle overline({Color? color, double size = 11}) {
    return TextStyle(
      fontFamily: family,
      fontSize: size,
      fontWeight: FontWeight.w800,
      color: color,
      letterSpacing: 1.4,
      height: 1.2,
    );
  }

  static ThemeData build({
    required ThemeSkin skin,
    Brightness brightness = Brightness.light,
  }) {
    final dark = brightness == Brightness.dark;
    final colors = CleanlyColors.light.withSkin(skin, dark: dark);
    final base = ThemeData(brightness: brightness, useMaterial3: true);
    final scheme = (dark ? ColorScheme.dark() : ColorScheme.light()).copyWith(
      primary: colors.primary,
      onPrimary: dark ? const Color(0xFF08221B) : Colors.white,
      primaryContainer: colors.primarySoft,
      onPrimaryContainer: colors.primaryDeep,
      secondary: colors.accent,
      onSecondary: dark ? const Color(0xFF2A1C05) : Colors.white,
      secondaryContainer: colors.accentSoft,
      onSecondaryContainer: colors.accentDeep,
      tertiary: colors.iris.base,
      tertiaryContainer: colors.iris.soft,
      onTertiaryContainer: colors.iris.deep,
      surface: colors.surface,
      onSurface: colors.ink,
      onSurfaceVariant: colors.inkSoft,
      surfaceContainer: colors.surface,
      surfaceContainerLow: colors.canvas,
      surfaceContainerLowest: colors.surfaceSunk,
      surfaceContainerHigh: colors.surfaceMuted,
      surfaceContainerHighest: colors.surfaceMuted,
      outline: colors.hairline,
      outlineVariant: colors.hairline,
      error: dark ? const Color(0xFFFF9B8C) : const Color(0xFFB3261E),
      errorContainer: dark ? const Color(0xFF4A2119) : const Color(0xFFFBE3E0),
      onErrorContainer: dark ? const Color(0xFFFFDAD3) : const Color(0xFF7E1A14),
      onError: dark ? const Color(0xFF3A0F0A) : Colors.white,
      shadow: colors.shadow,
      surfaceTint: Colors.transparent,
    );

    final textTheme = TextTheme(
      displayLarge: sans(
        size: 34,
        weight: FontWeight.w800,
        height: 1.12,
        letterSpacing: -0.8,
        color: colors.ink,
      ),
      displayMedium: sans(
        size: 28,
        weight: FontWeight.w800,
        height: 1.15,
        letterSpacing: -0.6,
        color: colors.ink,
      ),
      headlineLarge: sans(
        size: 24,
        weight: FontWeight.w800,
        height: 1.2,
        letterSpacing: -0.4,
        color: colors.ink,
      ),
      headlineMedium: sans(
        size: 20,
        weight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.2,
        color: colors.ink,
      ),
      headlineSmall: sans(
        size: 17,
        weight: FontWeight.w700,
        height: 1.3,
        color: colors.ink,
      ),
      titleLarge: sans(
        size: 16,
        weight: FontWeight.w700,
        height: 1.3,
        color: colors.ink,
      ),
      titleMedium: sans(
        size: 14.5,
        weight: FontWeight.w700,
        height: 1.35,
        color: colors.ink,
      ),
      titleSmall: sans(
        size: 13,
        weight: FontWeight.w700,
        height: 1.35,
        color: colors.ink,
      ),
      bodyLarge: sans(
        size: 15,
        height: 1.5,
        color: colors.ink,
      ),
      bodyMedium: sans(size: 13.5, height: 1.5, color: colors.inkSoft),
      bodySmall: sans(size: 12, height: 1.45, color: colors.inkSoft),
      labelLarge: sans(
        size: 14,
        weight: FontWeight.w700,
        color: colors.ink,
      ),
      labelMedium: sans(
        size: 12,
        weight: FontWeight.w700,
        color: colors.inkSoft,
      ),
      labelSmall: overline(color: colors.inkFaint, size: 10.5),
    );

    return base.copyWith(
      extensions: [colors],
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.canvas,
      canvasColor: colors.canvas,
      cardColor: colors.surface,
      dividerColor: colors.hairline,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        systemOverlayStyle: dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: colors.ink, size: 22),
        titleTextStyle: sans(
          size: 18,
          weight: FontWeight.w800,
          letterSpacing: -0.2,
          color: colors.ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: colors.hairline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? colors.surfaceMuted : colors.canvas,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        hintStyle: sans(size: 14, color: colors.inkFaint),
        labelStyle: sans(size: 13, weight: FontWeight.w600, color: colors.inkSoft),
        prefixIconColor: colors.inkFaint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.error),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(48, 54),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: sans(size: 15, weight: FontWeight.w800),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(48, 54),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: sans(size: 15, weight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.ink,
          side: BorderSide(color: colors.hairline, width: 1.4),
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: sans(size: 14, weight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primaryDeep,
          minimumSize: const Size(48, 48),
          textStyle: sans(size: 14, weight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        extendedTextStyle: sans(size: 14.5, weight: FontWeight.w800),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface,
        indicatorColor: colors.primarySoft,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 70,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => sans(
            size: 11,
            weight: FontWeight.w700,
            color: states.contains(WidgetState.selected)
                ? colors.primaryDeep
                : colors.inkFaint,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 23,
            color: states.contains(WidgetState.selected)
                ? colors.primaryDeep
                : colors.inkFaint,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: dark ? colors.surfaceMuted : colors.ink,
        contentTextStyle: sans(size: 13.5, color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        titleTextStyle: sans(
          size: 19,
          weight: FontWeight.w800,
          color: colors.ink,
        ),
        contentTextStyle: sans(size: 14, height: 1.5, color: colors.inkSoft),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: colors.hairline,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: dark ? colors.surfaceMuted : colors.canvas,
        selectedColor: colors.primarySoft,
        side: BorderSide(color: colors.hairline),
        labelStyle: sans(size: 12.5, weight: FontWeight.w700, color: colors.ink),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
        linearTrackColor: colors.surfaceMuted,
        circularTrackColor: colors.surfaceMuted,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.surface
              : colors.inkFaint,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.primary
              : colors.surfaceMuted,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: colors.primary,
        thumbColor: colors.primary,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colors.inkSoft,
        textColor: colors.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: DividerThemeData(
        color: colors.hairline,
        thickness: 1,
        space: 1,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
