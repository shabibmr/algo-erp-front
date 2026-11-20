import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/error/safe_call.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/network/paginated.dart';
import 'package:algo_erp_front/features/inventory_attribute/data/product_attribute_dto.dart';
import 'package:algo_erp_front/features/inventory_attribute/data/product_attribute_mapper.dart';
import 'package:algo_erp_front/features/inventory_attribute/domain/product_attribute.dart';

/// Text to show the user. Validation, conflict and not-found messages come from
/// the backend and are meant for people; anything else gets the fixed [fallback]
/// so raw exception text never reaches the UI.
String failureText(Failure failure, String fallback) => switch (failure) {
  ValidationFailure(:final message) ||
  ConflictFailure(:final message) ||
  NotFoundFailure(:final message) => message,
  _ => fallback,
};

/// Item-level attribute operations: assignments, suggestions, variant
/// resolution and the paged SKU list. Maps JSON here so widgets never do.
class ItemAttributeRepository {
  ItemAttributeRepository(this._client);

  final DioClient _client;

  Map<String, dynamic> _data(Object? body) {
    final envelope = body as Map<String, dynamic>?;
    return envelope?['data'] as Map<String, dynamic>? ?? const {};
  }

  List<dynamic> _list(Object? body) {
    final envelope = body as Map<String, dynamic>?;
    return envelope?['data'] as List<dynamic>? ?? const [];
  }

  Future<Result<List<ItemAttributeAssignment>>> getAssignments(int itemId) {
    return safeCall(() async {
      final res = await _client.dio.get<Object?>(
        '/inventory/item/$itemId/attributes',
      );
      return _list(res.data)
          .map(
            (e) => mapAssignment(
              ItemAttributeAssignmentDto.fromJson(e as Map<String, dynamic>),
            ),
          )
          .toList(growable: false);
    });
  }

  /// Attribute master tree: groups with their children.
  Future<Result<List<ProductAttribute>>> getAttributeTree() {
    return safeCall(() async {
      final res = await _client.dio.get<Object?>('/inventory/attribute/tree');
      return _list(res.data)
          .map(
            (e) => const ProductAttributeMapper().toEntity(
              ProductAttributeDto.fromJson(e as Map<String, dynamic>),
            ),
          )
          .toList(growable: false);
    });
  }

  Future<Result<List<ItemAttributeAssignment>>> saveAssignments(
    int itemId,
    List<ItemAttributeAssignment> assignments,
  ) {
    return safeCall(() async {
      final res = await _client.dio.post<Object?>(
        '/inventory/item/$itemId/attributes',
        data: {
          'attributes': [
            for (final a in assignments)
              {
                'attribute_id': a.attributeId,
                'is_required': a.isRequired,
                'display_order': a.displayOrder,
              },
          ],
        },
      );
      return _list(res.data)
          .map(
            (e) => mapAssignment(
              ItemAttributeAssignmentDto.fromJson(e as Map<String, dynamic>),
            ),
          )
          .toList(growable: false);
    });
  }

  Future<Result<Map<int, List<String>>>> getSuggestions(int itemId) {
    return safeCall(() async {
      final res = await _client.dio.get<Object?>(
        '/inventory/item/$itemId/attribute-suggestions',
      );
      return _data(res.data).map(
        (k, v) => MapEntry(
          int.parse(k),
          (v as List<dynamic>).map((e) => e.toString()).toList(),
        ),
      );
    });
  }

  Future<Result<Paginated<ItemSku>>> getSkus(
    int itemId, {
    int page = 1,
    int limit = 50,
  }) {
    return safeCall(() async {
      final res = await _client.dio.get<Object?>(
        '/inventory/item/$itemId/skus',
        queryParameters: {'page': page, 'limit': limit},
      );
      return Paginated<ItemSku>.fromJson(
        _data(res.data),
        (json) =>
            mapItemSku(ItemSkuDto.fromJson(json! as Map<String, dynamic>)),
      );
    });
  }

  Future<Result<ResolvedVariant>> resolveVariant(
    int itemId,
    List<VariantAttributeInput> attributes,
  ) {
    return safeCall(() async {
      final res = await _client.dio.post<Object?>(
        '/inventory/sku/resolve-variant',
        data: {
          'itemId': itemId,
          'attributes': [
            for (final a in attributes)
              {
                'attributeId': a.attributeId,
                'value': a.value,
                if (a.valueId != null) 'valueId': a.valueId,
              },
          ],
        },
      );
      return mapResolvedVariant(ResolvedVariantDto.fromJson(_data(res.data)));
    });
  }
}
