import 'package:algo_erp_front/core/responsive/breakpoints.dart';
import 'package:algo_erp_front/core/theme/app_tokens.dart';
import 'package:algo_erp_front/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// Terse, uniform access to the three things almost every widget needs:
/// design tokens, localized strings, and the current breakpoint. Keeps
/// `Theme.of(context).extension<AppTokens>()!` and friends out of widget code.
extension BuildContextX on BuildContext {
  /// Design tokens (colors, spacing, radii, motion) — never hardcode instead.
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;

  /// Localized strings (en/ar).
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// Text direction — `true` when the active locale is RTL (Arabic).
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;

  DeviceClass get deviceClass => Breakpoints.of(this);
  bool get isMobile => Breakpoints.isMobile(this);
  bool get isTablet => Breakpoints.isTablet(this);
  bool get isDesktop => Breakpoints.isDesktop(this);

  /// True once the shell shows a persistent rail/sidebar (tablet and up).
  bool get hasPersistentNav => Breakpoints.hasPersistentNav(this);
}
