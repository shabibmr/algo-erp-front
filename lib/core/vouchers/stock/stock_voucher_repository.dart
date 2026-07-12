import 'package:algo_erp_front/core/data/remote_data_source.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/error/safe_call.dart';
import 'package:algo_erp_front/core/network/api_response.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/network/paginated.dart';
import 'package:algo_erp_front/core/vouchers/stock/stock_voucher_dto.dart';
import 'package:algo_erp_front/core/vouchers/stock/stock_voucher_kind.dart';
import 'package:algo_erp_front/core/vouchers/stock/stock_voucher_models.dart';

/// Online repository for stock vouchers ([StockVoucherKind]).
class StockVoucherRepository {
  StockVoucherRepository(this._client, this.kind);

  final DioClient _client;
  final StockVoucherKind kind;

  Future<Result<Paginated<StockVoucherListItem>>> list(PageQuery query) {
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
      return Paginated<StockVoucherListItem>(
        items: page.items
            .map(
              (j) => StockVoucherDto.listItemFromJson(
                j,
                mainNestKey: kind.mainNestKey,
              ),
            )
            .toList(growable: false),
        meta: page.meta,
      );
    });
  }

  Future<Result<StockVoucherDetail>> getById(
    int id, {
    Future<String?> Function(int itemId)? resolveItemLabel,
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
      final detail = StockVoucherDto.detailFromJson(data);

      var fromLabel = detail.fromGodownLabel;
      var toLabel = detail.toGodownLabel;
      var godownLabel = detail.godownLabel;
      if (resolveGodownLabel != null) {
        if (detail.fromGodownId != null) {
          fromLabel =
              await resolveGodownLabel(detail.fromGodownId!) ?? fromLabel;
        }
        if (detail.toGodownId != null) {
          toLabel = await resolveGodownLabel(detail.toGodownId!) ?? toLabel;
        }
        if (detail.godownId != null) {
          godownLabel =
              await resolveGodownLabel(detail.godownId!) ?? godownLabel;
        }
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
        fromGodownLabel: fromLabel,
        toGodownLabel: toLabel,
        godownLabel: godownLabel,
        lines: lines,
      );
    });
  }

  Future<Result<StockVoucherPostResult>> post(StockVoucherDraft draft) {
    return safeCall(() async {
      final res = await _client.dio.post<Object?>(
        kind.blueprint.postPath,
        data: StockVoucherDto.draftToPostJson(draft, kind: kind),
      );
      final envelope = decodeApiResponse<JsonMap>(
        res.data,
        (j) => j! as JsonMap,
      );
      final data = envelope.data;
      if (data == null) {
        throw FormatException('Expected ${kind.blueprint.label} post result');
      }
      return StockVoucherDto.postResultFromJson(data, idKey: kind.postIdKey);
    });
  }

  Future<Result<StockVoucherLifecycleResult>> cancel(int id) {
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
      return StockVoucherDto.lifecycleFromJson(data);
    });
  }
}
