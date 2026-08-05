import 'package:algo_erp_front/core/theme/app_tokens.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Ledger & Linen theme: lagoon primary, linen canvas, clerk density.
abstract final class AppTheme {
  /// Gulf lagoon — primary seed (not Material blue).
  static const _seed = Color(0xFF0E6B68);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final tokens = isLight ? AppTokens.light : AppTokens.dark;
    final brand = tokens.brand;

    final baseScheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );

    final colorScheme = baseScheme.copyWith(
      primary: brand.lagoon,
      onPrimary: isLight ? Colors.white : const Color(0xFF052E2C),
      primaryContainer: brand.lagoonSoft,
      onPrimaryContainer: brand.ink,
      secondary: brand.brass,
      onSecondary: isLight ? Colors.white : const Color(0xFF2A1A05),
      secondaryContainer: isLight
          ? const Color(0xFFF3E6D0)
          : const Color(0xFF3D2E14),
      onSecondaryContainer: brand.ink,
      error: brand.oxblood,
      onError: Colors.white,
      surface: brand.paper,
      onSurface: brand.ink,
      onSurfaceVariant: brand.inkMuted,
      surfaceContainerLowest: brand.linen,
      surfaceContainerLow: brand.paper,
      surfaceContainer: brand.mist,
      surfaceContainerHigh: brand.mist,
      surfaceContainerHighest: isLight
          ? const Color(0xFFD8DEE4)
          : const Color(0xFF343E4C),
      outline: brand.mist,
      outlineVariant: isLight
          ? const Color(0xFFCFD6DD)
          : const Color(0xFF3A4452),
    );

    final plex = GoogleFonts.ibmPlexSansTextTheme();
    final fraunces = GoogleFonts.frauncesTextTheme();

    // Figures: IBM Plex Mono, tabular + lining, so digits align on the decimal
    // down a ledger column. Built once per theme and handed to AppTokens —
    // never call GoogleFonts per cell.
    final figures = GoogleFonts.ibmPlexMono(
      textStyle: AppTokens.defaultFigures,
      fontSize: 13.5,
      height: 1.35,
      color: brand.ink,
    );

    final textTheme = plex
        .copyWith(
          displayLarge: fraunces.displayLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: brand.ink,
          ),
          displayMedium: fraunces.displayMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: brand.ink,
          ),
          displaySmall: fraunces.displaySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: brand.ink,
          ),
          headlineLarge: fraunces.headlineLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: brand.ink,
          ),
          headlineMedium: fraunces.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: brand.ink,
          ),
          headlineSmall: fraunces.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: brand.ink,
          ),
          titleLarge: plex.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: brand.ink,
          ),
          titleMedium: plex.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: brand.ink,
          ),
          titleSmall: plex.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: brand.ink,
          ),
          bodyLarge: plex.bodyLarge?.copyWith(color: brand.ink),
          bodyMedium: plex.bodyMedium?.copyWith(color: brand.ink),
          bodySmall: plex.bodySmall?.copyWith(color: brand.inkMuted),
          labelLarge: plex.labelLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: brand.ink,
          ),
          labelMedium: plex.labelMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: brand.inkMuted,
          ),
          labelSmall: plex.labelSmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: brand.inkMuted,
            letterSpacing: 0.02 * 12,
          ),
        )
        .apply(bodyColor: brand.ink, displayColor: brand.ink);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: brand.linen,
      // ERP screens are data-dense (tables, forms); compact density keeps
      // more rows/fields visible without scrolling on desktop/web.
      visualDensity: VisualDensity.compact,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      extensions: [tokens.copyWith(figures: figures)],
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: brand.paper,
        foregroundColor: brand.ink,
        elevation: tokens.elevation.level0,
        scrolledUnderElevation: tokens.elevation.level1,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brand.paper,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radii.md),
          borderSide: BorderSide(color: brand.mist),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radii.md),
          borderSide: BorderSide(color: brand.mist),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radii.md),
          borderSide: BorderSide(color: brand.lagoon, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radii.md),
          borderSide: BorderSide(color: brand.oxblood),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radii.md),
          borderSide: BorderSide(color: brand.oxblood, width: 2),
        ),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: tokens.spacing.md,
          vertical: tokens.spacing.sm,
        ),
      ),
      cardTheme: CardThemeData(
        color: brand.paper,
        elevation: tokens.elevation.level1,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radii.lg),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brand.lagoon,
          foregroundColor: isLight ? Colors.white : const Color(0xFF052E2C),
          elevation: tokens.elevation.level1,
          // Content-sized actions — avoid M3's wide min + large horizontal pad
          // making "Save" / "Create" look like full-width chips on dense forms.
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spacing.md,
            vertical: tokens.spacing.sm,
          ),
          minimumSize: const Size(64, 36),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.radii.lg),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brand.ink,
          side: BorderSide(color: brand.mist),
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spacing.md,
            vertical: tokens.spacing.sm,
          ),
          minimumSize: const Size(64, 36),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.radii.lg),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brand.lagoon,
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spacing.sm,
            vertical: tokens.spacing.xs,
          ),
          minimumSize: const Size(48, 32),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: brand.paper,
        selectedIconTheme: IconThemeData(color: brand.lagoon),
        unselectedIconTheme: IconThemeData(color: brand.inkMuted),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: brand.lagoon,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: brand.inkMuted,
        ),
        indicatorColor: brand.lagoonSoft,
        useIndicator: true,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radii.md),
        ),
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: brand.paper,
        indicatorColor: brand.lagoonSoft,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radii.md),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: brand.mist,
        selectedColor: brand.lagoonSoft,
        labelStyle: textTheme.labelMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radii.full),
        ),
        side: BorderSide.none,
      ),
      dividerTheme: DividerThemeData(color: brand.mist, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: brand.ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: isLight ? brand.paper : brand.linen,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radii.md),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: brand.lagoon,
        linearTrackColor: brand.mist,
      ),
    );
  }
}
