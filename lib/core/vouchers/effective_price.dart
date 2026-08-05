import 'package:algo_erp_front/core/error/safe_call.dart';
import 'package:algo_erp_front/core/network/api_response.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:decimal/decimal.dart';

/// Resolves the sell rate for an item code via
/// `GET /inventory/pricelist/effective-price`.
///
/// [itemCode] must be the inventory `Item_Code` (string), not the numeric PK —
/// that matches how `pricelist_entries.Item_Id` and the backend fallback join.
Future<Result<Decimal>> fetchEffectivePrice(
  DioClient client, {
  required String itemCode,
  int? priceListId,
  DateTime? date,
}) {
  return safeCall(() async {
    final code = itemCode.trim();
    if (code.isEmpty) {
      throw const FormatException('itemCode is required for effective price');
    }
    final res = await client.dio.get<Object?>(
      '/inventory/pricelist/effective-price',
      queryParameters: {
        'itemId': code,
        if (priceListId != null) 'priceListId': priceListId,
        if (date != null)
          'date':
              '${date.year.toString().padLeft(4, '0')}-'
              '${date.month.toString().padLeft(2, '0')}-'
              '${date.day.toString().padLeft(2, '0')}',
      },
    );
    final envelope = decodeApiResponse<Object?>(res.data, (j) => j);
    final data = envelope.data;
    if (data is Map<String, dynamic>) {
      final raw = data['price'];
      if (raw is num) return Decimal.parse(raw.toString());
      if (raw is String && raw.isNotEmpty) return Decimal.parse(raw);
    }
    throw const FormatException('Effective price response missing price');
  });
}
