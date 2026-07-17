import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:algo_erp_front/core/auth/permission_gate.dart';
import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/bloc/crud_contract.dart';
import 'package:algo_erp_front/core/export/export_button.dart';
import 'package:algo_erp_front/core/export/export_cubit.dart';
import 'package:algo_erp_front/core/manifest/entity_manifest.dart';
import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/core/widgets/data_display/adaptive_entity_list.dart';
import 'package:algo_erp_front/core/widgets/filters/filter_bar.dart';
import 'package:algo_erp_front/core/widgets/layout/page_header.dart';
import 'package:algo_erp_front/core/widgets/layout/work_sheet.dart';
import 'package:algo_erp_front/core/widgets/shortcuts/create_new_shortcuts.dart';
import 'package:algo_erp_front/core/widgets/states/empty_state.dart';
import 'package:algo_erp_front/core/widgets/states/error_state.dart';
import 'package:algo_erp_front/core/widgets/states/ledger_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Renders a manifest's list view as a **ledger sheet**: a page header naming
/// the entity and carrying the create action, above one sheet of paper that
/// fills the canvas and holds the search, the filters, and the rows.
///
/// The create action lives on the header, not next to the search field.
/// Creating a record is a page action; searching filters the sheet. Keeping
/// them on separate bands is the whole point of the two-band layout — see
/// `PageHeader` and `WorkSheet`.
///
/// Owns the page title, so feature pages are just
/// `AdaptiveLayout(child: MasterListSurface(...))` — they don't render a title
/// of their own.
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

  String get _createLabel => 'New ${manifest.label.toLowerCase()}';

  @override
  Widget build(BuildContext context) {
    // Export walks the list's own repository with the list's own query, so it
    // is bound here off the CrudBloc rather than asking every feature page to
    // wire a second binding.
    return BlocProvider<ExportCubit<E>>(
      create: (context) => ExportCubit<E>(
        source: context.read<CrudBloc<E, int, void>>().repository.list,
      ),
      child: Builder(builder: _buildSheet),
    );
  }

  Widget _buildSheet(BuildContext context) {
    final tokens = context.tokens;

    return CreateNewShortcuts(
      module: manifest.rbacModule,
      onCreate: onCreate,
      child: BlocBuilder<CrudBloc<E, int, void>, CrudState<E>>(
        builder: (context, state) {
          final loaded = state is CrudLoaded<E> ? state : null;
          final total = loaded?.meta.total;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                eyebrow: manifest.eyebrowText,
                title: manifest.label,
                subtitle: switch (total) {
                  null => null,
                  1 => '1 record',
                  final count => '$count records',
                },
                actions: [
                  PermissionGate(
                    module: manifest.rbacModule,
                    action: PermissionAction.create,
                    child: Tooltip(
                      message:
                          '$_createLabel (${CreateNewShortcuts.shortcutLabel})',
                      child: FilledButton.icon(
                        onPressed: onCreate,
                        icon: const Icon(Icons.add),
                        label: Text(_createLabel),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: tokens.spacing.lg),
              Expanded(
                child: WorkSheet(
                  toolbar: FilterBar(
                    searchHint: 'Search ${manifest.label.toLowerCase()}',
                    onSearchChanged: (query) => context
                        .read<CrudBloc<E, int, void>>()
                        .add(CrudSearchChanged<E, void>(query)),
                    trailing: [
                      if (manifest.supportsExport)
                        ExportButton<E>.fromManifest(
                          manifest: manifest,
                          query: () =>
                              context.read<CrudBloc<E, int, void>>().query,
                        ),
                    ],
                  ),
                  child: _sheetBody(context, state),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// The sheet's contents for whichever state the list is in. Deliberately not
  /// `AsyncStateView`: the ledger's own skeleton holds the sheet's shape on
  /// first load, where a centered spinner would leave it an empty box.
  Widget _sheetBody(BuildContext context, CrudState<E> state) {
    void reload() =>
        context.read<CrudBloc<E, int, void>>().add(const CrudLoadRequested());

    return switch (state) {
      CrudInitial<E>() ||
      CrudLoading<E>() => LedgerSkeleton(columns: manifest.listColumns.length),
      CrudError<E>(:final failure) => ErrorState(
        failure: failure,
        onRetry: reload,
      ),
      CrudLoaded<E>(:final items) when items.isEmpty => EmptyState(
        message:
            manifest.emptyMessage ?? 'No ${manifest.label.toLowerCase()} yet.',
        actionLabel: manifest.emptyCtaLabel ?? _createLabel,
        onAction: onCreate,
      ),
      final CrudLoaded<E> loaded => _ledger(context, loaded),
    };
  }

  Widget _ledger(BuildContext context, CrudLoaded<E> loaded) {
    final tokens = context.tokens;
    final bloc = context.read<CrudBloc<E, int, void>>();

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        final nearBottom =
            notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 200;
        if (nearBottom && loaded.hasMore && !loaded.isLoadingMore) {
          bloc.add(const CrudLoadMoreRequested());
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () async => bloc.add(const CrudRefreshRequested()),
        child: AdaptiveEntityList<E>(
          items: loaded.items,
          keyOf: idOf,
          onTap: onTap,
          footer: loaded.isLoadingMore
              ? Padding(
                  padding: EdgeInsets.all(tokens.spacing.md),
                  child: const Center(child: CircularProgressIndicator()),
                )
              : null,
          columns: [
            for (final field in manifest.listColumns)
              EntityColumn<E>(
                label: field.label,
                flex: field.flex,
                minWidth: field.minWidth,
                align: field.align,
                mono: field.mono,
                primary: field.primary,
                cellBuilder: (context, item) => Text(field.cellValue(item)),
              ),
          ],
        ),
      ),
    );
  }
}
