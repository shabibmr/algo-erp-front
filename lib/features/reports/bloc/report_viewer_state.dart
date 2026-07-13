import 'package:algo_erp_front/core/error/failure.dart';
import 'package:equatable/equatable.dart';

enum ReportViewerStatus { initial, loading, success, failure }

final class ReportViewerState extends Equatable {
  const ReportViewerState({
    this.status = ReportViewerStatus.initial,
    this.textValues = const {},
    this.dateValues = const {},
    this.hasRun = false,
    this.rawData,
    this.errorMessage,
    this.failure,
  });

  final ReportViewerStatus status;
  final Map<String, String> textValues;
  final Map<String, DateTime?> dateValues;
  final bool hasRun;
  final Object? rawData;
  final String? errorMessage;
  final Failure? failure;

  bool get isLoading => status == ReportViewerStatus.loading;
  bool get isSuccess => status == ReportViewerStatus.success;
  bool get isFailure => status == ReportViewerStatus.failure;

  ReportViewerState copyWith({
    ReportViewerStatus? status,
    Map<String, String>? textValues,
    Map<String, DateTime?>? dateValues,
    bool? hasRun,
    Object? Function()? rawData,
    String? Function()? errorMessage,
    Failure? Function()? failure,
  }) {
    return ReportViewerState(
      status: status ?? this.status,
      textValues: textValues ?? this.textValues,
      dateValues: dateValues ?? this.dateValues,
      hasRun: hasRun ?? this.hasRun,
      rawData: rawData != null ? rawData() : this.rawData,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      failure: failure != null ? failure() : this.failure,
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
  ];
}
