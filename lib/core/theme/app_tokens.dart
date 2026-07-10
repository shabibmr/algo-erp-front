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
    draft: Color(0xFF6B7280),
    approved: Color(0xFF2563EB),
    posted: Color(0xFF15803D),
    cancelled: Color(0xFF991B1B),
    rejected: Color(0xFFB91C1C),
    pendingSync: Color(0xFFB45309),
  );

  static const dark = VoucherStatusColors(
    draft: Color(0xFF9CA3AF),
    approved: Color(0xFF60A5FA),
    posted: Color(0xFF4ADE80),
    cancelled: Color(0xFFF87171),
    rejected: Color(0xFFEF4444),
    pendingSync: Color(0xFFFBBF24),
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
    success: Color(0xFF15803D),
    onSuccess: Color(0xFFFFFFFF),
    warning: Color(0xFFB45309),
    onWarning: Color(0xFFFFFFFF),
    danger: Color(0xFFB91C1C),
    onDanger: Color(0xFFFFFFFF),
    info: Color(0xFF2563EB),
    onInfo: Color(0xFFFFFFFF),
  );

  static const dark = SemanticColors(
    success: Color(0xFF4ADE80),
    onSuccess: Color(0xFF052E16),
    warning: Color(0xFFFBBF24),
    onWarning: Color(0xFF451A03),
    danger: Color(0xFFF87171),
    onDanger: Color(0xFF450A0A),
    info: Color(0xFF60A5FA),
    onInfo: Color(0xFF172554),
  );
}

/// Design-token layer so widgets never hardcode colors/spacing/radii.
/// Access via `Theme.of(context).extension<AppTokens>()!` or the
/// `context.tokens` extension in `core/utils/extensions`.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.semanticColors,
    required this.voucherStatusColors,
    this.spacing = const AppSpacing(),
    this.radii = const AppRadii(),
    this.elevation = const AppElevation(),
  });

  final SemanticColors semanticColors;
  final VoucherStatusColors voucherStatusColors;
  final AppSpacing spacing;
  final AppRadii radii;
  final AppElevation elevation;

  static const light = AppTokens(
    semanticColors: SemanticColors.light,
    voucherStatusColors: VoucherStatusColors.light,
  );

  static const dark = AppTokens(
    semanticColors: SemanticColors.dark,
    voucherStatusColors: VoucherStatusColors.dark,
  );

  @override
  AppTokens copyWith({
    SemanticColors? semanticColors,
    VoucherStatusColors? voucherStatusColors,
    AppSpacing? spacing,
    AppRadii? radii,
    AppElevation? elevation,
  }) {
    return AppTokens(
      semanticColors: semanticColors ?? this.semanticColors,
      voucherStatusColors: voucherStatusColors ?? this.voucherStatusColors,
      spacing: spacing ?? this.spacing,
      radii: radii ?? this.radii,
      elevation: elevation ?? this.elevation,
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
