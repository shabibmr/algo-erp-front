import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/export/csv_writer.dart';
import 'package:algo_erp_front/core/export/entity_export.dart';
import 'package:algo_erp_front/core/export/excel_writer.dart';
import 'package:algo_erp_front/core/export/export_cubit.dart';
import 'package:algo_erp_front/core/manifest/entity_manifest.dart';
import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The export control every list wears: a menu offering Excel (the default) and
/// CSV, backed by an [ExportCubit] that gathers **every row matching the
/// current query** rather than the pages that happen to be on screen.
///
/// Requires an `ExportCubit<E>` above it. The cubit gathers; this widget
/// writes — see [ExportCubit] for why the file write lives on the view side.
///
/// Takes columns, not a manifest, because the voucher lists have no manifest —
/// they declare their export columns directly. [ExportButton.fromManifest] is
/// the shorthand for the entities that do have one.
class ExportButton<E> extends StatelessWidget {
  const ExportButton({
    required this.id,
    required this.label,
    required this.columns,
    required this.query,
    super.key,
  });

  /// The columns that have a manifest get their export from it — same columns
  /// the list already renders, so the file matches the screen.
  ExportButton.fromManifest({
    required EntityManifest<E> manifest,
    required this.query,
    super.key,
  }) : id = manifest.id,
       label = manifest.label,
       columns = manifest.listColumns;

  /// Names the file: `<id>_export.xlsx`.
  final String id;

  /// Names the sheet, and the tooltip.
  final String label;

  final List<FieldSpec<E>> columns;

  /// Read at the moment of the tap, not at build: the user's search and filters
  /// have to be whatever they are *when they press export*.
  final PageQuery Function() query;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ExportCubit<E>, ExportState<E>>(
      listener: (context, state) => switch (state) {
        ExportReady<E>() => _write(context, state),
        ExportFailed<E>(:final failure) => _snack(
          context,
          'Export failed: ${failure.message}',
        ),
        ExportIdle<E>() || ExportRunning<E>() => null,
      },
      builder: (context, state) {
        if (state is ExportRunning<E>) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        return PopupMenuButton<ExportFormat>(
          icon: const Icon(Icons.download_outlined),
          tooltip: 'Export ${label.toLowerCase()}',
          onSelected: (format) => context.read<ExportCubit<E>>().run(
            query: query(),
            format: format,
          ),
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: ExportFormat.excel,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.table_chart_outlined),
                title: Text('Excel (.xlsx)'),
              ),
            ),
            PopupMenuItem(
              value: ExportFormat.csv,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.description_outlined),
                title: Text('CSV'),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _write(BuildContext context, ExportReady<E> ready) async {
    // Clear the payload before the first await: the write is async, and a
    // rebuild landing mid-write would otherwise hand us the same file again.
    context.read<ExportCubit<E>>().handled();
    final messenger = ScaffoldMessenger.of(context);

    final headers = EntityExport.headers(columns);
    final rows = EntityExport.rows(columns, ready.items);
    final isExcel = ready.format == ExportFormat.excel;

    final String? path;
    try {
      path = isExcel
          ? await ExcelWriter.write(
              filename: '${id}_export.xlsx',
              sheetName: label,
              headers: headers,
              rows: rows,
            )
          : await CsvWriter.write(
              filename: '${id}_export.csv',
              headers: headers,
              rows: rows,
            );
    } on Object catch (e) {
      // A denied folder or a full disk must not take the list down with it.
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
      return;
    }

    final what = ready.isTruncated
        ? 'the first ${ready.items.length} of ${ready.total} rows — narrow the '
              'filters to export the rest'
        : '${ready.items.length} rows';

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          path == null ? 'Exported $what' : 'Exported $what to $path',
        ),
      ),
    );
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
