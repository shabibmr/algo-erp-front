import 'package:algo_erp_front/core/responsive/breakpoints.dart';
import 'package:flutter/material.dart';

/// A generic content layout that centers and caps content width on very
/// large screens, and goes edge-to-edge below desktop — avoids
/// unreadably-wide forms/tables on ultrawide monitors.
class AdaptiveLayout extends StatelessWidget {
  const AdaptiveLayout({
    required this.child,
    super.key,
    this.maxContentWidth = 1600,
    this.padding,
  });

  final Widget child;
  final double maxContentWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final device = Breakpoints.of(context);
    final effectivePadding =
        padding ??
        switch (device) {
          DeviceClass.mobile => const EdgeInsets.all(12),
          DeviceClass.tablet => const EdgeInsets.all(16),
          _ => const EdgeInsets.all(24),
        };

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentWidth),
        child: Padding(padding: effectivePadding, child: child),
      ),
    );
  }
}
