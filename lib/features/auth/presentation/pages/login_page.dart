import 'dart:ui' show ImageFilter;

import 'package:algo_erp_front/core/config/app_config.dart';
import 'package:algo_erp_front/core/theme/motion_tokens.dart';
import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/core/widgets/animated_brand_logo.dart';
import 'package:algo_erp_front/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Premium entrance curve — heavy mass, soft settle (Linear / Apple-tier).
const Curve _loginEntrance = Cubic(0.32, 0.72, 0, 1);

/// Ambient loop — slow, almost imperceptible breathing.
const Curve _ambientBreath = Cubic(0.45, 0.05, 0.55, 0.95);

/// Logo-mark stamp — quick overshoot then paper settle (desk seal).
const Curve _stampIn = Cubic(0.22, 1.2, 0.36, 1);

/// Stamp ring bloom — expands ahead of the mark, then softens away.
const Curve _stampRing = Cubic(0.16, 0.84, 0.44, 1);

/// Local UI toggle for password visibility on the login form.
class _ObscurePasswordCubit extends Cubit<bool> {
  _ObscurePasswordCubit() : super(true);
  void toggle() => emit(!state);
}

/// Adaptive sign-in screen — "closed desk, open for the day".
///
/// Editorial Luxury × Editorial Split: warm linen canvas, lagoon brand panel
/// with living ambient orbs, double-bezel paper card, staggered entrance
/// choreography. Fully token- and RTL-aware. Drives [AuthBloc]; navigation on
/// success is the router's auth redirect.
///
/// In dev with [AppConfig.skipLogin], the form is prefilled with the test
/// credentials so a failed auto-login is one tap to retry.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;

  /// Orchestrates the staggered first-paint reveal (logo → copy → card → fields).
  late final AnimationController _entrance;

  /// Slow ambient pulse for brand-panel orbs and ledger shimmer.
  late final AnimationController _ambient;

  /// Short loading seal pulse on the logo mark while auth is in flight.
  late final AnimationController _sealPulse;

  @override
  void initState() {
    super.initState();
    final prefillUser = AppConfig.isReady && !AppConfig.instance.isProd
        ? AppConfig.instance.devUsername
        : '';
    final prefillPass = AppConfig.isReady && !AppConfig.instance.isProd
        ? AppConfig.instance.devPassword
        : '';
    _usernameController = TextEditingController(text: prefillUser);
    _passwordController = TextEditingController(text: prefillPass);

    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 9000),
    );
    _sealPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    // Defer start so first frame paints at t=0 (no flash of settled state).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (reduce) {
        _entrance.value = 1;
      } else {
        _entrance.forward();
        _ambient.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    _ambient.dispose();
    _sealPulse.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _syncSealPulse({required bool isLoading, required bool reduceMotion}) {
    if (reduceMotion || !isLoading) {
      if (_sealPulse.isAnimating) _sealPulse.stop();
      _sealPulse.value = 0;
      return;
    }
    if (!_sealPulse.isAnimating) {
      _sealPulse.repeat(reverse: true);
    }
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(
      AuthLoginRequested(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  /// Interval helper: map global progress into a staggered 0→1 slice.
  Animation<double> _stagger(double begin, double end) {
    return CurvedAnimation(
      parent: _entrance,
      curve: Interval(begin, end, curve: _loginEntrance),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final brand = tokens.brand;
    final isMobile = context.isMobile;

    return BlocProvider(
      create: (_) => _ObscurePasswordCubit(),
      child: Scaffold(
        backgroundColor: brand.linen,
        body: BlocConsumer<AuthBloc, AuthState>(
          listenWhen: (previous, current) {
            if (current is AuthFailure && current.fieldErrors.isEmpty) {
              return true;
            }
            // Drive the logo-mark seal pulse with loading transitions.
            return (previous is AuthLoading) != (current is AuthLoading);
          },
          listener: (context, state) {
            if (state is AuthFailure) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.failure.message)));
            }
            final reduceMotion =
                MediaQuery.maybeOf(context)?.disableAnimations ?? false;
            _syncSealPulse(
              isLoading: state is AuthLoading,
              reduceMotion: reduceMotion,
            );
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            final fieldErrors = state is AuthFailure
                ? state.fieldErrors
                : const <String, String>{};

            return BlocBuilder<_ObscurePasswordCubit, bool>(
              builder: (context, obscurePassword) {
                final form = _LoginForm(
                  formKey: _formKey,
                  usernameController: _usernameController,
                  passwordController: _passwordController,
                  obscurePassword: obscurePassword,
                  onToggleObscure: context.read<_ObscurePasswordCubit>().toggle,
                  isLoading: isLoading,
                  fieldErrors: fieldErrors,
                  onSubmit: _submit,
                  stagger: _stagger,
                );

                if (isMobile) {
                  return _MobileLoginShell(
                    brandPanel: _BrandPanel(
                      ambient: _ambient,
                      entrance: _entrance,
                      sealPulse: _sealPulse,
                      isLoading: isLoading,
                      compact: true,
                    ),
                    form: form,
                    formEntrance: _stagger(0.18, 0.72),
                  );
                }

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Soft canvas wash behind the split — linen warming into
                    // lagoon glass so the seam between panels never hard-cuts.
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: tokens.gradient.canvas,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: _BrandPanel(
                            ambient: _ambient,
                            entrance: _entrance,
                            sealPulse: _sealPulse,
                            isLoading: isLoading,
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: SafeArea(
                            child: Center(
                              child: SingleChildScrollView(
                                padding: EdgeInsets.symmetric(
                                  horizontal: tokens.spacing.xl,
                                  vertical: tokens.spacing.xxl,
                                ),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 440,
                                  ),
                                  child: _Reveal(
                                    animation: _stagger(0.22, 0.78),
                                    child: _DoubleBezelCard(child: form),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Film grain — fixed, pointer-transparent, never on scroll.
                    const Positioned.fill(
                      child: IgnorePointer(child: _FilmGrainOverlay()),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shells
// ─────────────────────────────────────────────────────────────────────────────

/// Mobile: brand panel as a short hero band, form card floating on linen below.
class _MobileLoginShell extends StatelessWidget {
  const _MobileLoginShell({
    required this.brandPanel,
    required this.form,
    required this.formEntrance,
  });

  final Widget brandPanel;
  final Widget form;
  final Animation<double> formEntrance;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: tokens.brand.linen),
        SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(height: 220, child: brandPanel),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    tokens.spacing.lg,
                    tokens.spacing.lg,
                    tokens.spacing.lg,
                    tokens.spacing.xxl,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: _Reveal(
                        animation: formEntrance,
                        child: _DoubleBezelCard(child: form),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Positioned.fill(child: IgnorePointer(child: _FilmGrainOverlay())),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Brand panel — lagoon wash, living orbs, ledger rules, editorial type
// ─────────────────────────────────────────────────────────────────────────────

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({
    required this.ambient,
    required this.entrance,
    required this.sealPulse,
    required this.isLoading,
    this.compact = false,
  });

  final AnimationController ambient;
  final AnimationController entrance;
  final AnimationController sealPulse;
  final bool isLoading;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final brand = tokens.brand;
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: Listenable.merge([ambient, entrance, sealPulse]),
      builder: (context, _) {
        final breath = _ambientBreath.transform(ambient.value);
        final t = entrance.value;
        final pulse = isLoading
            ? Curves.easeInOut.transform(sealPulse.value)
            : 0.0;

        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Deep lagoon base with vertical depth.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      brand.lagoon,
                      Color.lerp(
                            brand.lagoon,
                            brand.ink,
                            0.28 + breath * 0.06,
                          ) ??
                          brand.lagoon,
                    ],
                  ),
                ),
              ),
              // Ambient mesh orbs — GPU-safe (transform/opacity only via paint).
              CustomPaint(
                painter: _AmbientOrbsPainter(
                  breath: breath,
                  lagoon: brand.lagoon,
                  brass: brand.brass,
                ),
              ),
              // Quiet ledger rules — paper memory of the product.
              CustomPaint(
                painter: _LedgerLinesPainter(
                  color: Colors.white.withValues(alpha: 0.05 + breath * 0.025),
                  phase: breath,
                ),
              ),
              // Content
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(
                    compact ? tokens.spacing.lg : tokens.spacing.xxl,
                  ),
                  child: compact
                      ? _BrandContentCompact(
                          t: t,
                          theme: theme,
                          breath: breath,
                          pulse: pulse,
                          isLoading: isLoading,
                        )
                      : _BrandContentDesktop(
                          t: t,
                          theme: theme,
                          breath: breath,
                          pulse: pulse,
                          isLoading: isLoading,
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BrandContentDesktop extends StatelessWidget {
  const _BrandContentDesktop({
    required this.t,
    required this.theme,
    required this.breath,
    required this.pulse,
    required this.isLoading,
  });

  final double t;
  final ThemeData theme;
  final double breath;
  final double pulse;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final spacing = context.tokens.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FadeSlide(
          progress: _slice(t, 0.0, 0.45),
          child: _EyebrowPill(label: 'algoERP', lightOnDark: true),
        ),
        const Spacer(),
        // Desk-seal stamp: mark lands first, then wordmark and copy follow.
        _LogoMarkStamp(
          progress: _slice(t, 0.04, 0.52),
          breath: breath,
          pulse: pulse,
          isLoading: isLoading,
          height: 78,
        ),
        SizedBox(height: spacing.lg),
        _FadeSlide(
          progress: _slice(t, 0.18, 0.65),
          child: Text(
            context.l10n.appTitle,
            style: theme.textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ),
        ),
        SizedBox(height: spacing.md),
        _FadeSlide(
          progress: _slice(t, 0.24, 0.72),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Text(
              "Your company's desk — open for the day.",
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.82),
                fontWeight: FontWeight.w400,
                height: 1.45,
              ),
            ),
          ),
        ),
        SizedBox(height: spacing.xl),
        _FadeSlide(
          progress: _slice(t, 0.32, 0.82),
          child: const _BrandSignals(),
        ),
        const Spacer(flex: 2),
        _FadeSlide(
          progress: _slice(t, 0.4, 0.9),
          child: Text(
            'Precision · Calm · Trust',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.45),
              letterSpacing: 0.18 * 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _BrandContentCompact extends StatelessWidget {
  const _BrandContentCompact({
    required this.t,
    required this.theme,
    required this.breath,
    required this.pulse,
    required this.isLoading,
  });

  final double t;
  final ThemeData theme;
  final double breath;
  final double pulse;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final spacing = context.tokens.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _FadeSlide(
          progress: _slice(t, 0.0, 0.5),
          child: Row(
            children: [
              _LogoMarkStamp(
                progress: _slice(t, 0.0, 0.48),
                breath: breath,
                pulse: pulse,
                isLoading: isLoading,
                height: 44,
                compact: true,
              ),
              SizedBox(width: spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.appTitle,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "Your company's desk — open for the day.",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Animated brand mark — stamps onto the lagoon panel like a brass desk seal.
///
/// Motion is transform/opacity only: slight rotation settle, scale overshoot,
/// expanding hairline ring. While [isLoading], a soft pulse keeps the seal
/// "alive" during the auth round-trip (router may leave as soon as authenticated).
class _LogoMarkStamp extends StatelessWidget {
  const _LogoMarkStamp({
    required this.progress,
    required this.breath,
    required this.pulse,
    required this.isLoading,
    required this.height,
    this.compact = false,
  });

  final double progress;
  final double breath;
  final double pulse;
  final bool isLoading;
  final double height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final brand = context.tokens.brand;
    final t = progress.clamp(0.0, 1.0);
    final stamp = _stampIn.transform(t);
    final ringT = _stampRing.transform(t);

    // Land from above with a tiny rotational settle — wax seal, not a bounce.
    final scale = 0.72 + stamp * 0.28;
    final loadScale = isLoading ? 1 + pulse * 0.035 : 1.0;
    final breathScale = 1 + breath * 0.012;
    final rotation =
        (1 - stamp) * (-0.11) + (stamp < 1 ? (1 - stamp) * 0.02 : 0);
    final dy = (1 - stamp) * (compact ? 10 : 16);

    // Ring blooms early, peaks, then softens so it doesn't fight the mark.
    final ringScale = 0.55 + ringT * 0.7;
    final ringOpacity =
        (ringT < 0.55 ? ringT / 0.55 : (1 - (ringT - 0.55) / 0.45)).clamp(
          0.0,
          1.0,
        );
    final loadRing = isLoading ? 0.12 + pulse * 0.18 : 0.0;

    final pad = compact ? 8.0 : 14.0;
    final radius = compact ? 14.0 : 20.0;
    // Mark asset is wide (~2.2:1); pin shell size so Column layout is stable.
    final shellHeight = height + pad * 1.4;
    final shellWidth = shellHeight * 2.35;

    return Opacity(
      opacity: stamp.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, dy),
        child: Transform.rotate(
          angle: rotation,
          child: Transform.scale(
            scale: scale * breathScale * loadScale,
            child: SizedBox(
              width: shellWidth,
              height: shellHeight,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Expanding seal ring (brass on lagoon).
                  Transform.scale(
                    scale: ringScale + pulse * 0.06,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(radius + 6),
                        border: Border.all(
                          color: brand.brass.withValues(
                            alpha: 0.22 * ringOpacity + loadRing,
                          ),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: brand.brass.withValues(
                              alpha: 0.18 * ringOpacity + loadRing * 0.5,
                            ),
                            blurRadius: 22 + pulse * 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  // Double-bezel tray holding the mark.
                  Padding(
                    padding: EdgeInsets.all(compact ? 2 : 3),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(radius),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.14),
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(pad * 0.35),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(radius - 4),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: pad * 0.55,
                                vertical: pad * 0.3,
                              ),
                              child: AnimatedBrandLogo(
                                height: height,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Micro trust signals under the brand copy — not KPI vanity, just presence.
class _BrandSignals extends StatelessWidget {
  const _BrandSignals();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = const [
      ('Masters', 'Catalog ready'),
      ('Ledgers', 'Balanced books'),
      ('Vouchers', 'Day open'),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final item in items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  item.$1,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  item.$2,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Form card — double-bezel architecture
// ─────────────────────────────────────────────────────────────────────────────

/// Outer shell + inner core — machined hardware, not a flat Material card.
class _DoubleBezelCard extends StatelessWidget {
  const _DoubleBezelCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final brand = tokens.brand;
    const outerRadius = 28.0;
    const inset = 6.0;
    const innerRadius = outerRadius - inset;

    return Container(
      decoration: BoxDecoration(
        color: brand.mist.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(outerRadius),
        border: Border.all(color: brand.ink.withValues(alpha: 0.04)),
        boxShadow: [
          // Soft ambient pool — never a harsh drop shadow.
          BoxShadow(
            color: brand.ink.withValues(alpha: 0.06),
            blurRadius: 40,
            offset: const Offset(0, 18),
            spreadRadius: -8,
          ),
          BoxShadow(
            color: brand.lagoon.withValues(alpha: 0.05),
            blurRadius: 48,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(inset),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: brand.paper,
          borderRadius: BorderRadius.circular(innerRadius),
          border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
          // Inner top highlight — light catching the paper edge.
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.55),
              blurRadius: 0,
              offset: const Offset(0, 1),
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(innerRadius),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              tokens.spacing.xl,
              tokens.spacing.xl,
              tokens.spacing.xl,
              tokens.spacing.xl + 4,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Form
// ─────────────────────────────────────────────────────────────────────────────

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.formKey,
    required this.usernameController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.isLoading,
    required this.fieldErrors,
    required this.onSubmit,
    required this.stagger,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final bool isLoading;
  final Map<String, String> fieldErrors;
  final VoidCallback onSubmit;
  final Animation<double> Function(double begin, double end) stagger;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final brand = tokens.brand;
    final theme = Theme.of(context);
    final isMobile = context.isMobile;

    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Eyebrow + title block
          _Reveal(
            animation: stagger(0.28, 0.72),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMobile) ...[
                  const _EyebrowPill(label: 'Welcome back'),
                  SizedBox(height: tokens.spacing.md),
                ],
                Text(
                  context.l10n.appTitle,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                    height: 1.15,
                  ),
                ),
                SizedBox(height: tokens.spacing.sm),
                Text(
                  'Sign in to your desk',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: brand.inkMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: tokens.spacing.xl + 4),

          // Username
          _Reveal(
            animation: stagger(0.36, 0.82),
            child: _PremiumField(
              controller: usernameController,
              enabled: !isLoading,
              label: 'Username',
              hint: 'Your clerk id',
              icon: Icons.person_outline_rounded,
              autofillHints: const [AutofillHints.username],
              textInputAction: TextInputAction.next,
              errorText: fieldErrors['username'],
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Username is required'
                  : null,
            ),
          ),
          SizedBox(height: tokens.spacing.md),

          // Password
          _Reveal(
            animation: stagger(0.42, 0.88),
            child: _PremiumField(
              controller: passwordController,
              enabled: !isLoading,
              label: 'Password',
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              obscureText: obscurePassword,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => isLoading ? null : onSubmit(),
              errorText: fieldErrors['password'],
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Password is required'
                  : null,
              suffix: _IconGhostButton(
                tooltip: obscurePassword ? 'Show password' : 'Hide password',
                onPressed: onToggleObscure,
                icon: obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
          SizedBox(height: tokens.spacing.xl + 4),

          // CTA — island pill with nested trailing glyph
          _Reveal(
            animation: stagger(0.5, 0.95),
            child: _SignInButton(isLoading: isLoading, onPressed: onSubmit),
          ),
        ],
      ),
    );
  }
}

/// Quiet, paper-true field — hairline border, lagoon focus rim, light icons.
class _PremiumField extends StatelessWidget {
  const _PremiumField({
    required this.controller,
    required this.enabled,
    required this.label,
    required this.hint,
    required this.icon,
    required this.autofillHints,
    required this.textInputAction,
    required this.validator,
    this.obscureText = false,
    this.errorText,
    this.onFieldSubmitted,
    this.suffix,
  });

  final TextEditingController controller;
  final bool enabled;
  final String label;
  final String hint;
  final IconData icon;
  final Iterable<String> autofillHints;
  final TextInputAction textInputAction;
  final String? Function(String?) validator;
  final bool obscureText;
  final String? errorText;
  final void Function(String)? onFieldSubmitted;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final brand = tokens.brand;

    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      autofillHints: autofillHints,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      style: Theme.of(context).textTheme.bodyLarge,
      cursorColor: brand.lagoon,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        filled: true,
        fillColor: brand.linen.withValues(alpha: 0.55),
        prefixIcon: Icon(icon, size: 20, color: brand.inkMuted),
        suffixIcon: suffix,
        contentPadding: EdgeInsets.symmetric(
          horizontal: tokens.spacing.md,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: brand.mist),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: brand.ink.withValues(alpha: 0.06)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: brand.lagoon, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: brand.oxblood),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: brand.oxblood, width: 1.5),
        ),
        labelStyle: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: brand.inkMuted),
        floatingLabelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: brand.lagoon,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _IconGhostButton extends StatelessWidget {
  const _IconGhostButton({
    required this.onPressed,
    required this.icon,
    required this.tooltip,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final brand = context.tokens.brand;
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: 20, color: brand.inkMuted),
      splashRadius: 20,
    );
  }
}

/// Primary CTA — full pill, lagoon seal, nested trailing arrow island.
class _SignInButton extends StatefulWidget {
  const _SignInButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  State<_SignInButton> createState() => _SignInButtonState();
}

class _SignInButtonState extends State<_SignInButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final brand = context.tokens.brand;
    final theme = Theme.of(context);
    final scale = _pressed ? 0.98 : (_hovered ? 1.01 : 1.0);

    return Semantics(
      button: true,
      enabled: !widget.isLoading,
      label: 'Sign in',
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() {
          _hovered = false;
          _pressed = false;
        }),
        child: FocusableActionDetector(
          enabled: !widget.isLoading,
          onShowHoverHighlight: (v) => setState(() => _hovered = v),
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                if (!widget.isLoading) widget.onPressed();
                return null;
              },
            ),
          },
          child: GestureDetector(
            onTapDown: widget.isLoading
                ? null
                : (_) {
                    setState(() => _pressed = true);
                    HapticFeedback.lightImpact();
                  },
            onTapUp: widget.isLoading
                ? null
                : (_) {
                    setState(() => _pressed = false);
                    widget.onPressed();
                  },
            onTapCancel: () => setState(() => _pressed = false),
            child: AnimatedScale(
              scale: scale,
              duration: MotionTokens.hoverPress,
              curve: _loginEntrance,
              child: AnimatedContainer(
                duration: MotionTokens.standard,
                curve: _loginEntrance,
                height: 52,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: widget.isLoading
                      ? brand.lagoon.withValues(alpha: 0.7)
                      : brand.lagoon,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: brand.lagoon.withValues(
                        alpha: _hovered ? 0.35 : 0.22,
                      ),
                      blurRadius: _hovered ? 28 : 18,
                      offset: Offset(0, _hovered ? 10 : 8),
                      spreadRadius: -4,
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(22, 0, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: widget.isLoading
                          ? Center(
                              child: SizedBox.square(
                                dimension: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : Text(
                              'Sign in',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                    ),
                    if (!widget.isLoading)
                      AnimatedSlide(
                        duration: MotionTokens.standard,
                        curve: _loginEntrance,
                        offset: _hovered
                            ? const Offset(0.06, -0.04)
                            : Offset.zero,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: theme.colorScheme.onPrimary.withValues(
                              alpha: 0.95,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Motion primitives
// ─────────────────────────────────────────────────────────────────────────────

/// Fade + rise + soft deblur entrance. Animates only opacity/transform.
class _Reveal extends StatelessWidget {
  const _Reveal({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = animation.value.clamp(0.0, 1.0);
        // Slight upward travel — heavy paper settling onto the desk.
        final dy = (1 - t) * 22;
        final blurSigma = (1 - t) * 6;
        final content = Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, dy), child: child),
        );
        // Skip ImageFilter when settled — blur is expensive on continuous paint.
        if (blurSigma < 0.4) return content;
        return ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: content,
        );
      },
      child: child,
    );
  }
}

class _FadeSlide extends StatelessWidget {
  const _FadeSlide({required this.progress, required this.child});

  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = progress.clamp(0.0, 1.0);
    return Opacity(
      opacity: t,
      child: Transform.translate(offset: Offset(0, (1 - t) * 18), child: child),
    );
  }
}

/// Microscopic pill badge — editorial eyebrow.
class _EyebrowPill extends StatelessWidget {
  const _EyebrowPill({required this.label, this.lightOnDark = false});

  final String label;
  final bool lightOnDark;

  @override
  Widget build(BuildContext context) {
    final brand = context.tokens.brand;
    final fg = lightOnDark ? Colors.white.withValues(alpha: 0.9) : brand.lagoon;
    final bg = lightOnDark
        ? Colors.white.withValues(alpha: 0.1)
        : brand.lagoonSoft;
    final border = lightOnDark
        ? Colors.white.withValues(alpha: 0.14)
        : brand.lagoon.withValues(alpha: 0.18);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: fg,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.18 * 10,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Painters
// ─────────────────────────────────────────────────────────────────────────────

class _AmbientOrbsPainter extends CustomPainter {
  const _AmbientOrbsPainter({
    required this.breath,
    required this.lagoon,
    required this.brass,
  });

  final double breath;
  final Color lagoon;
  final Color brass;

  @override
  void paint(Canvas canvas, Size size) {
    // Orb A — large lagoon glow, upper right, drifts slowly.
    final aCenter = Offset(
      size.width * (0.78 + breath * 0.03),
      size.height * (0.22 - breath * 0.02),
    );
    final aRadius = size.shortestSide * (0.42 + breath * 0.03);
    canvas.drawCircle(
      aCenter,
      aRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.14 + breath * 0.04),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: aCenter, radius: aRadius)),
    );

    // Orb B — brass warmth, lower left — the "desk lamp" memory.
    final bCenter = Offset(
      size.width * (0.18 - breath * 0.02),
      size.height * (0.72 + breath * 0.03),
    );
    final bRadius = size.shortestSide * (0.34 + breath * 0.02);
    canvas.drawCircle(
      bCenter,
      bRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            brass.withValues(alpha: 0.16 + breath * 0.05),
            brass.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: bCenter, radius: bRadius)),
    );

    // Orb C — soft white bloom near logo zone.
    final cCenter = Offset(
      size.width * 0.35,
      size.height * (0.38 + breath * 0.015),
    );
    final cRadius = size.shortestSide * 0.22;
    canvas.drawCircle(
      cCenter,
      cRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.07),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: cCenter, radius: cRadius)),
    );
  }

  @override
  bool shouldRepaint(covariant _AmbientOrbsPainter oldDelegate) =>
      oldDelegate.breath != breath ||
      oldDelegate.lagoon != lagoon ||
      oldDelegate.brass != brass;
}

class _LedgerLinesPainter extends CustomPainter {
  const _LedgerLinesPainter({required this.color, required this.phase});

  final Color color;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const step = 30.0;
    // Subtle phase shift so the rules feel alive, not static wallpaper.
    final offsetY = phase * 6;
    for (var y = step + offsetY; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LedgerLinesPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.phase != phase;
}

/// Fixed film-grain veil — physical paper feel. Pointer-transparent.
class _FilmGrainOverlay extends StatelessWidget {
  const _FilmGrainOverlay();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GrainPainter(
        color: context.tokens.brand.ink.withValues(alpha: 0.028),
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  const _GrainPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    // Deterministic sparse grain — not true noise (cheap, stable, no asset).
    const cell = 3.0;
    final cols = (size.width / cell).ceil();
    final rows = (size.height / cell).ceil();
    for (var r = 0; r < rows; r += 2) {
      for (var c = 0; c < cols; c += 2) {
        // Cheap hash — scatter ~12% of cells.
        final h = _hash(c, r);
        if (h % 8 != 0) continue;
        final dx = (h % 3) * 0.4;
        final dy = ((h ~/ 3) % 3) * 0.4;
        canvas.drawRect(
          Rect.fromLTWH(c * cell + dx, r * cell + dy, 1.1, 1.1),
          paint,
        );
      }
    }
  }

  int _hash(int x, int y) {
    // Integer hash — stable across frames.
    var n = x * 374761393 + y * 668265263;
    n = (n ^ (n >> 13)) * 1274126177;
    return n & 0x7fffffff;
  }

  @override
  bool shouldRepaint(covariant _GrainPainter oldDelegate) =>
      oldDelegate.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

double _slice(double t, double begin, double end) {
  if (t <= begin) return 0;
  if (t >= end) return 1;
  final local = (t - begin) / (end - begin);
  return _loginEntrance.transform(local.clamp(0.0, 1.0));
}
