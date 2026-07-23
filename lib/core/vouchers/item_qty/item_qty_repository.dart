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

/// Online repository for one [ItemQtyVoucherKind] (list / get / post / lifecycle).
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
    Future<String?> Function(int employeeId)? resolveSalespersonLabel,
    Future<String?> Function(int projectId)? resolveProjectLabel,
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

      final partyFuture =
          resolvePartyLabel != null && detail.partyLedgerId != null
          ? resolvePartyLabel(detail.partyLedgerId!)
          : Future<String?>.value(detail.partyLabel);
      final godownFuture = resolveGodownLabel != null && detail.godownId != null
          ? resolveGodownLabel(detail.godownId!)
          : Future<String?>.value(detail.godownLabel);
      final salespersonFuture =
          resolveSalespersonLabel != null &&
              detail.salespersonEmployeeId != null
          ? resolveSalespersonLabel(detail.salespersonEmployeeId!)
          : Future<String?>.value(detail.salespersonLabel);
      final projectFuture =
          resolveProjectLabel != null && detail.voucherProjectId != null
          ? resolveProjectLabel(detail.voucherProjectId!)
          : Future<String?>.value(detail.projectLabel);

      final (partyLabel, godownLabel, salespersonLabel, projectLabel) = await (
        partyFuture,
        godownFuture,
        salespersonFuture,
        projectFuture,
      ).wait;

      var lines = detail.lines;
      if (resolveItemLabel != null) {
        final ids = detail.lines.map((l) => l.itemId).whereType<int>().toSet();
        final resolved = await Future.wait(
          ids.map(
            (itemId) async => MapEntry(itemId, await resolveItemLabel(itemId)),
          ),
        );
        final labels = {for (final e in resolved) e.key: e.value};
        lines = [
          for (final line in detail.lines)
            line.copyWith(
              itemLabel: line.itemId == null ? null : labels[line.itemId!],
            ),
        ];
      }

      return detail.copyWith(
        partyLabel: partyLabel ?? detail.partyLabel,
        godownLabel: godownLabel ?? detail.godownLabel,
        salespersonLabel: salespersonLabel ?? detail.salespersonLabel,
        projectLabel: projectLabel ?? detail.projectLabel,
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

  /// Draft-only line/header replace via lifecycle edit.
  Future<Result<ItemQtyLifecycleResult>> updateDraft(
    int id,
    ItemQtyDraft draft,
  ) {
    return safeCall(() async {
      final res = await _client.dio.put<Object?>(
        '/transactions/${kind.lifecycleType}/$id',
        data: ItemQtyDto.draftToEditJson(draft),
      );
      return _lifecycleBody(res.data);
    });
  }

  Future<Result<ItemQtyLifecycleResult>> cancel(int id) =>
      _lifecycle('cancel', id);

  Future<Result<ItemQtyLifecycleResult>> approve(int id) =>
      _lifecycle('approve', id);

  Future<Result<ItemQtyLifecycleResult>> reject(int id, String reason) {
    return safeCall(() async {
      final res = await _client.dio.post<Object?>(
        '/transactions/${kind.lifecycleType}/$id/reject',
        data: {'reason': reason},
      );
      return _lifecycleBody(res.data);
    });
  }

  Future<Result<ItemQtyLifecycleResult>> _lifecycle(String action, int id) {
    return safeCall(() async {
      final res = await _client.dio.post<Object?>(
        '/transactions/${kind.lifecycleType}/$id/$action',
      );
      return _lifecycleBody(res.data);
    });
  }

  ItemQtyLifecycleResult _lifecycleBody(Object? raw) {
    final envelope = decodeApiResponse<JsonMap>(raw, (j) => j! as JsonMap);
    final data = envelope.data;
    if (data == null) {
      throw const FormatException('Expected lifecycle result');
    }
    return ItemQtyDto.lifecycleFromJson(data);
  }

  Future<Result<List<ItemQtySourceLite>>> searchSourceVouchers({
    String query = '',
    String? type,
    String? listPath,
    String? mainNestKey,
  }) {
    final path = listPath ?? kind.sourceListPath;
    final sourceType = type ?? kind.sourceLifecycleType;
    final nest = mainNestKey ?? kind.sourceMainNestKey;
    if (path == null || sourceType == null || nest == null) {
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
              type: sourceType,
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

  Future<Result<ItemQtySourceLite>> getSourceVoucher(
    int id, {
    String? type,
    String? detailPathPattern,
    String? mainNestKey,
  }) {
    final pathPattern = detailPathPattern ?? kind.sourceDetailPathPattern;
    final sourceType = type ?? kind.sourceLifecycleType;
    final nest = mainNestKey ?? kind.sourceMainNestKey;
    final path = pathPattern?.replaceAll(':id', id.toString());
    if (path == null || sourceType == null || nest == null) {
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
      return ItemQtyDto.sourceFromJson(
        data,
        type: sourceType,
        mainNestKey: nest,
      );
    });
  }
}
