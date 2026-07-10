import 'package:flutter/animation.dart';

/// Durations and curves for page transitions, list stagger, and
/// hover/press micro-interactions. Keep every animation in the app on one
/// of these so pacing stays consistent.
abstract final class MotionTokens {
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration standard = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);

  static const Curve standardCurve = Curves.easeInOutCubic;
  static const Curve emphasizedCurve = Curves.easeOutCubic;
  static const Curve decelerate = Curves.decelerate;

  /// Per-item delay for staggered list-entry animations.
  static const Duration listStaggerStep = Duration(milliseconds: 30);

  static const Duration pageTransition = standard;
  static const Duration hoverPress = fast;
}
