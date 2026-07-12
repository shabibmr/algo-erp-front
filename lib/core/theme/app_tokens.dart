import 'package:flutter/material.dart';

@immutable
class AppSpacing {
  const AppSpacing({
    this.xxs = 2,
    this.xs = 4,
    this.sm = 8,
    this.md = 16,
    this.lg = 24,
    this.xl = 32,
    this.xxl = 48,
  });

  final double xxs;
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;
}

@immutable
class AppRadii {
  const AppRadii({
    this.sm = 4,
    this.md = 8,
    this.lg = 12,
    this.xl = 16,
    this.full = 999,
  });

  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double full;
}

@immutable
class AppElevation {
  const AppElevation({
    this.level0 = 0,
    this.level1 = 1,
    this.level2 = 3,
    this.level3 = 6,
    this.level4 = 8,
  });

  final double level0;
  final double level1;
  final double level2;
  final double level3;
  final double level4;
}

/// Named surfaces and brand accents for the Ledger & Linen system.
/// Widgets should prefer these over raw [ColorScheme] when the desk
/// metaphor matters (canvas, paper cards, lagoon seals, brass money).
@immutable
class BrandColors {
  const BrandColors({
    required this.linen,
    required this.paper,
    required this.mist,
    required this.ink,
    required this.inkMuted,
    required this.lagoon,
    required this.lagoonSoft,
    required this.brass,
    required this.oxblood,
  });

  final Color linen;
  final Color paper;
  final Color mist;
  final Color ink;
  final Color inkMuted;
  final Color lagoon;
  final Color lagoonSoft;
  final Color brass;
  final Color oxblood;

  static const light = BrandColors(
    linen: Color(0xFFF1EDE6),
    paper: Color(0xFFFBF9F6),
    mist: Color(0xFFE4E9EE),
    ink: Color(0xFF1A2330),
    inkMuted: Color(0xFF5C6778),
    lagoon: Color(0xFF0E6B68),
    lagoonSoft: Color(0xFFD7EFED),
    brass: Color(0xFFB8843B),
    oxblood: Color(0xFF8F3535),
  );

  static const dark = BrandColors(
    linen: Color(0xFF11161D),
    paper: Color(0xFF1A212B),
    mist: Color(0xFF2A3340),
    ink: Color(0xFFE8ECF1),
    inkMuted: Color(0xFF9AA3B2),
    lagoon: Color(0xFF3CB8B0),
    lagoonSoft: Color(0xFF1A3D3B),
    brass: Color(0xFFD9A45C),
    oxblood: Color(0xFFE07A7A),
  );
}

/// Voucher lifecycle status colors, kept separate from Material's semantic
/// roles because a voucher's status maps to domain meaning, not UI severity.
@immutable
class VoucherStatusColors {
  const VoucherStatusColors({
    required this.draft,
    required this.approved,
    required this.posted,
    required this.cancelled,
    required this.rejected,
    required this.pendingSync,
  });

  final Color draft;
  final Color approved;
  final Color posted;
  final Color cancelled;
  final Color rejected;
  final Color pendingSync;

  static const light = VoucherStatusColors(
    draft: Color(0xFF5C6778),
    approved: Color(0xFF0E6B68),
    posted: Color(0xFF2F6F4E),
    cancelled: Color(0xFF8F3535),
    rejected: Color(0xFF8F3535),
    pendingSync: Color(0xFFB8843B),
  );

  static const dark = VoucherStatusColors(
    draft: Color(0xFF9AA3B2),
    approved: Color(0xFF3CB8B0),
    posted: Color(0xFF6BBF8A),
    cancelled: Color(0xFFE07A7A),
    rejected: Color(0xFFE07A7A),
    pendingSync: Color(0xFFD9A45C),
  );
}

@immutable
class SemanticColors {
  const SemanticColors({
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.danger,
    required this.onDanger,
    required this.info,
    required this.onInfo,
  });

  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;
  final Color danger;
  final Color onDanger;
  final Color info;
  final Color onInfo;

  static const light = SemanticColors(
    success: Color(0xFF2F6F4E),
    onSuccess: Color(0xFFFFFFFF),
    warning: Color(0xFFB8843B),
    onWarning: Color(0xFFFFFFFF),
    danger: Color(0xFF8F3535),
    onDanger: Color(0xFFFFFFFF),
    info: Color(0xFF0E6B68),
    onInfo: Color(0xFFFFFFFF),
  );

  static const dark = SemanticColors(
    success: Color(0xFF6BBF8A),
    onSuccess: Color(0xFF052E16),
    warning: Color(0xFFD9A45C),
    onWarning: Color(0xFF2A1A05),
    danger: Color(0xFFE07A7A),
    onDanger: Color(0xFF2A0A0A),
    info: Color(0xFF3CB8B0),
    onInfo: Color(0xFF0A1F1E),
  );
}

/// How a ledger sheet rules its lines.
///
/// The rules are drawn faint between rows and at full strength every
/// [groupEvery] rows — the way a paper ledger pad rules in fives so the eye
/// can count down a column without losing its place. This is the one place
/// that rhythm is defined; `LedgerTable` reads it and nothing else should
/// hardcode a row divider.
@immutable
class LedgerTokens {
  const LedgerTokens({
    required this.ruleFaint,
    required this.ruleStrong,
    required this.rowHover,
    required this.rowSelected,
    required this.gutter,
    this.groupEvery = 5,
    this.gutterWidth = 2,
    this.rowMinHeight = 44,
  });

  /// The rule drawn between ordinary rows.
  final Color ruleFaint;

  /// The rule drawn under the header and under every [groupEvery]th row.
  final Color ruleStrong;

  final Color rowHover;
  final Color rowSelected;

  /// The edge lit in a row's left gutter on hover/focus.
  final Color gutter;

  final int groupEvery;
  final double gutterWidth;
  final double rowMinHeight;

  // The two rules are drawn from one ink at two strengths, not from two
  // different greys — that's what makes every fifth line read as *the same
  // line, pressed harder*. Plain `mist` is too pale against paper to carry the
  // difference, so the ledger rules in a deeper slate of its own.
  static const light = LedgerTokens(
    ruleFaint: Color(0x40B3C0CC), // slate @ 25%
    ruleStrong: Color(0xFFB3C0CC), // slate
    rowHover: Color(0x73D7EFED), // lagoonSoft @ 45%
    rowSelected: Color(0xFFD7EFED), // lagoonSoft
    gutter: Color(0xFF0E6B68), // lagoon
  );

  static const dark = LedgerTokens(
    ruleFaint: Color(0x40566274),
    ruleStrong: Color(0xFF566274),
    rowHover: Color(0x731A3D3B),
    rowSelected: Color(0xFF1A3D3B),
    gutter: Color(0xFF3CB8B0),
  );
}

/// Design-token layer so widgets never hardcode colors/spacing/radii.
/// Access via `Theme.of(context).extension<AppTokens>()!` or the
/// `context.tokens` extension in `core/utils/extensions`.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.brand,
    required this.semanticColors,
    required this.voucherStatusColors,
    required this.ledger,
    this.spacing = const AppSpacing(),
    this.radii = const AppRadii(),
    this.elevation = const AppElevation(),
    this.figures = defaultFigures,
  });

  /// Fallback figure style. `AppTheme` replaces this with IBM Plex Mono at
  /// theme-build time; the const default keeps [AppTokens] const-constructible
  /// (and keeps tests that build tokens directly from needing a font).
  static const defaultFigures = TextStyle(
    fontFeatures: [FontFeature('tnum'), FontFeature('lnum')],
  );

  final BrandColors brand;
  final SemanticColors semanticColors;
  final VoucherStatusColors voucherStatusColors;
  final LedgerTokens ledger;
  final AppSpacing spacing;
  final AppRadii radii;
  final AppElevation elevation;

  /// IBM Plex Mono with tabular, lining figures — for codes, quantities and
  /// money, so digits align on the decimal down a column. Never use it for
  /// prose. Callers restyle color/size via `copyWith`.
  final TextStyle figures;

  static const light = AppTokens(
    brand: BrandColors.light,
    semanticColors: SemanticColors.light,
    voucherStatusColors: VoucherStatusColors.light,
    ledger: LedgerTokens.light,
  );

  static const dark = AppTokens(
    brand: BrandColors.dark,
    semanticColors: SemanticColors.dark,
    voucherStatusColors: VoucherStatusColors.dark,
    ledger: LedgerTokens.dark,
  );

  @override
  AppTokens copyWith({
    BrandColors? brand,
    SemanticColors? semanticColors,
    VoucherStatusColors? voucherStatusColors,
    LedgerTokens? ledger,
    AppSpacing? spacing,
    AppRadii? radii,
    AppElevation? elevation,
    TextStyle? figures,
  }) {
    return AppTokens(
      brand: brand ?? this.brand,
      semanticColors: semanticColors ?? this.semanticColors,
      voucherStatusColors: voucherStatusColors ?? this.voucherStatusColors,
      ledger: ledger ?? this.ledger,
      spacing: spacing ?? this.spacing,
      radii: radii ?? this.radii,
      elevation: elevation ?? this.elevation,
      figures: figures ?? this.figures,
    );
  }

  @override
  AppTokens lerp(covariant ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    // Discrete design tokens aren't meaningfully interpolated; snap at the
    // midpoint so theme-mode transitions don't produce muddy in-between hues.
    return t < 0.5 ? this : other;
  }
}
