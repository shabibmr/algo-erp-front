import 'package:equatable/equatable.dart';

class ErrorReportDto extends Equatable {
  const ErrorReportDto({
    required this.id,
    required this.error,
    this.tablename = '',
    this.query = '',
    this.clientId,
    this.timeStamp,
  });

  factory ErrorReportDto.fromJson(Map<String, dynamic> json) => ErrorReportDto(
    id: json['id'] as int? ?? 0,
    error: json['error'] as String? ?? '',
    tablename: json['tablename'] as String? ?? '',
    query: json['query'] as String? ?? '',
    clientId: json['client_id'] as String?,
    timeStamp: json['time_stamp']?.toString(),
  );

  final int id;
  final String error;
  final String tablename;
  final String query;
  final String? clientId;
  final String? timeStamp;

  Map<String, dynamic> toJson() => {
    'error': error,
    'tablename': tablename,
    'query': query,
    if (clientId != null && clientId!.isNotEmpty) 'client_id': clientId,
  };

  @override
  List<Object?> get props => [
    id,
    error,
    tablename,
    query,
    clientId,
    timeStamp,
  ];
}
