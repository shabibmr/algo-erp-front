import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Home surface — personal desk, not a KPI billboard.
///
/// Until report/draft APIs land, **Needs you** and **Continue** show honest
/// empty invitations rather than demo numbers.
class TodaysDeskPage extends StatelessWidget {
  const TodaysDeskPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final brand = tokens.brand;

    return ColoredBox(
      color: brand.linen,
      child: AdaptiveLayout(
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final name = state is AuthAuthenticated
                ? state.user.username
                : null;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Greeting(name: name),
                  SizedBox(height: tokens.spacing.xl),
                  const _NeedsYouSection(),
                  SizedBox(height: tokens.spacing.xl),
                  const _ContinueSection(),
                  SizedBox(height: tokens.spacing.xl),
                  const _QuietPulseSection(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final brand = context.tokens.brand;
    final tokens = context.tokens;
    final hour = DateTime.now().hour;
    final salutation = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    final who = (name != null && name!.isNotEmpty) ? name! : 'there';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$salutation, $who',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: brand.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: tokens.spacing.xs),
        Text(
          "Here's your desk for today.",
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: brand.inkMuted),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final brand = context.tokens.brand;
    return Padding(
      padding: EdgeInsets.only(bottom: context.tokens.spacing.sm),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: brand.ink,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PaperCard extends StatelessWidget {
  const _PaperCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final brand = tokens.brand;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(tokens.radii.lg),
      side: BorderSide(color: brand.mist),
    );

    return Material(
      color: brand.paper,
      elevation: tokens.elevation.level1,
      shadowColor: brand.ink.withValues(alpha: 0.06),
      shape: shape,
      child: Padding(padding: EdgeInsets.all(tokens.spacing.md), child: child),
    );
  }
}

class _NeedsYouSection extends StatelessWidget {
  const _NeedsYouSection();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final brand = tokens.brand;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Needs you'),
        _PaperCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.sticky_note_2_outlined, color: brand.brass, size: 28),
              SizedBox(width: tokens.spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nothing waiting yet',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    SizedBox(height: tokens.spacing.xs),
                    Text(
                      'Drafts, approvals, and credit alerts will land here '
                      'once those reports connect.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: brand.inkMuted),
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

class _ContinueSection extends StatelessWidget {
  const _ContinueSection();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final brand = tokens.brand;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Continue'),
        _PaperCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.history_outlined, color: brand.lagoon, size: 28),
              SizedBox(width: tokens.spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No recent work yet',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    SizedBox(height: tokens.spacing.xs),
                    Text(
                      'Masters and vouchers you open will show up here so '
                      'you can pick up where you left off.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: brand.inkMuted),
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

class _QuietPulseSection extends StatelessWidget {
  const _QuietPulseSection();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final brand = tokens.brand;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Quiet pulse'),
        _PaperCard(
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: brand.mist,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: tokens.spacing.sm),
              Expanded(
                child: Text(
                  'Live counts will appear when they answer '
                  '"what should I do next?" — not as vanity stats.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: brand.inkMuted),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
