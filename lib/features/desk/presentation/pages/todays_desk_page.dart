import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/core/utils/extensions/format_x.dart';
import 'package:algo_erp_front/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:algo_erp_front/features/desk/data/desk_repository.dart';
import 'package:algo_erp_front/features/desk/domain/desk_alerts.dart';
import 'package:algo_erp_front/features/desk/presentation/cubit/desk_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Home surface — personal desk with live alerts + quiet period pulse.
class TodaysDeskPage extends StatelessWidget {
  const TodaysDeskPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          DeskCubit(createDeskRepository(getIt<DioClient>()))..load(),
      child: const _DeskBody(),
    );
  }
}

class _DeskBody extends StatelessWidget {
  const _DeskBody();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final brand = tokens.brand;

    return ColoredBox(
      color: brand.linen,
      child: AdaptiveLayout(
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            final name = authState is AuthAuthenticated
                ? authState.user.username
                : null;
            return RefreshIndicator(
              onRefresh: () => context.read<DeskCubit>().load(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Greeting(name: name),
                    SizedBox(height: tokens.spacing.xl),
                    BlocBuilder<DeskCubit, DeskState>(
                      builder: (context, desk) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _NeedsYouSection(state: desk),
                            SizedBox(height: tokens.spacing.xl),
                            const _ContinueSection(),
                            SizedBox(height: tokens.spacing.xl),
                            _QuietPulseSection(state: desk),
                          ],
                        );
                      },
                    ),
                  ],
                ),
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
  const _NeedsYouSection({required this.state});

  final DeskState state;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final brand = tokens.brand;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Needs you'),
        if (state.loading)
          _PaperCard(
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: brand.lagoon,
                  ),
                ),
                SizedBox(width: tokens.spacing.md),
                Text(
                  'Checking for items that need you…',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: brand.inkMuted),
                ),
              ],
            ),
          )
        else if (state.alertsFailure != null && state.alerts == null)
          _PaperCard(
            child: _InlineFailure(
              failure: state.alertsFailure!,
              onRetry: () => context.read<DeskCubit>().load(),
            ),
          )
        else if (state.alerts == null || state.alerts!.isEmpty)
          _PaperCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.sticky_note_2_outlined,
                  color: brand.brass,
                  size: 28,
                ),
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
                        'Document expiries and overdue bills '
                        'will show up here.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: brand.inkMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          ..._alertCards(context, state.alerts!),
      ],
    );
  }

  List<Widget> _alertCards(BuildContext context, DeskAlerts alerts) {
    final tokens = context.tokens;
    final brand = tokens.brand;
    final cards = <Widget>[];

    for (final doc in alerts.expiringDocuments.take(8)) {
      final days = doc.daysUntilExpiry;
      final when = days == null
          ? ''
          : days <= 0
          ? 'expires today'
          : 'in $days day${days == 1 ? '' : 's'}';
      cards.add(
        Padding(
          padding: EdgeInsets.only(bottom: tokens.spacing.sm),
          child: _PaperCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.badge_outlined, color: brand.oxblood, size: 28),
                SizedBox(width: tokens.spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${doc.docType} · ${doc.employeeName}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      SizedBox(height: tokens.spacing.xxs),
                      Text(
                        [
                          if (doc.employeeCode.isNotEmpty) doc.employeeCode,
                          if (doc.expiryDate != null)
                            'Expires ${doc.expiryDate!.toDayString()}',
                          if (when.isNotEmpty) when,
                        ].join(' · '),
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
        ),
      );
    }

    for (final bill in alerts.overdueBills.take(8)) {
      cards.add(
        Padding(
          padding: EdgeInsets.only(bottom: tokens.spacing.sm),
          child: _PaperCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  color: brand.oxblood,
                  size: 28,
                ),
                SizedBox(width: tokens.spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bill.voucherNo.isNotEmpty
                            ? 'Overdue · ${bill.voucherNo}'
                            : 'Overdue bill',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      SizedBox(height: tokens.spacing.xxs),
                      Text(
                        [
                          if (bill.refNo.isNotEmpty) 'Ref ${bill.refNo}',
                          if (bill.dueDate != null)
                            'Due ${bill.dueDate!.toDayString()}',
                          'AED ${bill.amount.toStringAsFixed(2)}',
                        ].join(' · '),
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
        ),
      );
    }

    if (alerts.totalCount > cards.length) {
      cards.add(
        Text(
          'Showing ${cards.length} of ${alerts.totalCount} items',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: brand.inkMuted),
        ),
      );
    }
    return cards;
  }
}

class _ContinueSection extends StatelessWidget {
  const _ContinueSection();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final brand = tokens.brand;

    final shortcuts = <(String, String, IconData)>[
      (
        'Sales invoices',
        '/transactions/sales-invoices',
        Icons.receipt_outlined,
      ),
      ('Ledgers', '/accounts/ledgers', Icons.menu_book_outlined),
      ('Items', '/inventory/item', Icons.inventory_outlined),
      ('Reports', '/reports', Icons.bar_chart_outlined),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Continue'),
        Wrap(
          spacing: tokens.spacing.sm,
          runSpacing: tokens.spacing.sm,
          children: [
            for (final (label, route, icon) in shortcuts)
              ActionChip(
                avatar: Icon(icon, size: 18, color: brand.lagoon),
                label: Text(label),
                onPressed: () => context.go(route),
                backgroundColor: brand.paper,
                side: BorderSide(color: brand.mist),
              ),
          ],
        ),
      ],
    );
  }
}

class _QuietPulseSection extends StatelessWidget {
  const _QuietPulseSection({required this.state});

  final DeskState state;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final brand = tokens.brand;
    final dash = state.dashboard;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Quiet pulse'),
        if (state.loading)
          _PaperCard(
            child: Text(
              'Loading period counts…',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: brand.inkMuted),
            ),
          )
        else if (state.dashboardFailure != null && dash == null)
          _PaperCard(
            child: _InlineFailure(
              failure: state.dashboardFailure!,
              onRetry: () => context.read<DeskCubit>().load(),
            ),
          )
        else if (dash == null)
          _PaperCard(
            child: Text(
              'No dashboard data for this period.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: brand.inkMuted),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 720;
              final tiles = [
                _PulseTile(
                  label: 'Sales invoices',
                  value: '${dash.salesCount}',
                  hint: 'This month',
                ),
                _PulseTile(
                  label: 'Purchase invoices',
                  value: '${dash.purchaseCount}',
                  hint: 'This month',
                ),
                _PulseTile(
                  label: 'Cash position',
                  value: _money(dash.cashPosition),
                  hint: 'Net movement',
                  brass: true,
                ),
                _PulseTile(
                  label: 'Bank position',
                  value: _money(dash.bankPosition),
                  hint: 'Net movement',
                  brass: true,
                ),
              ];
              if (wide) {
                return Row(
                  children: [
                    for (var i = 0; i < tiles.length; i++) ...[
                      if (i > 0) SizedBox(width: tokens.spacing.sm),
                      Expanded(child: tiles[i]),
                    ],
                  ],
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < tiles.length; i++) ...[
                    if (i > 0) SizedBox(height: tokens.spacing.sm),
                    tiles[i],
                  ],
                ],
              );
            },
          ),
        if (dash != null && dash.topCustomers.isNotEmpty) ...[
          SizedBox(height: tokens.spacing.sm),
          _PaperCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Top customers (by invoice count)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                SizedBox(height: tokens.spacing.sm),
                for (final c in dash.topCustomers)
                  Padding(
                    padding: EdgeInsets.only(bottom: tokens.spacing.xs),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Ledger #${c.voucherLedgerId}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Text(
                          '${c.count}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                                color: brand.inkMuted,
                              ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _money(num value) => 'AED ${value.toStringAsFixed(2)}';
}

class _PulseTile extends StatelessWidget {
  const _PulseTile({
    required this.label,
    required this.value,
    required this.hint,
    this.brass = false,
  });

  final String label;
  final String value;
  final String hint;
  final bool brass;

  @override
  Widget build(BuildContext context) {
    final brand = context.tokens.brand;
    final tokens = context.tokens;
    return _PaperCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: brand.inkMuted),
          ),
          SizedBox(height: tokens.spacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: brass ? brand.brass : brand.ink,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          SizedBox(height: tokens.spacing.xxs),
          Text(
            hint,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: brand.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _InlineFailure extends StatelessWidget {
  const _InlineFailure({required this.failure, required this.onRetry});

  final Failure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final brand = context.tokens.brand;
    final tokens = context.tokens;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.error_outline, color: brand.oxblood, size: 28),
        SizedBox(width: tokens.spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                failure.message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(height: tokens.spacing.sm),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
