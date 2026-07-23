import 'package:algo_erp_front/core/data/remote_data_source.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/error/safe_call.dart';
import 'package:algo_erp_front/core/network/api_response.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/network/paginated.dart';
import 'package:algo_erp_front/core/vouchers/item_qty/item_qty_dto.dart';
import 'package:algo_erp_front/core/vouchers/item_qty/item_qty_kind.dart';
import 'package:algo_erp_front/core/vouchers/item_qty/item_qty_repository.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/domain/sales_invoice.dart';

/// Online repository for Sales Invoice list, detail, post, and lifecycle.
///
/// Delegates core voucher I/O to [ItemQtyRepository]; keeps SI-specific
/// employee/project lookups and multi-source (Quotation | Sales Order) helpers.
class SalesInvoiceRepository {
  SalesInvoiceRepository(this._client)
    : _itemQty = ItemQtyRepository(_client, ItemQtyKinds.salesInvoice);

  final DioClient _client;
  final ItemQtyRepository _itemQty;

  Future<Result<Paginated<SalesInvoiceListItem>>> list(PageQuery query) =>
      _itemQty.list(query);

  Future<Result<SalesInvoiceDetail>> getById(
    int id, {
    Future<String?> Function(int itemId)? resolveItemLabel,
    Future<String?> Function(int ledgerId)? resolveCustomerLabel,
    Future<String?> Function(int godownId)? resolveGodownLabel,
    Future<String?> Function(int employeeId)? resolveSalespersonLabel,
    Future<String?> Function(int projectId)? resolveProjectLabel,
  }) {
    return _itemQty.getById(
      id,
      resolveItemLabel: resolveItemLabel,
      resolvePartyLabel: resolveCustomerLabel,
      resolveGodownLabel: resolveGodownLabel,
      resolveSalespersonLabel: resolveSalespersonLabel,
      resolveProjectLabel: resolveProjectLabel,
    );
  }

  /// Look up series for this voucher type+prefix (approval flag).
  Future<Result<bool?>> seriesRequiresApproval({
    required String voucherType,
    required String prefix,
  }) {
    return safeCall(() async {
      final res = await _client.dio.get<Object?>(
        '/organization/voucher-series',
        queryParameters: {
          'limit': 100,
          'voucher_type': voucherType,
          'prefix': prefix,
        },
      );
      final envelope = decodeApiResponse<JsonMap>(
        res.data,
        (j) => j! as JsonMap,
      );
      final data = envelope.data;
      if (data == null) return null;
      if (data['items'] is! List) return null;
      final items = data['items'] as List<dynamic>;
      for (final raw in items) {
        if (raw is! Map<String, dynamic>) continue;
        if (raw['voucher_type'] == voucherType && raw['prefix'] == prefix) {
          return raw['require_approval'] as bool? ?? false;
        }
      }
      return false;
    });
  }

  Future<Result<SalesInvoicePostResult>> post(SalesInvoiceDraft draft) =>
      _itemQty.post(draft);

  Future<Result<VoucherLifecycleResult>> updateDraft(
    int id,
    SalesInvoiceDraft draft,
  ) => _itemQty.updateDraft(id, draft);

  Future<Result<VoucherLifecycleResult>> approve(int id) =>
      _itemQty.approve(id);

  Future<Result<VoucherLifecycleResult>> reject(int id, String reason) =>
      _itemQty.reject(id, reason);

  Future<Result<VoucherLifecycleResult>> cancel(int id) => _itemQty.cancel(id);

  Future<Result<List<EmployeeLite>>> searchEmployees(String query) {
    return safeCall(() async {
      final res = await _client.dio.get<Object?>(
        '/employee/employees',
        queryParameters: {
          'page': 1,
          'limit': 50,
          if (query.isNotEmpty) 'search': query,
        },
      );
      final all = _listFromEnvelope(res.data, ItemQtyDto.employeeFromJson);
      if (query.isEmpty) return all;
      final q = query.toLowerCase();
      return all
          .where(
            (e) =>
                e.name.toLowerCase().contains(q) ||
                (e.code?.toLowerCase().contains(q) ?? false),
          )
          .toList(growable: false);
    });
  }

  Future<Result<EmployeeLite?>> getEmployee(int id) {
    return safeCall(() async {
      final res = await _client.dio.get<Object?>('/employee/employees/$id');
      final envelope = decodeApiResponse<JsonMap>(
        res.data,
        (j) => j! as JsonMap,
      );
      final data = envelope.data;
      if (data == null) return null;
      return ItemQtyDto.employeeFromJson(data);
    });
  }

  Future<Result<ProjectLite?>> getProject(int id) {
    return safeCall(() async {
      final res = await _client.dio.get<Object?>('/organization/projects/$id');
      final envelope = decodeApiResponse<JsonMap>(
        res.data,
        (j) => j! as JsonMap,
      );
      final data = envelope.data;
      if (data == null) return null;
      return ItemQtyDto.projectFromJson(data);
    });
  }

  Future<Result<List<ProjectLite>>> searchProjects(String query) {
    return safeCall(() async {
      final res = await _client.dio.get<Object?>(
        '/organization/projects',
        queryParameters: {
          'page': 1,
          'limit': 50,
          if (query.isNotEmpty) 'search': query,
        },
      );
      return _listFromEnvelope(res.data, ItemQtyDto.projectFromJson);
    });
  }

  Future<Result<List<SourceVoucherLite>>> searchSourceVouchers({
    required String type,
    String query = '',
  }) {
    final listPath = type == 'SalesOrder'
        ? '/transactions/sales-orders'
        : '/transactions/quotations';
    final nest = type == 'SalesOrder' ? 'sales_order_main' : 'quotation_main';
    return _itemQty.searchSourceVouchers(
      query: query,
      type: type,
      listPath: listPath,
      mainNestKey: nest,
    );
  }

  Future<Result<SourceVoucherLite>> getSourceVoucher({
    required String type,
    required int id,
  }) {
    final detailPattern = type == 'SalesOrder'
        ? '/transactions/sales-orders/:id'
        : '/transactions/quotations/:id';
    final nest = type == 'SalesOrder' ? 'sales_order_main' : 'quotation_main';
    return _itemQty.getSourceVoucher(
      id,
      type: type,
      detailPathPattern: detailPattern,
      mainNestKey: nest,
    );
  }

  List<T> _listFromEnvelope<T>(
    Object? raw,
    T Function(Map<String, dynamic>) map,
  ) {
    final envelope = decodeApiResponse<Object?>(raw, (j) => j);
    final data = envelope.data;
    List<dynamic> items;
    if (data is Map<String, dynamic> && data['items'] is List) {
      items = data['items'] as List<dynamic>;
    } else if (data is List) {
      items = data;
    } else {
      items = const [];
    }
    return [
      for (final rawItem in items)
        if (rawItem is Map<String, dynamic>) map(rawItem),
    ];
  }
}
