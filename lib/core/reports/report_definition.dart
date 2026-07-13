import 'package:flutter/foundation.dart';

/// How the report viewer interprets the envelope `data` payload.
enum ReportShape {
  /// `data` is a list of row maps, or a map with [ReportDefinition.rowsPath].
  table,

  /// `data` is a flat map of label→value fields (e.g. VAT return summary).
  summary,
}

enum ReportParamType { date, text, intField }

@immutable
class ReportParamSpec {
  const ReportParamSpec({
    required this.key,
    required this.label,
    required this.type,
    this.required = false,
    this.defaultToday = false,
    this.defaultMonthStart = false,
  });

  final String key;
  final String label;
  final ReportParamType type;
  final bool required;

  /// Seed with today's date (for date params).
  final bool defaultToday;

  /// Seed with first day of current month (for date params).
  final bool defaultMonthStart;
}

@immutable
class ReportColumnSpec {
  const ReportColumnSpec({
    required this.key,
    required this.label,
    this.flex = 1,
    this.mono = false,
    this.primary = false,
  });

  /// Dot-path into a row map, e.g. `sales_invoice_main.Total`.
  final String key;
  final String label;
  final int flex;
  final bool mono;
  final bool primary;
}

/// Declarative report: endpoint, params, columns, CSV flag.
@immutable
class ReportDefinition {
  const ReportDefinition({
    required this.id,
    required this.title,
    required this.endpoint,
    required this.columns,
    this.eyebrow = 'Reports',
    this.requiredModule,
    this.params = const [],
    this.shape = ReportShape.table,
    this.rowsPath,
    this.supportsCsv = true,
    this.autoRun = false,
  });

  final String id;
  final String title;
  final String eyebrow;
  final String endpoint;
  final String? requiredModule;
  final List<ReportParamSpec> params;
  final List<ReportColumnSpec> columns;
  final ReportShape shape;

  /// Optional path to the list inside `data` (`items`, `entries`, …).
  /// Null means `data` itself is the list (table shape only).
  final String? rowsPath;
  final bool supportsCsv;

  /// Run on open without waiting for the user to press Run.
  final bool autoRun;
}
