import 'package:algo_erp_front/core/network/api_response.dart';
import 'package:algo_erp_front/core/network/paginated.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiResponse', () {
    test('decodes a success envelope', () {
      final json = {
        'success': true,
        'message': 'ok',
        'data': {'id': 1, 'name': 'Brand A'},
        'requestId': 'req-123',
      };

      final response = decodeApiResponse<Map<String, dynamic>>(
        json,
        (data) => data! as Map<String, dynamic>,
      );

      expect(response.success, isTrue);
      expect(response.message, 'ok');
      expect(response.data, {'id': 1, 'name': 'Brand A'});
      expect(response.error, isNull);
      expect(response.requestId, 'req-123');
    });

    test('decodes an error envelope with zod-style details', () {
      final json = {
        'success': false,
        'error': {
          'message': 'Validation failed',
          'code': 'VALIDATION_ERROR',
          'details': [
            {
              'path': ['brand_name'],
              'message': 'Required',
            },
          ],
        },
        'requestId': 'req-456',
      };

      final response = decodeApiResponse<Object?>(json, (data) => data);

      expect(response.success, isFalse);
      expect(response.data, isNull);
      expect(response.error?.message, 'Validation failed');
      expect(response.error?.code, 'VALIDATION_ERROR');
      expect(response.error?.details, hasLength(1));
    });

    test('throws FormatException for a non-object body', () {
      expect(
        () => decodeApiResponse<Object?>(<dynamic>[1, 2, 3], (data) => data),
        throwsFormatException,
      );
    });
  });

  group('Paginated', () {
    test('decodes items and meta matching the backend shape', () {
      final json = {
        'items': [
          {'id': 1},
          {'id': 2},
        ],
        'meta': {'total': 40, 'page': 1, 'limit': 20, 'totalPages': 2},
      };

      final paginated = Paginated<Map<String, dynamic>>.fromJson(
        json,
        (data) => data! as Map<String, dynamic>,
      );

      expect(paginated.items, hasLength(2));
      expect(paginated.meta.total, 40);
      expect(paginated.meta.page, 1);
      expect(paginated.meta.limit, 20);
      expect(paginated.meta.totalPages, 2);
      expect(paginated.meta.hasMore, isTrue);
    });

    test('hasMore is false on the last page', () {
      const meta = PaginationMeta(total: 20, page: 2, limit: 20, totalPages: 2);
      expect(meta.hasMore, isFalse);
    });
  });
}
