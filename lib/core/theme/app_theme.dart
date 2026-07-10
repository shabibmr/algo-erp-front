import 'package:algo_erp_front/core/theme/app_tokens.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const _seed = Color(0xFF2563EB);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    final tokens = brightness == Brightness.light
        ? AppTokens.light
        : AppTokens.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      // ERP screens are data-dense (tables, forms); compact density keeps
      // more rows/fields visible without scrolling on desktop/web.
      visualDensity: VisualDensity.compact,
      extensions: [tokens],
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radii.md),
        ),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: tokens.spacing.md,
          vertical: tokens.spacing.sm,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: tokens.elevation.level1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radii.lg),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        useIndicator: true,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radii.md),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radii.full),
        ),
      ),
    );
  }
}
