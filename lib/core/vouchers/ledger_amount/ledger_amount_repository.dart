import 'package:algo_erp_front/core/data/remote_data_source.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/error/safe_call.dart';
import 'package:algo_erp_front/core/network/api_response.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/network/paginated.dart';
import 'package:algo_erp_front/core/vouchers/ledger_amount/ledger_amount_dto.dart';
import 'package:algo_erp_front/core/vouchers/ledger_amount/ledger_amount_kind.dart';
import 'package:algo_erp_front/core/vouchers/ledger_amount/ledger_amount_models.dart';
import 'package:decimal/decimal.dart';

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

  Future<Result<LedgerAmountLifecycleResult>> cancel(int id) =>
      _lifecycle('cancel', id);

  Future<Result<LedgerAmountLifecycleResult>> approve(int id) =>
      _lifecycle('approve', id);

  Future<Result<LedgerAmountLifecycleResult>> reject(int id, String reason) {
    return safeCall(() async {
      final res = await _client.dio.post<Object?>(
        '/transactions/${kind.lifecycleType}/$id/reject',
        data: {'reason': reason},
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

  Future<Result<LedgerAmountLifecycleResult>> _lifecycle(
    String action,
    int id,
  ) {
    return safeCall(() async {
      final res = await _client.dio.post<Object?>(
        '/transactions/${kind.lifecycleType}/$id/$action',
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

  /// Outstanding New-Ref bills for a party ledger (settlement UI).
  Future<Result<List<OutstandingBill>>> listOutstanding(int ledgerId) {
    return safeCall(() async {
      final res = await _client.dio.get<Object?>(
        '/accounts/outstanding/$ledgerId',
      );
      final envelope = decodeApiResponse<Object?>(res.data, (j) => j);
      final data = envelope.data;
      if (data is! List) return <OutstandingBill>[];
      return [
        for (final raw in data)
          if (raw is Map<String, dynamic>) OutstandingBill.fromJson(raw),
      ];
    });
  }

  /// Write an Agst Ref billwise row after payment/receipt post.
  Future<Result<void>> createBillwiseSettlement({
    required int ledgerId,
    required OutstandingBill bill,
    required Decimal amount,
    required String voucherPrefix,
    required String voucherNo,
    required String voucherType,
    required bool isPayment,
  }) {
    return safeCall(() async {
      final amt = double.tryParse(amount.toString()) ?? 0;
      await _client.dio.post<Object?>(
        '/accounts/billwise',
        data: {
          'voucher_prefix': voucherPrefix,
          'voucher_type': voucherType,
          'voucher_no': voucherNo,
          'ledger_id': ledgerId.toString(),
          'ref_type': 'Agst Ref',
          'ref_no': bill.refNo,
          if (bill.refPrefix != null && bill.refPrefix!.isNotEmpty)
            'ref_prefix': bill.refPrefix,
          // Payment reduces AR (credit); receipt reduces AP (debit).
          if (isPayment) 'credit_amount': amt else 'debit_amount': amt,
        },
      );
    });
  }
}
