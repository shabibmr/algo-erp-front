import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/export/csv_writer.dart';
import 'package:algo_erp_front/core/export/entity_export.dart';
import 'package:algo_erp_front/core/export/excel_writer.dart';
import 'package:algo_erp_front/core/export/export_cubit.dart'
    show ExportFormat, kExportRowCap;
import 'package:algo_erp_front/core/reports/report_definition.dart';
import 'package:algo_erp_front/core/reports/report_json.dart';
import 'package:algo_erp_front/core/reports/report_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Carries a repository [Failure] out of the export's re-fetch.
class ReportExportFailure implements Exception {
  const ReportExportFailure(this.message);
  final String message;
}

enum ReportViewerStatus { initial, loading, success, failure }

final class ReportViewerUiState extends Equatable {
  const ReportViewerUiState({
    this.status = ReportViewerStatus.initial,
    this.textValues = const {},
    this.dateValues = const {},
    this.hasRun = false,
    this.rawData,
    this.errorMessage,
    this.failure,
    this.exporting = false,
    this.exportSnack,
  });

  final ReportViewerStatus status;
  final Map<String, String> textValues;
  final Map<String, DateTime?> dateValues;
  final bool hasRun;
  final Object? rawData;
  final String? errorMessage;
  final Failure? failure;
  final bool exporting;

  /// One-shot snackbar payload after export (success or failure message).
  final String? exportSnack;

  bool get isLoading => status == ReportViewerStatus.loading;

  ReportViewerUiState copyWith({
    ReportViewerStatus? status,
    Map<String, String>? textValues,
    Map<String, DateTime?>? dateValues,
    bool? hasRun,
    Object? Function()? rawData,
    String? Function()? errorMessage,
    Failure? Function()? failure,
    bool? exporting,
    String? Function()? exportSnack,
  }) {
    return ReportViewerUiState(
      status: status ?? this.status,
      textValues: textValues ?? this.textValues,
      dateValues: dateValues ?? this.dateValues,
      hasRun: hasRun ?? this.hasRun,
      rawData: rawData != null ? rawData() : this.rawData,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      failure: failure != null ? failure() : this.failure,
      exporting: exporting ?? this.exporting,
      exportSnack: exportSnack != null ? exportSnack() : this.exportSnack,
    );
  }

  @override
  List<Object?> get props => [
    status,
    textValues,
    dateValues,
    hasRun,
    rawData,
    errorMessage,
    failure,
    exporting,
    exportSnack,
  ];
}

/// Filter params + run + export for a single [ReportDefinition].
class ReportViewerCubit extends Cubit<ReportViewerUiState> {
  ReportViewerCubit({required this.definition, required this.repository})
    : super(const ReportViewerUiState()) {
    _initDefaults();
  }

  final ReportDefinition definition;
  final ReportRepository repository;

  void _initDefaults() {
    final now = DateTime.now();
    final textVals = <String, String>{};
    final dateVals = <String, DateTime?>{};

    for (final p in definition.params) {
      switch (p.type) {
        case ReportParamType.date:
          if (p.defaultToday) {
            dateVals[p.key] = DateTime(now.year, now.month, now.day);
          } else if (p.defaultMonthStart) {
            dateVals[p.key] = DateTime(now.year, now.month);
          } else {
            dateVals[p.key] = null;
          }
        case ReportParamType.text:
        case ReportParamType.intField:
          if (p.key == 'period') {
            textVals[p.key] =
                '${now.year}-${now.month.toString().padLeft(2, '0')}';
          } else {
            textVals[p.key] = '';
          }
      }
    }

    emit(state.copyWith(textValues: textVals, dateValues: dateVals));
    if (definition.autoRun) {
      run();
    }
  }

  void setTextParam(String key, String value) {
    final updated = Map<String, String>.from(state.textValues)..[key] = value;
    emit(state.copyWith(textValues: updated));
  }

  void setDateParam(String key, DateTime? value) {
    final updated = Map<String, DateTime?>.from(state.dateValues)
      ..[key] = value;
    emit(state.copyWith(dateValues: updated));
  }

  Map<String, String> _buildQuery() {
    final q = <String, String>{};
    for (final p in definition.params) {
      switch (p.type) {
        case ReportParamType.date:
          final d = state.dateValues[p.key];
          if (d != null) {
            q[p.key] = d.toIso8601String().split('T').first;
          }
        case ReportParamType.text:
        case ReportParamType.intField:
          final v = state.textValues[p.key]?.trim() ?? '';
          if (v.isNotEmpty) q[p.key] = v;
      }
    }
    return q;
  }

  String? _validate() {
    for (final p in definition.params) {
      if (!p.required) continue;
      switch (p.type) {
        case ReportParamType.date:
          if (state.dateValues[p.key] == null) return '${p.label} is required';
        case ReportParamType.text:
        case ReportParamType.intField:
          if ((state.textValues[p.key] ?? '').trim().isEmpty) {
            return '${p.label} is required';
          }
      }
    }
    return null;
  }

  Future<void> run() async {
    final err = _validate();
    if (err != null) {
      // Validation stays a snackbar — do not paint the body as a hard failure.
      emit(state.copyWith(exportSnack: () => err));
      return;
    }

    emit(
      state.copyWith(
        status: ReportViewerStatus.loading,
        hasRun: true,
        rawData: () => null,
        failure: () => null,
        errorMessage: () => null,
      ),
    );

    final result = await repository.fetch(definition, _buildQuery());
    if (isClosed) return;
    result.fold(
      (f) => emit(
        state.copyWith(status: ReportViewerStatus.failure, failure: () => f),
      ),
      (data) => emit(
        state.copyWith(status: ReportViewerStatus.success, rawData: () => data),
      ),
    );
  }

  Future<Object?> _dataForExport() async {
    if (!definition.paginated) return state.rawData;

    final result = await repository.fetch(definition, {
      ..._buildQuery(),
      'page': '1',
      'limit': '$kExportRowCap',
    });
    return result.fold(
      (failure) => throw ReportExportFailure(failure.message),
      (data) => data,
    );
  }

  Future<void> export(ExportFormat format) async {
    if (state.rawData == null || state.exporting) return;
    emit(state.copyWith(exporting: true, exportSnack: () => null));

    try {
      final table = flattenReport(definition, await _dataForExport());
      final rows = [
        for (final row in table.rows)
          [for (final cell in row) EntityExport.reportCell(cell)],
      ];

      final path = format == ExportFormat.excel
          ? await ExcelWriter.write(
              filename: '${definition.id}.xlsx',
              sheetName: definition.title,
              headers: table.headers,
              rows: rows,
            )
          : await CsvWriter.write(
              filename: '${definition.id}.csv',
              headers: table.headers,
              rows: rows,
            );

      if (isClosed) return;
      emit(
        state.copyWith(
          exporting: false,
          exportSnack: () => path == null
              ? 'Exported ${rows.length} rows'
              : 'Exported ${rows.length} rows to $path',
        ),
      );
    } on Object catch (e) {
      if (isClosed) return;
      final message = e is ReportExportFailure ? e.message : '$e';
      emit(
        state.copyWith(
          exporting: false,
          exportSnack: () => 'Export failed: $message',
        ),
      );
    }
  }

  void clearExportSnack() {
    if (state.exportSnack == null) return;
    emit(state.copyWith(exportSnack: () => null));
  }
}
