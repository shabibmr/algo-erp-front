import 'package:equatable/equatable.dart';

sealed class ReportViewerEvent extends Equatable {
  const ReportViewerEvent();

  @override
  List<Object?> get props => [];
}

final class ReportViewerInitialized extends ReportViewerEvent {
  const ReportViewerInitialized();
}

final class ReportViewerParamChanged extends ReportViewerEvent {
  const ReportViewerParamChanged(this.key, this.value);
  final String key;
  final Object? value;

  @override
  List<Object?> get props => [key, value];
}

final class ReportViewerRunRequested extends ReportViewerEvent {
  const ReportViewerRunRequested();
}
