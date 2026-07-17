import 'package:algo_erp_front/core/reports/report_catalog.dart';
import 'package:algo_erp_front/core/reports/report_definition.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/theme/app_tokens.dart';
import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/core/widgets/layout/page_header.dart';
import 'package:algo_erp_front/core/widgets/layout/work_sheet.dart';
import 'package:algo_erp_front/features/reports/bloc/reports_hub_bloc.dart';
import 'package:algo_erp_front/features/reports/bloc/reports_hub_event.dart';
import 'package:algo_erp_front/features/reports/bloc/reports_hub_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Categorized catalog of stamped report definitions in a grid layout powered by flutter_bloc.
class ReportsHubPage extends StatelessWidget {
  const ReportsHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ReportsHubBloc>(
      create: (_) => ReportsHubBloc()..add(const ReportsHubInitialized()),
      child: const _ReportsHubView(),
    );
  }
}

class _ReportsHubView extends StatefulWidget {
  const _ReportsHubView();

  @override
  State<_ReportsHubView> createState() => _ReportsHubViewState();
}

class _ReportsHubViewState extends State<_ReportsHubView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _categoryIcon(ReportCategory cat) {
    switch (cat) {
      case ReportCategory.sales:
        return Icons.trending_up_rounded;
      case ReportCategory.purchase:
        return Icons.shopping_cart_outlined;
      case ReportCategory.inventory:
        return Icons.inventory_2_outlined;
      case ReportCategory.financial:
        return Icons.account_balance_outlined;
      case ReportCategory.payroll:
        return Icons.badge_outlined;
      case ReportCategory.manufacturing:
        return Icons.precision_manufacturing_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final brand = tokens.brand;

    return DecoratedBox(
      decoration: BoxDecoration(gradient: tokens.gradient.canvasGradient),
      child: AdaptiveLayout(
        child: BlocBuilder<ReportsHubBloc, ReportsHubState>(
          builder: (context, state) {
            final bloc = context.read<ReportsHubBloc>();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PageHeader(
                  eyebrow: 'Reports',
                  title: 'Reports Hub',
                  subtitle:
                      'Registers, stock, VAT, financial statements, and analytics',
                ),
                SizedBox(height: tokens.spacing.md),
                Expanded(
                  child: WorkSheet(
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(tokens.spacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Search bar & category chips
                                _buildFilterSection(
                                  context,
                                  brand,
                                  tokens,
                                  state,
                                  bloc,
                                ),
                                SizedBox(height: tokens.spacing.lg),
                                if (state.reports.isEmpty)
                                  _buildEmptyState(context, brand, tokens),
                              ],
                            ),
                          ),
                        ),
                        for (final category in state.activeCategories) ...[
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: tokens.spacing.md,
                              ),
                              child: _CategorySectionHeader(
                                category: category,
                                icon: _categoryIcon(category),
                                count: state
                                    .reportsForCategory(category)
                                    .length,
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: EdgeInsets.all(tokens.spacing.md),
                            sliver: _ReportGrid(
                              reports: state.reportsForCategory(category),
                              categoryIcon: _categoryIcon(category),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: SizedBox(height: tokens.spacing.sm),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterSection(
    BuildContext context,
    BrandColors brand,
    AppTokens tokens,
    ReportsHubState state,
    ReportsHubBloc bloc,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search TextField
        TextField(
          controller: _searchController,
          onChanged: (val) => bloc.add(ReportsHubSearchChanged(val)),
          decoration: InputDecoration(
            hintText: 'Search reports by title, module, or endpoint...',
            prefixIcon: Icon(Icons.search_rounded, color: brand.inkMuted),
            suffixIcon: state.searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: brand.inkMuted),
                    onPressed: () {
                      _searchController.clear();
                      bloc.add(const ReportsHubSearchChanged(''));
                    },
                  )
                : null,
            filled: true,
            fillColor: brand.paper,
            contentPadding: EdgeInsets.symmetric(
              horizontal: tokens.spacing.md,
              vertical: tokens.spacing.sm,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(tokens.radii.md),
              borderSide: BorderSide(color: brand.mist),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(tokens.radii.md),
              borderSide: BorderSide(color: brand.mist),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(tokens.radii.md),
              borderSide: BorderSide(color: brand.lagoon, width: 1.5),
            ),
          ),
        ),
        SizedBox(height: tokens.spacing.sm),
        // Category Chips Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                selected: state.selectedCategory == null,
                label: Text('All (${ReportCatalog.all.length})'),
                onSelected: (_) =>
                    bloc.add(const ReportsHubCategorySelected(null)),
                selectedColor: brand.lagoonSoft,
                checkmarkColor: brand.lagoon,
                labelStyle: TextStyle(
                  color: state.selectedCategory == null
                      ? brand.lagoon
                      : brand.ink,
                  fontWeight: state.selectedCategory == null
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              SizedBox(width: tokens.spacing.xs),
              for (final cat in ReportCategory.values) ...[
                Builder(
                  builder: (context) {
                    final count = ReportCatalog.all
                        .where((r) => r.category == cat)
                        .length;
                    final isSelected = state.selectedCategory == cat;
                    return Padding(
                      padding: EdgeInsets.only(right: tokens.spacing.xs),
                      child: FilterChip(
                        selected: isSelected,
                        avatar: Icon(
                          _categoryIcon(cat),
                          size: 16,
                          color: isSelected ? brand.lagoon : brand.inkMuted,
                        ),
                        label: Text('${cat.displayName} ($count)'),
                        onSelected: (_) => bloc.add(
                          ReportsHubCategorySelected(isSelected ? null : cat),
                        ),
                        selectedColor: brand.lagoonSoft,
                        checkmarkColor: brand.lagoon,
                        labelStyle: TextStyle(
                          color: isSelected ? brand.lagoon : brand.ink,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    BrandColors brand,
    AppTokens tokens,
  ) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: tokens.spacing.xxl),
        child: Column(
          children: [
            Icon(Icons.find_in_page_outlined, size: 48, color: brand.inkMuted),
            SizedBox(height: tokens.spacing.sm),
            Text(
              'No matching reports found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: brand.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: tokens.spacing.xs),
            Text(
              'Try searching with a different keyword or '
              'select another category.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: brand.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySectionHeader extends StatelessWidget {
  const _CategorySectionHeader({
    required this.category,
    required this.icon,
    required this.count,
  });

  final ReportCategory category;
  final IconData icon;
  final int count;

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
        border: Border(bottom: BorderSide(color: brand.mist, width: 1.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(tokens.spacing.xs),
            decoration: BoxDecoration(
              color: brand.lagoonSoft,
              borderRadius: BorderRadius.circular(tokens.radii.sm),
            ),
            child: Icon(icon, size: 20, color: brand.lagoon),
          ),
          SizedBox(width: tokens.spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      category.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: brand.ink,
                      ),
                    ),
                    SizedBox(width: tokens.spacing.xs),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: tokens.spacing.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: brand.mist,
                        borderRadius: BorderRadius.circular(tokens.radii.full),
                      ),
                      child: Text(
                        '$count',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: brand.inkMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  category.description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: brand.inkMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportGrid extends StatelessWidget {
  const _ReportGrid({required this.reports, required this.categoryIcon});

  final List<ReportDefinition> reports;
  final IconData categoryIcon;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.crossAxisExtent;
        final crossAxisCount = width >= 1100
            ? 3
            : width >= 700
            ? 2
            : 1;

        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: tokens.spacing.md,
            crossAxisSpacing: tokens.spacing.md,
            mainAxisExtent: 140,
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            final report = reports[index];
            return _ReportCard(report: report, icon: categoryIcon);
          }, childCount: reports.length),
        );
      },
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report, required this.icon});

  final ReportDefinition report;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final brand = tokens.brand;

    return Material(
      color: brand.paper,
      borderRadius: BorderRadius.circular(tokens.radii.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/reports/${report.id}'),
        hoverColor: brand.lagoonSoft.withValues(alpha: 0.3),
        child: Container(
          padding: EdgeInsets.all(tokens.spacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(tokens.radii.md),
            border: Border.all(color: brand.mist),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(tokens.spacing.xs),
                    decoration: BoxDecoration(
                      color: brand.lagoonSoft,
                      borderRadius: BorderRadius.circular(tokens.radii.sm),
                    ),
                    child: Icon(icon, size: 18, color: brand.lagoon),
                  ),
                  SizedBox(width: tokens.spacing.xs),
                  Expanded(
                    child: Text(
                      report.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: brand.ink,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: brand.inkMuted,
                  ),
                ],
              ),
              Text(
                report.endpoint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: brand.inkMuted,
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
              ),
              Wrap(
                spacing: tokens.spacing.xs,
                runSpacing: tokens.spacing.xxs,
                children: [
                  if (report.requiredModule != null)
                    _Badge(
                      label: report.requiredModule!,
                      color: brand.mist,
                      textColor: brand.inkMuted,
                    ),
                  if (report.params.isNotEmpty)
                    _Badge(
                      label: '${report.params.length} filters',
                      color: brand.mist,
                      textColor: brand.inkMuted,
                    ),
                  if (report.autoRun)
                    _Badge(
                      label: 'Auto-run',
                      color: brand.lagoonSoft,
                      textColor: brand.lagoon,
                    ),
                  if (report.supportsExport)
                    _Badge(
                      label: 'Excel',
                      color: brand.mist,
                      textColor: brand.inkMuted,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
