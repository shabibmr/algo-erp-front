import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:algo_erp_front/core/theme/motion_tokens.dart';

/// Magic Animated Brand Logo component.
///
/// Brings static logo assets to life using multi-layered AI-driven style motion:
/// 1. Smooth entrance reveal (scale + fade + rotation curve).
/// 2. Continuous ambient pulse / breathing effect.
/// 3. Periodic metallic/shimmer light sweep across the mark.
/// 4. Dynamic hover/press micro-interactions.
class AnimatedBrandLogo extends StatefulWidget {
  const AnimatedBrandLogo({
    super.key,
    this.assetPath = 'assets/brand/algo_mark.png',
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.enableAmbientPulse = true,
    this.enableShimmer = true,
    this.enableInteractiveSpring = true,
    this.onTap,
    this.errorBuilder,
  });

  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool enableAmbientPulse;
  final bool enableShimmer;
  final bool enableInteractiveSpring;
  final VoidCallback? onTap;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  @override
  State<AnimatedBrandLogo> createState() => _AnimatedBrandLogoState();
}

class _AnimatedBrandLogoState extends State<AnimatedBrandLogo>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _entranceScale;
  late final Animation<double> _entranceFade;
  late final Animation<double> _entranceRotate;

  late final AnimationController _ambientController;
  late final Animation<double> _ambientScale;

  late final AnimationController _shimmerController;

  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    // 1. Entrance animation
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _entranceScale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutBack,
      ),
    );

    _entranceFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _entranceRotate = Tween<double>(begin: -0.08, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutCubic,
      ),
    );

    // 2. Ambient breathing
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    _ambientScale = Tween<double>(begin: 1.0, end: 1.045).animate(
      CurvedAnimation(
        parent: _ambientController,
        curve: Curves.easeInOutSine,
      ),
    );

    if (widget.enableAmbientPulse) {
      _ambientController.repeat(reverse: true);
    }

    // 3. Periodic shimmer sweep
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    if (widget.enableShimmer) {
      _startShimmerTimer();
    }

    _entranceController.forward();
  }

  void _startShimmerTimer() async {
    while (mounted) {
      await Future<void>.delayed(const Duration(seconds: 4));
      if (!mounted) break;
      if (widget.enableShimmer) {
        await _shimmerController.forward(from: 0.0);
      }
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedBrandLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enableAmbientPulse != oldWidget.enableAmbientPulse) {
      if (widget.enableAmbientPulse) {
        _ambientController.repeat(reverse: true);
      } else {
        _ambientController.stop();
        _ambientController.animateTo(0.0);
      }
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _ambientController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (widget.enableInteractiveSpring) {
          setState(() => _isHovered = true);
        }
      },
      onExit: (_) {
        if (widget.enableInteractiveSpring) {
          setState(() {
            _isHovered = false;
            _isPressed = false;
          });
        }
      },
      child: GestureDetector(
        onTapDown: (_) {
          if (widget.enableInteractiveSpring) {
            setState(() => _isPressed = true);
          }
        },
        onTapUp: (_) {
          if (widget.enableInteractiveSpring) {
            setState(() => _isPressed = false);
          }
          widget.onTap?.call();
        },
        onTapCancel: () {
          if (widget.enableInteractiveSpring) {
            setState(() => _isPressed = false);
          }
        },
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _entranceController,
            _ambientController,
            _shimmerController,
          ]),
          builder: (context, child) {
            final double baseScale = _entranceScale.value *
                (widget.enableAmbientPulse ? _ambientScale.value : 1.0);

            final double interactiveScale = _isPressed
                ? 0.92
                : (_isHovered ? 1.08 : 1.0);

            final double finalScale = baseScale * interactiveScale;
            final double finalRotation = _entranceRotate.value +
                (_isHovered ? -0.03 : 0.0) +
                (_isPressed ? 0.04 : 0.0);

            Widget logoImage = Image.asset(
              widget.assetPath,
              width: widget.width,
              height: widget.height,
              fit: widget.fit,
              filterQuality: FilterQuality.high,
              errorBuilder: widget.errorBuilder ??
                  (_, __, ___) => Icon(
                        Icons.hexagon_outlined,
                        size: widget.height ?? 32,
                        color: Theme.of(context).colorScheme.primary,
                      ),
            );

            // Apply shimmer light sweep effect
            if (widget.enableShimmer && _shimmerController.isAnimating) {
              logoImage = ShaderMask(
                blendMode: BlendMode.srcATop,
                shaderCallback: (bounds) {
                  final progress = _shimmerController.value;
                  final shimmerWidth = bounds.width * 0.8;
                  final startX = (bounds.width + shimmerWidth * 2) * progress - shimmerWidth;

                  return LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: const [
                      Colors.transparent,
                      Color(0x33FFFFFF),
                      Color(0xBBFFFFFF),
                      Color(0x33FFFFFF),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
                    transform: _GradientTranslation(startX),
                  ).createShader(bounds);
                },
                child: logoImage,
              );
            }

            return Opacity(
              opacity: _entranceFade.value.clamp(0.0, 1.0),
              child: Transform.rotate(
                angle: finalRotation,
                child: Transform.scale(
                  scale: finalScale,
                  child: AnimatedContainer(
                    duration: MotionTokens.fast,
                    curve: MotionTokens.emphasizedCurve,
                    child: logoImage,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GradientTranslation extends GradientTransform {
  const _GradientTranslation(this.dx);
  final double dx;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(dx, 0.0, 0.0);
  }
}
