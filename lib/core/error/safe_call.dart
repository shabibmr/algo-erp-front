import 'package:algo_erp_front/core/error/failure.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

typedef Result<T> = Either<Failure, T>;

/// Runs [call], mapping any [DioException] (or other error) to a [Failure]
/// so callers only ever deal with `Result<T>`, never raw exceptions.
Future<Result<T>> safeCall<T>(Future<T> Function() call) async {
  try {
    return Right(await call());
  } on DioException catch (e) {
    return Left(mapDioException(e));
  } on Object catch (e) {
    return Left(Failure.unknown(e.toString()));
  }
}

Failure mapDioException(DioException e) {
  return switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.transformTimeout => Failure.timeout(
      e.message ?? 'Request timed out',
    ),
    DioExceptionType.connectionError => Failure.network(
      e.message ?? 'Network error',
    ),
    DioExceptionType.badCertificate => const Failure.network('Bad certificate'),
    DioExceptionType.cancel => const Failure.unknown('Request cancelled'),
    DioExceptionType.badResponse => _mapBadResponse(e),
    DioExceptionType.unknown => Failure.network(
      e.message ?? 'Unknown network error',
    ),
  };
}

Failure _mapBadResponse(DioException e) {
  final statusCode = e.response?.statusCode;
  final body = e.response?.data;
  final errorBody = body is Map<String, dynamic>
      ? body['error'] as Map<String, dynamic>?
      : null;
  final message =
      (errorBody?['message'] as String?) ?? e.message ?? 'Server error';
  final code = errorBody?['code'] as String?;
  final details = errorBody?['details'] as List<dynamic>?;

  return switch (statusCode) {
    400 => Failure.validation(message, _mapValidationDetails(details)),
    401 => Failure.unauthorized(message),
    403 => Failure.forbidden(message),
    404 => Failure.notFound(message),
    409 => Failure.conflict(message),
    _ => Failure.server(message, code: code),
  };
}

List<ValidationFieldError> _mapValidationDetails(List<dynamic>? details) {
  if (details == null) return const [];
  return details
      .map((d) {
        if (d is! Map<String, dynamic>) {
          return const ValidationFieldError(
            field: '',
            message: 'Invalid value',
          );
        }
        final path = d['path'];
        final field = path is List ? path.join('.') : (path?.toString() ?? '');
        return ValidationFieldError(
          field: field,
          message: d['message'] as String? ?? 'Invalid value',
        );
      })
      .toList(growable: false);
}
