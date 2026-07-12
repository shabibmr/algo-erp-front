import 'package:algo_erp_front/core/data/remote_data_source.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/error/safe_call.dart';
import 'package:algo_erp_front/core/network/api_response.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/network/paginated.dart';
import 'package:algo_erp_front/core/vouchers/voucher_blueprint.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/data/sales_invoice_dto.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/domain/sales_invoice.dart';
import 'package:dio/dio.dart';

/// Online repository for Sales Invoice list, detail, post, and lifecycle.
///
/// List/detail: `/transactions/sales-invoices`
/// Post: `/transactions/sales-invoice`
/// Lifecycle: `/transactions/SalesInvoice/:id/{approve|reject|cancel}`
class SalesInvoiceRepository {
  SalesInvoiceRepository(this._client);

  final DioClient _client;

  static const _blueprint = VoucherBlueprints.salesInvoice;
  static const _lifecycleType = 'SalesInvoice';

  Future<Result<Paginated<SalesInvoiceListItem>>> list(PageQuery query) {
    return safeCall(() async {
      final params = <String, dynamic>{
        'page': query.page,
        'limit': query.limit,
        if (query.search != null && query.search!.isNotEmpty)
          'search': query.search,
      };
      // Backend ListFilters: start_date, end_date, prefix, financial_year,
      // ledger_id, status (see voucherRead.controller extractFilters).
      query.filters.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          params[key] = value;
        }
      });
      final res = await _client.dio.get<Object?>(
        _blueprint.listPath,
        queryParameters: params,
      );
      final envelope = decodeApiResponse<JsonMap>(
        res.data,
        (j) => j! as JsonMap,
      );
      final data = envelope.data;
      if (data == null) {
        throw const FormatException('Expected paginated sales invoices');
      }
      final page = Paginated<JsonMap>.fromJson(data, (j) => j! as JsonMap);
      return Paginated<SalesInvoiceListItem>(
        items: page.items
            .map(SalesInvoiceDto.listItemFromJson)
            .toList(growable: false),
        meta: page.meta,
      );
    });
  }

  Future<Result<SalesInvoiceDetail>> getById(
    int id, {
    Future<String?> Function(int itemId)? resolveItemLabel,
    Future<String?> Function(int ledgerId)? resolveCustomerLabel,
    Future<String?> Function(int godownId)? resolveGodownLabel,
    Future<String?> Function(int employeeId)? resolveSalespersonLabel,
    Future<String?> Function(int projectId)? resolveProjectLabel,
  }) {
    return safeCall(() async {
      final res = await _client.dio.get<Object?>(_blueprint.detailPath(id));
      final envelope = decodeApiResponse<JsonMap>(
        res.data,
        (j) => j! as JsonMap,
      );
      final data = envelope.data;
      if (data == null) {
        throw const FormatException('Expected sales invoice detail');
      }
      final detail = SalesInvoiceDto.detailFromJson(data);

      var customerLabel = detail.customerLabel;
      var godownLabel = detail.godownLabel;
      var salespersonLabel = detail.salespersonLabel;
      var projectLabel = detail.projectLabel;
      if (resolveCustomerLabel != null && detail.customerLedgerId != null) {
        customerLabel =
            await resolveCustomerLabel(detail.customerLedgerId!) ??
            customerLabel;
      }
      if (resolveGodownLabel != null && detail.godownId != null) {
        godownLabel = await resolveGodownLabel(detail.godownId!) ?? godownLabel;
      }
      if (resolveSalespersonLabel != null &&
          detail.salespersonEmployeeId != null) {
        salespersonLabel =
            await resolveSalespersonLabel(detail.salespersonEmployeeId!) ??
            salespersonLabel;
      }
      if (resolveProjectLabel != null && detail.voucherProjectId != null) {
        projectLabel =
            await resolveProjectLabel(detail.voucherProjectId!) ?? projectLabel;
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
        customerLabel: customerLabel,
        godownLabel: godownLabel,
        salespersonLabel: salespersonLabel,
        projectLabel: projectLabel,
        lines: lines,
      );
    });
  }

  /// Look up series for this voucher type+prefix (approval flag).
  Future<Result<bool?>> seriesRequiresApproval({
    required String voucherType,
    required String prefix,
  }) {
    return safeCall(() async {
      final res = await _client.dio.get<Object?>(
        '/organization/voucher-series',
        queryParameters: {'limit': 1000},
      );
      final envelope = decodeApiResponse<JsonMap>(
        res.data,
        (j) => j! as JsonMap,
      );
      final data = envelope.data;
      if (data == null) return null;
      // May be {items, meta} or bare list depending on list shape.
      List<dynamic> items;
      if (data['items'] is List) {
        items = data['items'] as List<dynamic>;
      } else {
        return null;
      }
      for (final raw in items) {
        if (raw is! Map<String, dynamic>) continue;
        if (raw['voucher_type'] == voucherType && raw['prefix'] == prefix) {
          return raw['require_approval'] as bool? ?? false;
        }
      }
      return false;
    });
  }

  Future<Result<SalesInvoicePostResult>> post(SalesInvoiceDraft draft) {
    return safeCall(() async {
      final res = await _client.dio.post<Object?>(
        _blueprint.postPath,
        data: SalesInvoiceDto.draftToPostJson(draft),
      );
      final envelope = decodeApiResponse<JsonMap>(
        res.data,
        (j) => j! as JsonMap,
      );
      final data = envelope.data;
      if (data == null) {
        throw const FormatException('Expected sales invoice post result');
      }
      return SalesInvoiceDto.postResultFromJson(data);
    });
  }

  /// Draft-only line/header replace via lifecycle edit.
  Future<Result<VoucherLifecycleResult>> updateDraft(
    int id,
    SalesInvoiceDraft draft,
  ) {
    return safeCall(() async {
      final res = await _client.dio.put<Object?>(
        '/transactions/$_lifecycleType/$id',
        data: SalesInvoiceDto.draftToEditJson(draft),
      );
      return _lifecycleBody(res.data);
    });
  }

  Future<Result<VoucherLifecycleResult>> approve(int id) {
    return _lifecycle('approve', id);
  }

  Future<Result<VoucherLifecycleResult>> reject(int id, String reason) {
    return safeCall(() async {
      final res = await _client.dio.post<Object?>(
        '/transactions/$_lifecycleType/$id/reject',
        data: {'reason': reason},
      );
      return _lifecycleBody(res.data);
    });
  }

  Future<Result<VoucherLifecycleResult>> cancel(int id) {
    return _lifecycle('cancel', id);
  }

  Future<Result<VoucherLifecycleResult>> _lifecycle(String action, int id) {
    return safeCall(() async {
      final res = await _client.dio.post<Object?>(
        '/transactions/$_lifecycleType/$id/$action',
      );
      return _lifecycleBody(res.data);
    });
  }

  VoucherLifecycleResult _lifecycleBody(Object? raw) {
    final envelope = decodeApiResponse<JsonMap>(raw, (j) => j! as JsonMap);
    final data = envelope.data;
    if (data == null) {
      throw const FormatException('Expected lifecycle result');
    }
    return SalesInvoiceDto.lifecycleFromJson(data);
  }

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
      // BE listEmployees returns a bare array (not always paginated).
      final all = _listFromEnvelope(res.data, SalesInvoiceDto.employeeFromJson);
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
      return SalesInvoiceDto.employeeFromJson(data);
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
      return SalesInvoiceDto.projectFromJson(data);
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
      return _listFromEnvelope(res.data, SalesInvoiceDto.projectFromJson);
    });
  }

  Future<Result<List<SourceVoucherLite>>> searchSourceVouchers({
    required String type,
    String query = '',
  }) {
    final path = type == 'SalesOrder'
        ? '/transactions/sales-orders'
        : '/transactions/quotations';
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
      if (data == null) return <SourceVoucherLite>[];
      final items = data['items'] as List<dynamic>? ?? const [];
      return [
        for (final raw in items)
          if (raw is Map<String, dynamic>)
            SourceVoucherLite(
              id: raw['id'] as int,
              type: type,
              displayNo: () {
                final p = raw['voucher_prefix'] as String? ?? '';
                final n = raw['voucher_no'] as String? ?? '';
                return (p + n).isEmpty ? '#${raw['id']}' : '$p$n';
              }(),
              billingName:
                  (raw['sales_order_main']
                          as Map<String, dynamic>?)?['Billing_Name']
                      as String? ??
                  (raw['quotation_main']
                          as Map<String, dynamic>?)?['Billing_Name']
                      as String?,
            ),
      ];
    });
  }

  Future<Result<SourceVoucherLite>> getSourceVoucher({
    required String type,
    required int id,
  }) {
    final path = type == 'SalesOrder'
        ? '/transactions/sales-orders/$id'
        : '/transactions/quotations/$id';
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
      return SalesInvoiceDto.sourceFromJson(data, type: type);
    });
  }

  /// Authenticated HTML invoice (backend print template).
  Future<Result<String>> fetchPdfHtml(int id) {
    return safeCall(() async {
      final res = await _client.dio.get<String>(
        '/transactions/sales-invoices/$id/pdf',
        options: Options(
          responseType: ResponseType.plain,
          headers: {'Accept': 'text/html'},
        ),
      );
      final body = res.data;
      if (body == null || body.isEmpty) {
        throw const FormatException('Empty PDF/HTML response');
      }
      return body;
    });
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
