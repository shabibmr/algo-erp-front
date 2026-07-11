import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:algo_erp_front/core/auth/permission_gate.dart';
import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/bloc/crud_contract.dart';
import 'package:algo_erp_front/core/manifest/entity_manifest.dart';
import 'package:algo_erp_front/core/utils/csv_exporter.dart';
import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/core/utils/extensions/view_state_x.dart';
import 'package:algo_erp_front/core/widgets/async_state_view.dart';
import 'package:algo_erp_front/core/widgets/data_display/adaptive_entity_list.dart';
import 'package:algo_erp_front/core/widgets/filters/filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Renders a manifest's list view: search bar, adaptive table/cards built
/// from `manifest.listColumns`, infinite scroll, and an RBAC-gated "New"
/// action — the one Surface every master's list screen shares.
///
/// This is the EMR vertical slice's proving ground. It reuses Track A's
/// `CrudBloc` and Track C's widgets exactly as built; the only new plumbing
/// is the scroll-driven `CrudLoadMoreRequested` dispatch, since
/// `AdaptiveEntityList` takes a plain, already-loaded `List<E>` and has no
/// pagination hook of its own.
class MasterListSurface<E> extends StatelessWidget {
  const MasterListSurface({
    required this.manifest,
    required this.idOf,
    super.key,
    this.onTap,
    this.onCreate,
  });

  final EntityManifest<E> manifest;
  final Object? Function(E entity) idOf;
  final ValueChanged<E>? onTap;
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilterBar(
          searchHint: 'Search ${manifest.label.toLowerCase()}...',
          onSearchChanged: (query) =>
              context.read<CrudBloc<E, int, void>>().add(
                    CrudSearchChanged<E, void>(query),
                  ),
          trailing: [
            if (manifest.supportsExcel) ...[
              BlocBuilder<CrudBloc<E, int, void>, CrudState<E>>(
                builder: (context, state) {
                  final items = state is CrudLoaded<E> ? state.items : <E>[];
                  return IconButton(
                    icon: const Icon(Icons.download),
                    tooltip: 'Export to Excel (CSV)',
                    onPressed: items.isEmpty
                        ? null
                        : () {
                            final headers =
                                manifest.listColumns.map((c) => c.label).toList();
                            final rows = items.map((item) {
                              return manifest.listColumns
                                  .map((c) => c.cellValue(item))
                                  .toList();
                            }).toList();
                            CsvExporter.exportToCsv(
                              filename: '${manifest.id}_export.csv',
                              headers: headers,
                              rows: rows,
                            );
                          },
                  );
                },
              ),
              SizedBox(width: tokens.spacing.sm),
            ],
            PermissionGate(
              module: manifest.rbacModule,
              action: PermissionAction.create,
              child: FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: Text('New ${manifest.label}'),
              ),
            ),
          ],
        ),
        SizedBox(height: tokens.spacing.md),
        Expanded(
          child: BlocBuilder<CrudBloc<E, int, void>, CrudState<E>>(
            builder: (context, state) {
              final hasMore = state is CrudLoaded<E> && state.hasMore;
              final isLoadingMore =
                  state is CrudLoaded<E> && state.isLoadingMore;
              return NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  final nearBottom = notification.metrics.pixels >=
                      notification.metrics.maxScrollExtent - 200;
                  if (nearBottom && hasMore && !isLoadingMore) {
                    context
                        .read<CrudBloc<E, int, void>>()
                        .add(const CrudLoadMoreRequested());
                  }
                  return false;
                },
                child: RefreshIndicator(
                  onRefresh: () async => context
                      .read<CrudBloc<E, int, void>>()
                      .add(const CrudRefreshRequested()),
                  child: AsyncStateView<List<E>>(
                    state: state.toViewState(),
                    emptyMessage: 'No ${manifest.label.toLowerCase()} yet.',
                    onRetry: () => context
                        .read<CrudBloc<E, int, void>>()
                        .add(const CrudLoadRequested()),
                    builder: (context, items) => SingleChildScrollView(
                      child: Column(
                        children: [
                          AdaptiveEntityList<E>(
                            items: items,
                            keyOf: idOf,
                            onTap: onTap,
                            columns: [
                              for (final field in manifest.listColumns)
                                EntityColumn<E>(
                                  label: field.label,
                                  cellBuilder: (context, item) =>
                                      Text(field.cellValue(item)),
                                ),
                            ],
                            cardBuilder: (context, item) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final field in manifest.listColumns)
                                  Padding(
                                    padding: EdgeInsets.only(
                                      bottom: tokens.spacing.xs,
                                    ),
                                    child: Text(
                                      '${field.label}: '
                                      '${field.cellValue(item)}',
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (isLoadingMore)
                            Padding(
                              padding: EdgeInsets.all(tokens.spacing.md),
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
