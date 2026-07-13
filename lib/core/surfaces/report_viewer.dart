import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/manifest/field_spec.dart' show ColumnAlign;
import 'package:algo_erp_front/core/printing/voucher_pdf.dart';
import 'package:algo_erp_front/core/reports/report_definition.dart';
import 'package:algo_erp_front/core/reports/report_json.dart';
import 'package:algo_erp_front/core/reports/report_repository.dart';
import 'package:algo_erp_front/core/surfaces/document_pdf_preview_page.dart';
import 'package:algo_erp_front/core/utils/csv_exporter.dart';
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

/// Filter bar → adaptive table / summary → CSV export for any [ReportDefinition].
class ReportViewer extends StatefulWidget {
  const ReportViewer({
    required this.definition,
    required this.repository,
    super.key,
  });

  final ReportDefinition definition;
  final ReportRepository repository;

  @override
  State<ReportViewer> createState() => _ReportViewerState();
}

class _ReportViewerState extends State<ReportViewer> {
  late final Map<String, String> _textValues;
  late final Map<String, DateTime?> _dateValues;
  bool _loading = false;
  bool _hasRun = false;
  Failure? _failure;
  Object? _rawData;

  ReportDefinition get def => widget.definition;

  @override
  void initState() {
    super.initState();
    _textValues = {};
    _dateValues = {};
    final now = DateTime.now();
    for (final p in def.params) {
      switch (p.type) {
        case ReportParamType.date:
          if (p.defaultToday) {
            _dateValues[p.key] = DateTime(now.year, now.month, now.day);
          } else if (p.defaultMonthStart) {
            _dateValues[p.key] = DateTime(now.year, now.month);
          } else {
            _dateValues[p.key] = null;
          }
        case ReportParamType.text:
        case ReportParamType.intField:
          if (p.key == 'period') {
            _textValues[p.key] =
                '${now.year}-${now.month.toString().padLeft(2, '0')}';
          } else {
            _textValues[p.key] = '';
          }
      }
    }
    if (def.autoRun) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _run());
    }
  }

  Map<String, String> _buildQuery() {
    final q = <String, String>{};
    for (final p in def.params) {
      switch (p.type) {
        case ReportParamType.date:
          final d = _dateValues[p.key];
          if (d != null) {
            q[p.key] = d.toIso8601String().split('T').first;
          }
        case ReportParamType.text:
        case ReportParamType.intField:
          final v = _textValues[p.key]?.trim() ?? '';
          if (v.isNotEmpty) q[p.key] = v;
      }
    }
    return q;
  }

  String? _validate() {
    for (final p in def.params) {
      if (!p.required) continue;
      switch (p.type) {
        case ReportParamType.date:
          if (_dateValues[p.key] == null) return '${p.label} is required';
        case ReportParamType.text:
        case ReportParamType.intField:
          if ((_textValues[p.key] ?? '').trim().isEmpty) {
            return '${p.label} is required';
          }
      }
    }
    return null;
  }

  Future<void> _run() async {
    final err = _validate();
    if (err != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    setState(() {
      _loading = true;
      _failure = null;
      _hasRun = true;
    });
    final result = await widget.repository.fetch(def, _buildQuery());
    if (!mounted) return;
    result.fold(
      (f) => setState(() {
        _loading = false;
        _failure = f;
        _rawData = null;
      }),
      (data) => setState(() {
        _loading = false;
        _failure = null;
        _rawData = data;
      }),
    );
  }

  Future<void> _exportCsv() async {
    if (_rawData == null) return;

    final List<String> headers;
    final List<List<String>> rows;

    if (def.shape == ReportShape.sections) {
      final table = flattenReportSections(
        data: _rawData,
        sections: def.sections,
        totals: def.columns,
      );
      headers = table.headers;
      rows = table.rows;
    } else if (def.shape == ReportShape.summary) {
      final map = _rawData is Map
          ? Map<String, dynamic>.from(_rawData! as Map)
          : <String, dynamic>{};
      headers = def.columns.map((c) => c.label).toList();
      rows = [
        [
          for (final c in def.columns)
            formatReportCell(readJsonPath(map, c.key)),
        ],
      ];
    } else {
      headers = def.columns.map((c) => c.label).toList();
      rows = [
        for (final row in extractReportRows(
          data: _rawData,
          rowsPath: def.rowsPath,
        ))
          [
            for (final c in def.columns)
              formatReportCell(readJsonPath(row, c.key)),
          ],
      ];
    }

    final messenger = ScaffoldMessenger.of(context);
    try {
      // Off the web this writes to disk, so the user needs the path back.
      final path = await CsvExporter.exportToCsv(
        filename: '${def.id}.csv',
        headers: headers,
        rows: rows,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            path == null
                ? 'Exported ${rows.length} rows'
                : 'Exported ${rows.length} rows to $path',
          ),
        ),
      );
    } on Object catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  void _print() {
    if (_rawData == null) return;
    final headers = def.columns.map((c) => c.label).toList();
    final List<List<String>> rows;
    if (def.shape == ReportShape.sections) {
      final table = flattenReportSections(
        data: _rawData,
        sections: def.sections,
        totals: def.columns,
      );
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DocumentPdfPreviewPage(
            title: def.title,
            pdfBuilder: () => buildTablePdf(
              title: def.title,
              headers: table.headers,
              rows: table.rows,
            ),
          ),
        ),
      );
      return;
    }
    if (def.shape == ReportShape.summary) {
      final map = _rawData is Map
          ? Map<String, dynamic>.from(_rawData! as Map)
          : <String, dynamic>{};
      rows = [
        for (final c in def.columns)
          [c.label, formatReportCell(readJsonPath(map, c.key))],
      ];
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DocumentPdfPreviewPage(
            title: def.title,
            pdfBuilder: () => buildTablePdf(
              title: def.title,
              headers: const ['Field', 'Value'],
              rows: rows,
            ),
          ),
        ),
      );
      return;
    }
    final reportRows = extractReportRows(
      data: _rawData,
      rowsPath: def.rowsPath,
    );
    rows = [
      for (final row in reportRows)
        [
          for (final c in def.columns)
            formatReportCell(readJsonPath(row, c.key)),
        ],
    ];
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DocumentPdfPreviewPage(
          title: def.title,
          pdfBuilder: () =>
              buildTablePdf(title: def.title, headers: headers, rows: rows),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          eyebrow: def.eyebrow,
          title: def.title,
          actions: [
            if (_rawData != null)
              OutlinedButton.icon(
                onPressed: _print,
                icon: const Icon(Icons.print_outlined, size: 18),
                label: const Text('Print'),
              ),
            if (def.supportsCsv && _rawData != null)
              FilledButton.tonalIcon(
                onPressed: _exportCsv,
                icon: const Icon(Icons.download_outlined, size: 18),
                label: const Text('CSV'),
              ),
          ],
        ),
        SizedBox(height: tokens.spacing.md),
        if (def.params.isNotEmpty) ...[
          _FilterBar(
            definition: def,
            textValues: _textValues,
            dateValues: _dateValues,
            onTextChanged: (k, v) => setState(() => _textValues[k] = v),
            onDateChanged: (k, v) => setState(() => _dateValues[k] = v),
            onRun: _run,
            loading: _loading,
          ),
          SizedBox(height: tokens.spacing.md),
        ] else
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.icon(
              onPressed: _loading ? null : _run,
              icon: const Icon(Icons.play_arrow, size: 18),
              label: Text(_loading ? 'Running…' : 'Run'),
            ),
          ),
        Expanded(child: _buildBody(context)),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const WorkSheet(child: LoadingState(message: 'Running report…'));
    }
    if (_failure != null) {
      return WorkSheet(
        child: ErrorState(failure: _failure!, onRetry: _run),
      );
    }
    if (!_hasRun) {
      return const WorkSheet(
        child: EmptyState(
          message: 'Set filters and run the report.',
          icon: Icons.bar_chart_outlined,
        ),
      );
    }
    if (_rawData == null) {
      return const WorkSheet(child: EmptyState(message: 'No data returned.'));
    }

    if (def.shape == ReportShape.sections) {
      return _SectionsSheet(definition: def, data: _rawData!);
    }

    if (def.shape == ReportShape.summary) {
      return _SummarySheet(definition: def, data: _rawData!);
    }

    final rows = extractReportRows(data: _rawData, rowsPath: def.rowsPath);
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

/// A financial statement: one sheet per row list, then the totals block.
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
