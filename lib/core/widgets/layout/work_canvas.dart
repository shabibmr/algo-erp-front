import 'package:algo_erp_front/core/theme/motion_tokens.dart';
import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:flutter/material.dart';

/// The **Desk Lamp** — a soft lagoon focus rim over a surface's content canvas.
///
/// Wraps a form or voucher surface and paints a subtle lagoon glow around the
/// working area: a faint inner edge plus a blurred ambient wash, fading in once
/// on route-enter. It encodes "this is your work right now" — personal
/// attention on *this* document — the signature moment of the Ledger & Linen
/// design (`docs/UI_DESIGN_PLAN.md` §2B / §5.4).
///
/// The rim is a [CustomPaint] `foregroundPainter`, so it paints on top of the
/// child without joining layout or hit-testing: no shift, no swallowed taps.
/// Colour comes from `tokens.brand.lagoon`, so dark mode's Lagoon glow is
/// automatic. Reduced motion (`MediaQuery.disableAnimations`) shows the rim
/// immediately instead of fading it in.
class WorkCanvas extends StatelessWidget {
  const WorkCanvas({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: reduceMotion ? Duration.zero : MotionTokens.slow,
      curve: MotionTokens.decelerate,
      builder: (context, t, child) => CustomPaint(
        foregroundPainter: _RimPainter(
          t: t,
          color: tokens.brand.lagoon,
          radius: tokens.radii.lg,
        ),
        child: child,
      ),
      child: child,
    );
  }
}

/// Paints the desk-lamp rim inside its bounds: a blurred ambient wash pooling
/// inward, then a faint crisp edge on top. Both scale their opacity by [t] so
/// the whole rim fades up together.
class _RimPainter extends CustomPainter {
  const _RimPainter({
    required this.t,
    required this.color,
    required this.radius,
  });

  final double t;
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;

    // Inset by 1px so the stroke sits just inside the canvas edge rather than
    // being clipped by it.
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(1),
      Radius.circular(radius),
    );

    // Soft ambient wash — a wide, blurred stroke that bleeds the lagoon glow
    // inward from the edge (the "desk lamp" pooling on the paper).
    final wash = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = color.withValues(alpha: 0.10 * t)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawRRect(rrect, wash);

    // Faint inner edge — a crisp 1.5px line that reads as a deliberate frame.
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = color.withValues(alpha: 0.18 * t);
    canvas.drawRRect(rrect, edge);
  }

  @override
  bool shouldRepaint(_RimPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.color != color ||
      oldDelegate.radius != radius;
}
