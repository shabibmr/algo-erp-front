import 'package:flutter/foundation.dart';

/// Categorization head for grouping reports in catalog and hub views.
enum ReportCategory {
  sales(
    displayName: 'Sales',
    description: 'Sales, Invoices, Orders, Quotes & Commissions',
  ),
  purchase(
    displayName: 'Purchase',
    description: 'Purchases, POs, Vendor Expenses & Lead-times',
  ),
  inventory(
    displayName: 'Inventory',
    description: 'Stock, Valuations, Transfers, Batches & Warehouse',
  ),
  financial(
    displayName: 'Financial & Books',
    description:
        'Trial Balance, Ledger, Day Book, Profit & Loss, VAT & Statements',
  ),
  payroll(
    displayName: 'HR & Payroll',
    description: 'Attendance, Overtime, Payroll, Salary Revisions & Compliance',
  ),
  manufacturing(
    displayName: 'Manufacturing',
    description: 'BOM & Production Costing Analysis',
  );

  const ReportCategory({required this.displayName, required this.description});

  final String displayName;
  final String description;
}

/// How the report viewer interprets the envelope `data` payload.
enum ReportShape {
  /// `data` is a list of row maps, or a map with [ReportDefinition.rowsPath].
  table,

  /// `data` is a flat map of label→value fields (e.g. VAT return summary).
  summary,

  /// `data` holds several parallel row lists plus totals — a financial
  /// statement. [ReportDefinition.sections] names the lists;
  /// [ReportDefinition.columns] is the totals block rendered beneath them.
  sections,
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

/// One titled row list inside a [ReportShape.sections] payload, e.g. the
/// `assets` block of a balance sheet.
@immutable
class ReportSectionSpec {
  const ReportSectionSpec({
    required this.title,
    required this.rowsPath,
    required this.columns,
  });

  final String title;

  /// Dot-path to this section's list inside `data`, e.g. `assets`.
  final String rowsPath;
  final List<ReportColumnSpec> columns;
}

/// Declarative report: endpoint, params, columns, CSV flag.
@immutable
class ReportDefinition {
  const ReportDefinition({
    required this.id,
    required this.title,
    required this.category,
    required this.endpoint,
    required this.columns,
    this.eyebrow = 'Reports',
    this.requiredModule,
    this.params = const [],
    this.shape = ReportShape.table,
    this.rowsPath,
    this.sections = const [],
    this.supportsCsv = true,
    this.autoRun = false,
  });

  final String id;
  final String title;
  final String eyebrow;
  final ReportCategory category;
  final String endpoint;
  final String? requiredModule;
  final List<ReportParamSpec> params;
  final List<ReportColumnSpec> columns;
  final ReportShape shape;

  /// Optional path to the list inside `data` (`items`, `entries`, …).
  /// Null means `data` itself is the list (table shape only).
  final String? rowsPath;

  /// The row lists to render, for [ReportShape.sections] only.
  final List<ReportSectionSpec> sections;
  final bool supportsCsv;

  /// Run on open without waiting for the user to press Run.
  final bool autoRun;
}
