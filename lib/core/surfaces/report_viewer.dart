import 'package:algo_erp_front/core/export/export_cubit.dart' show ExportFormat;
import 'package:algo_erp_front/core/manifest/field_spec.dart' show ColumnAlign;
import 'package:algo_erp_front/core/printing/voucher_pdf.dart';
import 'package:algo_erp_front/core/reports/report_definition.dart';
import 'package:algo_erp_front/core/reports/report_json.dart';
import 'package:algo_erp_front/core/reports/report_repository.dart';
import 'package:algo_erp_front/core/surfaces/document_pdf_preview_page.dart';
import 'package:algo_erp_front/core/surfaces/report_viewer_cubit.dart';
import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/core/widgets/data_display/ledger_table.dart';
import 'package:algo_erp_front/core/widgets/fields/app_date_field.dart';
import 'package:algo_erp_front/core/widgets/fields/app_text_field.dart';
import 'package:algo_erp_front/core/widgets/layout/page_header.dart';
import 'package:algo_erp_front/core/widgets/layout/work_sheet.dart';
import 'package:algo_erp_front/core/widgets/states/empty_state.dart';
import 'package:algo_erp_front/core/widgets/states/error_state.dart';
import 'package:algo_erp_front/core/widgets/states/loading_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Filter bar → adaptive table / summary → Excel, CSV and print, for any
/// [ReportDefinition]. State lives in [ReportViewerCubit].
class ReportViewer extends StatelessWidget {
  const ReportViewer({
    required this.definition,
    required this.repository,
    super.key,
  });

  final ReportDefinition definition;
  final ReportRepository repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ReportViewerCubit(definition: definition, repository: repository),
      child: _ReportViewerBody(definition: definition),
    );
  }
}

class _ReportViewerBody extends StatelessWidget {
  const _ReportViewerBody({required this.definition});

  final ReportDefinition definition;

  void _print(BuildContext context, Object? rawData) {
    if (rawData == null) return;
    final table = flattenReport(definition, rawData);
    final rows = [
      for (final row in table.rows)
        [for (final cell in row) formatReportCell(cell)],
    ];

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DocumentPdfPreviewPage(
          title: definition.title,
          pdfBuilder: () => buildTablePdf(
            title: definition.title,
            headers: table.headers,
            rows: rows,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final def = definition;

    return BlocListener<ReportViewerCubit, ReportViewerUiState>(
      listenWhen: (p, c) =>
          p.exportSnack != c.exportSnack && c.exportSnack != null,
      listener: (context, state) {
        final snack = state.exportSnack;
        if (snack == null) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(snack)));
        context.read<ReportViewerCubit>().clearExportSnack();
      },
      child: BlocBuilder<ReportViewerCubit, ReportViewerUiState>(
        builder: (context, state) {
          final cubit = context.read<ReportViewerCubit>();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                eyebrow: def.eyebrow,
                title: def.title,
                actions: [
                  if (state.rawData != null)
                    OutlinedButton.icon(
                      onPressed: () => _print(context, state.rawData),
                      icon: const Icon(Icons.print_outlined, size: 18),
                      label: const Text('Print'),
                    ),
                  if (def.supportsExport && state.rawData != null)
                    OutlinedButton.icon(
                      onPressed: state.exporting
                          ? null
                          : () => cubit.export(ExportFormat.csv),
                      icon: const Icon(Icons.description_outlined, size: 18),
                      label: const Text('CSV'),
                    ),
                  if (def.supportsExport && state.rawData != null)
                    FilledButton.tonalIcon(
                      onPressed: state.exporting
                          ? null
                          : () => cubit.export(ExportFormat.excel),
                      icon: state.exporting
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.table_chart_outlined, size: 18),
                      label: const Text('Excel'),
                    ),
                ],
              ),
              SizedBox(height: tokens.spacing.md),
              if (def.params.isNotEmpty) ...[
                _FilterBar(
                  definition: def,
                  textValues: state.textValues,
                  dateValues: state.dateValues,
                  onTextChanged: cubit.setTextParam,
                  onDateChanged: cubit.setDateParam,
                  onRun: cubit.run,
                  loading: state.isLoading,
                ),
                SizedBox(height: tokens.spacing.md),
              ] else
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FilledButton.icon(
                    onPressed: state.isLoading ? null : cubit.run,
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: Text(state.isLoading ? 'Running…' : 'Run'),
                  ),
                ),
              Expanded(child: _buildBody(context, state, cubit)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ReportViewerUiState state,
    ReportViewerCubit cubit,
  ) {
    final def = definition;
    if (state.isLoading) {
      return const WorkSheet(child: LoadingState(message: 'Running report…'));
    }
    if (state.failure != null) {
      return WorkSheet(
        child: ErrorState(failure: state.failure!, onRetry: cubit.run),
      );
    }
    if (!state.hasRun) {
      return const WorkSheet(
        child: EmptyState(
          message: 'Set filters and run the report.',
          icon: Icons.bar_chart_outlined,
        ),
      );
    }
    if (state.rawData == null) {
      return const WorkSheet(child: EmptyState(message: 'No data returned.'));
    }

    if (def.shape == ReportShape.sections) {
      return _SectionsSheet(definition: def, data: state.rawData!);
    }

    if (def.shape == ReportShape.summary) {
      return _SummarySheet(definition: def, data: state.rawData!);
    }

    final rows = extractReportRows(data: state.rawData, rowsPath: def.rowsPath);
    if (rows.isEmpty) {
      return const WorkSheet(
        child: EmptyState(
          message: 'No rows for these filters.',
          icon: Icons.filter_list_off_outlined,
        ),
      );
    }

    return WorkSheet(
      toolbar: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.tokens.spacing.md,
          vertical: context.tokens.spacing.sm,
        ),
        child: Text(
          '${rows.length} row${rows.length == 1 ? '' : 's'}',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: context.tokens.brand.inkMuted,
          ),
        ),
      ),
      child: LedgerTable<Map<String, dynamic>>(
        items: rows,
        columns: [
          for (final c in def.columns)
            LedgerColumn<Map<String, dynamic>>(
              label: c.label,
              flex: c.flex,
              mono: c.mono,
              primary: c.primary,
              align: c.mono ? ColumnAlign.end : ColumnAlign.start,
              cellBuilder: (context, row) {
                final text = formatReportCell(readJsonPath(row, c.key));
                final style = c.primary
                    ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      )
                    : Theme.of(context).textTheme.bodyMedium;
                return Text(
                  text,
                  style: style,
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.definition,
    required this.textValues,
    required this.dateValues,
    required this.onTextChanged,
    required this.onDateChanged,
    required this.onRun,
    required this.loading,
  });

  final ReportDefinition definition;
  final Map<String, String> textValues;
  final Map<String, DateTime?> dateValues;
  final void Function(String key, String value) onTextChanged;
  final void Function(String key, DateTime? value) onDateChanged;
  final VoidCallback onRun;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return WorkSheet(
      fill: false,
      padding: EdgeInsets.all(tokens.spacing.md),
      child: Wrap(
        spacing: tokens.spacing.md,
        runSpacing: tokens.spacing.md,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          for (final p in definition.params)
            SizedBox(
              width: p.type == ReportParamType.date ? 180 : 220,
              child: switch (p.type) {
                ReportParamType.date => AppDateField(
                  label: p.label,
                  value: dateValues[p.key],
                  onChanged: (d) => onDateChanged(p.key, d),
                ),
                ReportParamType.text ||
                ReportParamType.intField => AppTextField(
                  label: p.label,
                  value: textValues[p.key] ?? '',
                  onChanged: (v) => onTextChanged(p.key, v),
                  keyboardType: p.type == ReportParamType.intField
                      ? TextInputType.number
                      : TextInputType.text,
                ),
              },
            ),
          FilledButton.icon(
            onPressed: loading ? null : onRun,
            icon: const Icon(Icons.play_arrow, size: 18),
            label: Text(loading ? 'Running…' : 'Run'),
          ),
        ],
      ),
    );
  }
}

class _SectionsSheet extends StatelessWidget {
  const _SectionsSheet({required this.definition, required this.data});

  final ReportDefinition definition;
  final Object data;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final map = data is Map<dynamic, dynamic>
        ? Map<String, dynamic>.from(data as Map)
        : <String, dynamic>{};

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final section in definition.sections) ...[
            _SectionBlock(section: section, data: data),
            SizedBox(height: tokens.spacing.md),
          ],
          WorkSheet(
            fill: false,
            title: 'Totals',
            padding: EdgeInsets.all(tokens.spacing.md),
            child: Column(
              children: [
                for (final c in definition.columns)
                  _TotalRow(column: c, value: readJsonPath(map, c.key)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({required this.section, required this.data});

  final ReportSectionSpec section;
  final Object? data;

  @override
  Widget build(BuildContext context) {
    final rows = extractReportRows(data: data, rowsPath: section.rowsPath);
    if (rows.isEmpty) {
      return WorkSheet(
        fill: false,
        title: section.title,
        padding: EdgeInsets.all(context.tokens.spacing.md),
        child: const EmptyState(message: 'No entries.'),
      );
    }
    return WorkSheet(
      fill: false,
      title: section.title,
      child: LedgerTable<Map<String, dynamic>>(
        items: rows,
        columns: [
          for (final c in section.columns)
            LedgerColumn<Map<String, dynamic>>(
              label: c.label,
              flex: c.flex,
              mono: c.mono,
              primary: c.primary,
              align: c.mono ? ColumnAlign.end : ColumnAlign.start,
              cellBuilder: (context, row) => Text(
                formatReportCell(readJsonPath(row, c.key)),
                style: c.primary
                    ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      )
                    : Theme.of(context).textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.column, required this.value});

  final ReportColumnSpec column;
  final Object? value;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.spacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              column.label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: tokens.brand.inkMuted),
            ),
          ),
          Text(
            formatReportCell(value),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontFeatures: column.mono
                  ? const [FontFeature.tabularFigures()]
                  : null,
              color: tokens.brand.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummarySheet extends StatelessWidget {
  const _SummarySheet({required this.definition, required this.data});

  final ReportDefinition definition;
  final Object data;

  @override
  Widget build(BuildContext context) {
    final map = data is Map
        ? Map<String, dynamic>.from(data as Map)
        : <String, dynamic>{};
    final brand = context.tokens.brand;
    final tokens = context.tokens;

    return WorkSheet(
      fill: false,
      padding: EdgeInsets.all(tokens.spacing.md),
      child: Column(
        children: [
          for (final c in definition.columns)
            Padding(
              padding: EdgeInsets.symmetric(vertical: tokens.spacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      c.label,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: brand.inkMuted),
                    ),
                  ),
                  Text(
                    formatReportCell(readJsonPath(map, c.key)),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontFeatures: c.mono
                          ? const [FontFeature.tabularFigures()]
                          : null,
                      color: c.key.contains('vat') || c.key.contains('payable')
                          ? brand.brass
                          : brand.ink,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
