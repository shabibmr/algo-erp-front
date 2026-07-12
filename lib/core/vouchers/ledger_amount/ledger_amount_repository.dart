import 'package:algo_erp_front/core/data/remote_data_source.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/error/safe_call.dart';
import 'package:algo_erp_front/core/network/api_response.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/network/paginated.dart';
import 'package:algo_erp_front/core/vouchers/ledger_amount/ledger_amount_dto.dart';
import 'package:algo_erp_front/core/vouchers/ledger_amount/ledger_amount_kind.dart';
import 'package:algo_erp_front/core/vouchers/ledger_amount/ledger_amount_models.dart';

/// Online repository for Payment / Receipt ([LedgerAmountVoucherKind]).
class LedgerAmountRepository {
  LedgerAmountRepository(this._client, this.kind);

  final DioClient _client;
  final LedgerAmountVoucherKind kind;

  Future<Result<Paginated<LedgerAmountListItem>>> list(PageQuery query) {
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
      return Paginated<LedgerAmountListItem>(
        items: page.items
            .map(
              (j) => LedgerAmountDto.listItemFromJson(
                j,
                mainNestKey: kind.mainNestKey,
              ),
            )
            .toList(growable: false),
        meta: page.meta,
      );
    });
  }

  Future<Result<LedgerAmountDetail>> getById(
    int id, {
    Future<String?> Function(int ledgerId)? resolveLedgerLabel,
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
      final detail = LedgerAmountDto.detailFromJson(data);

      var cashBankLabel = detail.cashBankLabel;
      if (resolveLedgerLabel != null && detail.cashBankLedgerId != null) {
        cashBankLabel =
            await resolveLedgerLabel(detail.cashBankLedgerId!) ?? cashBankLabel;
      }

      var lines = detail.lines;
      if (resolveLedgerLabel != null) {
        final labels = <int, String?>{};
        final ids = detail.lines
            .map((l) => l.ledgerId)
            .whereType<int>()
            .toSet();
        for (final ledgerId in ids) {
          labels[ledgerId] = await resolveLedgerLabel(ledgerId);
        }
        lines = [
          for (final line in detail.lines)
            line.copyWith(
              ledgerLabel: line.ledgerId == null
                  ? null
                  : labels[line.ledgerId!],
            ),
        ];
      }

      return detail.copyWith(cashBankLabel: cashBankLabel, lines: lines);
    });
  }

  Future<Result<LedgerAmountPostResult>> post(LedgerAmountDraft draft) {
    return safeCall(() async {
      final res = await _client.dio.post<Object?>(
        kind.blueprint.postPath,
        data: LedgerAmountDto.draftToPostJson(draft),
      );
      final envelope = decodeApiResponse<JsonMap>(
        res.data,
        (j) => j! as JsonMap,
      );
      final data = envelope.data;
      if (data == null) {
        throw FormatException('Expected ${kind.blueprint.label} post result');
      }
      return LedgerAmountDto.postResultFromJson(data);
    });
  }

  Future<Result<LedgerAmountLifecycleResult>> cancel(int id) {
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
      return LedgerAmountDto.lifecycleFromJson(data);
    });
  }
}
