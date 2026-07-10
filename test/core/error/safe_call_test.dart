import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/error/safe_call.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

RequestOptions _requestOptions() => RequestOptions(path: '/brands');

Response<dynamic> _response(int statusCode, Map<String, dynamic>? data) {
  return Response<dynamic>(
    requestOptions: _requestOptions(),
    statusCode: statusCode,
    data: data,
  );
}

void main() {
  group('safeCall', () {
    test('returns Right on success', () async {
      final result = await safeCall(() async => 42);
      expect(result.isRight(), isTrue);
      result.match((_) => fail('expected Right'), (value) {
        expect(value, 42);
      });
    });

    test('maps a non-Dio exception to Failure.unknown', () async {
      final result = await safeCall<int>(() async => throw StateError('bad'));
      expect(
        result.match((f) => f, (_) => fail('expected Left')),
        isA<UnknownFailure>(),
      );
    });
  });

  group('mapDioException', () {
    test('maps connectionTimeout to Failure.timeout', () {
      final e = DioException(
        requestOptions: _requestOptions(),
        type: DioExceptionType.connectionTimeout,
      );
      expect(mapDioException(e), isA<TimeoutFailure>());
    });

    test('maps connectionError to Failure.network', () {
      final e = DioException(
        requestOptions: _requestOptions(),
        type: DioExceptionType.connectionError,
      );
      expect(mapDioException(e), isA<NetworkFailure>());
    });

    test('maps 400 with zod details to Failure.validation with fields', () {
      final e = DioException(
        requestOptions: _requestOptions(),
        type: DioExceptionType.badResponse,
        response: _response(400, {
          'success': false,
          'error': {
            'message': 'Validation failed',
            'details': [
              {
                'path': ['brand_name'],
                'message': 'Required',
              },
            ],
          },
        }),
      );

      final failure = mapDioException(e);
      expect(failure, isA<ValidationFailure>());
      final validation = failure as ValidationFailure;
      expect(validation.message, 'Validation failed');
      expect(validation.fieldErrors, [
        const ValidationFieldError(field: 'brand_name', message: 'Required'),
      ]);
    });

    test('maps 401 to Failure.unauthorized', () {
      final e = DioException(
        requestOptions: _requestOptions(),
        type: DioExceptionType.badResponse,
        response: _response(401, {
          'success': false,
          'error': {'message': 'Token expired'},
        }),
      );
      expect(mapDioException(e), isA<UnauthorizedFailure>());
    });

    test('maps 403 to Failure.forbidden', () {
      final e = DioException(
        requestOptions: _requestOptions(),
        type: DioExceptionType.badResponse,
        response: _response(403, {
          'success': false,
          'error': {'message': 'Not allowed'},
        }),
      );
      expect(mapDioException(e), isA<ForbiddenFailure>());
    });

    test('maps 404 to Failure.notFound', () {
      final e = DioException(
        requestOptions: _requestOptions(),
        type: DioExceptionType.badResponse,
        response: _response(404, {
          'success': false,
          'error': {'message': 'Not found'},
        }),
      );
      expect(mapDioException(e), isA<NotFoundFailure>());
    });

    test('maps 409 to Failure.conflict', () {
      final e = DioException(
        requestOptions: _requestOptions(),
        type: DioExceptionType.badResponse,
        response: _response(409, {
          'success': false,
          'error': {'message': 'Conflict'},
        }),
      );
      expect(mapDioException(e), isA<ConflictFailure>());
    });

    test('maps other status codes to Failure.server with the code', () {
      final e = DioException(
        requestOptions: _requestOptions(),
        type: DioExceptionType.badResponse,
        response: _response(500, {
          'success': false,
          'error': {'message': 'Boom', 'code': 'INTERNAL'},
        }),
      );
      final failure = mapDioException(e);
      expect(failure, isA<ServerFailure>());
      expect((failure as ServerFailure).code, 'INTERNAL');
    });
  });
}
