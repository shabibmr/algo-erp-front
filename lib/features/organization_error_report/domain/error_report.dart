import 'package:equatable/equatable.dart';

const _unset = Object();

/// Client/server error report (`error_reporting`). Create + list only.
class ErrorReport extends Equatable {
  const ErrorReport({
    required this.id,
    required this.error,
    this.tablename = '',
    this.query = '',
    this.clientId,
    this.timeStamp,
  });

  final int id;
  final String error;
  final String tablename;
  final String query;
  final String? clientId;
  final String? timeStamp;

  ErrorReport copyWith({
    int? id,
    String? error,
    String? tablename,
    String? query,
    Object? clientId = _unset,
    Object? timeStamp = _unset,
  }) => ErrorReport(
    id: id ?? this.id,
    error: error ?? this.error,
    tablename: tablename ?? this.tablename,
    query: query ?? this.query,
    clientId: identical(clientId, _unset) ? this.clientId : clientId as String?,
    timeStamp: identical(timeStamp, _unset)
        ? this.timeStamp
        : timeStamp as String?,
  );

  @override
  List<Object?> get props => [id, error, tablename, query, clientId, timeStamp];
}
