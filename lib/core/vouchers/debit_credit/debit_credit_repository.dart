import 'package:algo_erp_front/core/data/remote_data_source.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/error/safe_call.dart';
import 'package:algo_erp_front/core/network/api_response.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/network/paginated.dart';
import 'package:algo_erp_front/core/vouchers/debit_credit/debit_credit_dto.dart';
import 'package:algo_erp_front/core/vouchers/debit_credit/debit_credit_kind.dart';
import 'package:algo_erp_front/core/vouchers/debit_credit/debit_credit_models.dart';

/// Online repository for Journal / Contra ([DebitCreditVoucherKind]).
class DebitCreditRepository {
  DebitCreditRepository(this._client, this.kind);

  final DioClient _client;
  final DebitCreditVoucherKind kind;

  Future<Result<Paginated<DebitCreditListItem>>> list(PageQuery query) {
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
      return Paginated<DebitCreditListItem>(
        items: page.items
            .map(
              (j) => DebitCreditDto.listItemFromJson(
                j,
                mainNestKey: kind.mainNestKey,
              ),
            )
            .toList(growable: false),
        meta: page.meta,
      );
    });
  }

  Future<Result<DebitCreditDetail>> getById(
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
      final detail = DebitCreditDto.detailFromJson(data);

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

      return detail.copyWith(lines: lines);
    });
  }

  Future<Result<DebitCreditPostResult>> post(DebitCreditDraft draft) {
    return safeCall(() async {
      final res = await _client.dio.post<Object?>(
        kind.blueprint.postPath,
        data: DebitCreditDto.draftToPostJson(draft, kind: kind),
      );
      final envelope = decodeApiResponse<JsonMap>(
        res.data,
        (j) => j! as JsonMap,
      );
      final data = envelope.data;
      if (data == null) {
        throw FormatException('Expected ${kind.blueprint.label} post result');
      }
      return DebitCreditDto.postResultFromJson(data);
    });
  }

  Future<Result<DebitCreditLifecycleResult>> cancel(int id) =>
      _lifecycle('cancel', id);

  Future<Result<DebitCreditLifecycleResult>> approve(int id) =>
      _lifecycle('approve', id);

  Future<Result<DebitCreditLifecycleResult>> reject(int id, String reason) {
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
      return DebitCreditDto.lifecycleFromJson(data);
    });
  }

  Future<Result<DebitCreditLifecycleResult>> _lifecycle(String action, int id) {
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
      return DebitCreditDto.lifecycleFromJson(data);
    });
  }
}
