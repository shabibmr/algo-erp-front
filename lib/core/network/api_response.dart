/// Matches the backend's success/error envelope exactly
/// (see docs/api-contract.md and models/backend/src/core/types/index.ts):
/// `{ success, message?, data, requestId }` or
/// `{ success:false, error:{ message, code?, details? }, requestId }`.
class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    required this.requestId,
    this.message,
    this.data,
    this.error,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    final rawData = json['data'];
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: rawData == null ? null : fromJsonT(rawData),
      error: json['error'] == null
          ? null
          : ApiErrorBody.fromJson(json['error'] as Map<String, dynamic>),
      requestId: json['requestId'] as String? ?? '',
    );
  }

  final bool success;
  final String? message;
  final T? data;
  final ApiErrorBody? error;
  final String requestId;
}

class ApiErrorBody {
  const ApiErrorBody({required this.message, this.code, this.details});

  factory ApiErrorBody.fromJson(Map<String, dynamic> json) {
    return ApiErrorBody(
      message: json['message'] as String? ?? 'Unknown error',
      code: json['code'] as String?,
      details: json['details'] as List<dynamic>?,
    );
  }

  final String message;
  final String? code;
  final List<dynamic>? details;
}

/// Decodes a raw JSON body into an [ApiResponse]. Throws [FormatException]
/// if [json] isn't the expected envelope shape.
ApiResponse<T> decodeApiResponse<T>(
  dynamic json,
  T Function(Object? json) fromJsonT,
) {
  if (json is! Map<String, dynamic>) {
    throw const FormatException('Expected a JSON object envelope');
  }
  return ApiResponse<T>.fromJson(json, fromJsonT);
}
