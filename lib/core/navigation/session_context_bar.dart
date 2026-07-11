import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/features/auth/domain/entities/auth_user.dart';
import 'package:algo_erp_front/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Workplace context chips: company · branch · financial year.
///
/// Names are not on the JWT yet — we show honest ID labels or "Not set"
/// rather than inventing company names. Wired to [AuthBloc] when signed in.
class SessionContextBar extends StatelessWidget {
  const SessionContextBar({super.key, this.compact = false});

  /// Tighter chips for mobile app bars.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (prev, next) =>
          prev.runtimeType != next.runtimeType ||
          (prev is AuthAuthenticated &&
              next is AuthAuthenticated &&
              prev.user != next.user),
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;
        return _ContextChips(user: user, compact: compact);
      },
    );
  }
}

class _ContextChips extends StatelessWidget {
  const _ContextChips({required this.user, required this.compact});

  final AuthUser? user;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final brand = tokens.brand;
    final company = user?.companyId != null
        ? 'Company #${user!.companyId}'
        : 'Company · Not set';
    final branch = user?.branchId != null
        ? 'Branch #${user!.branchId}'
        : 'Branch · Not set';
    // FY is not on the session yet — honest placeholder, not a fake year.
    const fy = 'FY · Not set';

    final chips = [
      _ContextChip(label: company, icon: Icons.apartment_outlined),
      _ContextChip(label: branch, icon: Icons.storefront_outlined),
      const _ContextChip(label: fy, icon: Icons.calendar_today_outlined),
    ];

    if (compact) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < chips.length; i++) ...[
              if (i > 0) SizedBox(width: tokens.spacing.xs),
              chips[i],
            ],
          ],
        ),
      );
    }

    return Wrap(
      spacing: tokens.spacing.sm,
      runSpacing: tokens.spacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Workplace',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: brand.inkMuted,
              ),
        ),
        ...chips,
      ],
    );
  }
}

class _ContextChip extends StatelessWidget {
  const _ContextChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final brand = tokens.brand;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spacing.sm,
        vertical: tokens.spacing.xs,
      ),
      decoration: BoxDecoration(
        color: brand.mist.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(tokens.radii.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: brand.inkMuted),
          SizedBox(width: tokens.spacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: brand.ink,
                ),
          ),
        ],
      ),
    );
  }
}
