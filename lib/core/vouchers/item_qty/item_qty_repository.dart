import 'package:algo_erp_front/core/data/remote_data_source.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/error/safe_call.dart';
import 'package:algo_erp_front/core/network/api_response.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/network/paginated.dart';
import 'package:algo_erp_front/core/vouchers/item_qty/item_qty_dto.dart';
import 'package:algo_erp_front/core/vouchers/item_qty/item_qty_kind.dart';
import 'package:algo_erp_front/core/vouchers/item_qty/item_qty_models.dart';
import 'package:fpdart/fpdart.dart';

/// Online repository for one [ItemQtyVoucherKind] (list / get / post / cancel).
class ItemQtyRepository {
  ItemQtyRepository(this._client, this.kind);

  final DioClient _client;
  final ItemQtyVoucherKind kind;

  Future<Result<Paginated<ItemQtyListItem>>> list(PageQuery query) {
    return safeCall(() async {
      final params = <String, dynamic>{
        'page': query.page,
        'limit': query.limit,
        if (query.search != null && query.search!.isNotEmpty)
          'search': query.search,
      };
      query.filters.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          params[key] = value;
        }
      });
      final res = await _client.dio.get<Object?>(
        kind.blueprint.listPath,
        queryParameters: params,
      );
      final envelope = decodeApiResponse<JsonMap>(
        res.data,
        (j) => j! as JsonMap,
      );
      final data = envelope.data;
      if (data == null) {
        throw FormatException('Expected paginated ${kind.blueprint.label}');
      }
      final page = Paginated<JsonMap>.fromJson(data, (j) => j! as JsonMap);
      return Paginated<ItemQtyListItem>(
        items: page.items
            .map(
              (j) =>
                  ItemQtyDto.listItemFromJson(j, mainNestKey: kind.mainNestKey),
            )
            .toList(growable: false),
        meta: page.meta,
      );
    });
  }

  Future<Result<ItemQtyDetail>> getById(
    int id, {
    Future<String?> Function(int itemId)? resolveItemLabel,
    Future<String?> Function(int ledgerId)? resolvePartyLabel,
    Future<String?> Function(int godownId)? resolveGodownLabel,
  }) {
    return safeCall(() async {
      final res = await _client.dio.get<Object?>(kind.blueprint.detailPath(id));
      final envelope = decodeApiResponse<JsonMap>(
        res.data,
        (j) => j! as JsonMap,
      );
      final data = envelope.data;
      if (data == null) {
        throw FormatException('Expected ${kind.blueprint.label} detail');
      }
      final detail = ItemQtyDto.detailFromJson(data);

      var partyLabel = detail.partyLabel;
      var godownLabel = detail.godownLabel;
      if (resolvePartyLabel != null && detail.partyLedgerId != null) {
        partyLabel =
            await resolvePartyLabel(detail.partyLedgerId!) ?? partyLabel;
      }
      if (resolveGodownLabel != null && detail.godownId != null) {
        godownLabel = await resolveGodownLabel(detail.godownId!) ?? godownLabel;
      }

      var lines = detail.lines;
      if (resolveItemLabel != null) {
        final labels = <int, String?>{};
        final ids = detail.lines.map((l) => l.itemId).whereType<int>().toSet();
        for (final itemId in ids) {
          labels[itemId] = await resolveItemLabel(itemId);
        }
        lines = [
          for (final line in detail.lines)
            line.copyWith(
              itemLabel: line.itemId == null ? null : labels[line.itemId!],
            ),
        ];
      }

      return detail.copyWith(
        partyLabel: partyLabel,
        godownLabel: godownLabel,
        lines: lines,
      );
    });
  }

  Future<Result<ItemQtyPostResult>> post(ItemQtyDraft draft) {
    return safeCall(() async {
      final res = await _client.dio.post<Object?>(
        kind.blueprint.postPath,
        data: ItemQtyDto.draftToPostJson(draft, kind: kind),
      );
      final envelope = decodeApiResponse<JsonMap>(
        res.data,
        (j) => j! as JsonMap,
      );
      final data = envelope.data;
      if (data == null) {
        throw FormatException('Expected ${kind.blueprint.label} post result');
      }
      return ItemQtyDto.postResultFromJson(data, idKey: kind.postIdKey);
    });
  }

  Future<Result<ItemQtyLifecycleResult>> cancel(int id) {
    return safeCall(() async {
      final res = await _client.dio.post<Object?>(
        '/transactions/${kind.lifecycleType}/$id/cancel',
      );
      final envelope = decodeApiResponse<JsonMap>(
        res.data,
        (j) => j! as JsonMap,
      );
      final data = envelope.data;
      if (data == null) {
        throw const FormatException('Expected lifecycle result');
      }
      return ItemQtyDto.lifecycleFromJson(data);
    });
  }

  Future<Result<List<ItemQtySourceLite>>> searchSourceVouchers({
    String query = '',
  }) {
    final path = kind.sourceListPath;
    final type = kind.sourceLifecycleType;
    final nest = kind.sourceMainNestKey;
    if (path == null || type == null || nest == null) {
      return Future<Result<List<ItemQtySourceLite>>>.value(
        const Right(<ItemQtySourceLite>[]),
      );
    }
    return safeCall(() async {
      final res = await _client.dio.get<Object?>(
        path,
        queryParameters: {
          'page': 1,
          'limit': 30,
          if (query.isNotEmpty) 'search': query,
        },
      );
      final envelope = decodeApiResponse<JsonMap>(
        res.data,
        (j) => j! as JsonMap,
      );
      final data = envelope.data;
      if (data == null) return <ItemQtySourceLite>[];
      final items = data['items'] as List<dynamic>? ?? const [];
      return [
        for (final raw in items)
          if (raw is Map<String, dynamic>)
            ItemQtySourceLite(
              id: raw['id'] as int,
              type: type,
              displayNo: () {
                final p = raw['voucher_prefix'] as String? ?? '';
                final n = raw['voucher_no'] as String? ?? '';
                return (p + n).isEmpty ? '#${raw['id']}' : '$p$n';
              }(),
              billingName:
                  (raw[nest] as Map<String, dynamic>?)?['Billing_Name']
                      as String?,
            ),
      ];
    });
  }

  Future<Result<ItemQtySourceLite>> getSourceVoucher(int id) {
    final path = kind.sourceDetailPath(id);
    final type = kind.sourceLifecycleType;
    final nest = kind.sourceMainNestKey;
    if (path == null || type == null || nest == null) {
      return Future<Result<ItemQtySourceLite>>.value(
        const Left(Failure.unknown('Source not configured')),
      );
    }
    return safeCall(() async {
      final res = await _client.dio.get<Object?>(path);
      final envelope = decodeApiResponse<JsonMap>(
        res.data,
        (j) => j! as JsonMap,
      );
      final data = envelope.data;
      if (data == null) {
        throw const FormatException('Expected source voucher');
      }
      return ItemQtyDto.sourceFromJson(data, type: type, mainNestKey: nest);
    });
  }
}
