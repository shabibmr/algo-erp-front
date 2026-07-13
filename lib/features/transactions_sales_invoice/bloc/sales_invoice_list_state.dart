import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/network/paginated.dart';
import 'package:algo_erp_front/features/accounts_ledger/domain/ledger.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/domain/sales_invoice.dart';
import 'package:equatable/equatable.dart';

enum SalesInvoiceListStatus { initial, loading, success, failure }

/// A finished export, waiting for the view to turn it into a file.
///
/// The bloc gathers the rows; writing bytes to disk is a side effect and stays
/// in the widget layer. [total] is what the server says matches the filter, so
/// the view can tell the user when the cap trimmed the export rather than
/// letting a short file pass for a complete one.
final class SalesInvoiceExport extends Equatable {
  const SalesInvoiceExport({required this.rows, required this.total});

  final List<SalesInvoiceListItem> rows;
  final int total;

  bool get isTruncated => rows.length < total;

  @override
  List<Object?> get props => [rows, total];
}

final class SalesInvoiceListState extends Equatable {
  const SalesInvoiceListState({
    this.status = SalesInvoiceListStatus.initial,
    this.items = const [],
    this.failure,
    this.page = 1,
    this.meta,
    this.isLoadingMore = false,
    this.isExporting = false,
    this.export,
    this.startDate,
    this.endDate,
    this.statusFilter,
    this.prefix = '',
    this.customer,
    this.search = '',
    this.filtersExpanded = false,
  });

  final SalesInvoiceListStatus status;
  final List<SalesInvoiceListItem> items;
  final Failure? failure;

  /// The page currently held in [items]; load-more asks for `page + 1`.
  final int page;
  final PaginationMeta? meta;
  final bool isLoadingMore;

  final bool isExporting;

  /// One-shot: set when an export finishes, cleared by a
  /// `SalesInvoiceListExportHandled` once the view has written the file.
  final SalesInvoiceExport? export;

  final DateTime? startDate;
  final DateTime? endDate;
  final String? statusFilter;
  final String prefix;
  final Ledger? customer;
  final String search;
  final bool filtersExpanded;

  bool get isLoading => status == SalesInvoiceListStatus.loading;
  bool get isSuccess => status == SalesInvoiceListStatus.success;
  bool get isFailure => status == SalesInvoiceListStatus.failure;

  /// False until the first page lands, so scroll-to-end can't fire early.
  bool get hasMore => meta?.hasMore ?? false;

  /// Server-reported row count across all pages — null before the first page.
  int? get total => meta?.total;

  String? _formatYmd(DateTime? d) {
    if (d == null) return null;
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  PageQuery get query => PageQuery(
    page: page,
    search: search.isEmpty ? null : search,
    filters: {
      if (_formatYmd(startDate) != null) 'start_date': _formatYmd(startDate),
      if (_formatYmd(endDate) != null) 'end_date': _formatYmd(endDate),
      if (statusFilter != null) 'status': statusFilter,
      if (prefix.trim().isNotEmpty) 'prefix': prefix.trim(),
      if (customer != null) 'ledger_id': customer!.id,
    },
  );

  /// Nullable fields take a closure: `?? this.failure` left a stale failure
  /// pinned to the state forever, since it could never be nulled back out.
  SalesInvoiceListState copyWith({
    SalesInvoiceListStatus? status,
    List<SalesInvoiceListItem>? items,
    Failure? Function()? failure,
    int? page,
    PaginationMeta? Function()? meta,
    bool? isLoadingMore,
    bool? isExporting,
    SalesInvoiceExport? Function()? export,
    DateTime? Function()? startDate,
    DateTime? Function()? endDate,
    String? Function()? statusFilter,
    String? prefix,
    Ledger? Function()? customer,
    String? search,
    bool? filtersExpanded,
  }) {
    return SalesInvoiceListState(
      status: status ?? this.status,
      items: items ?? this.items,
      failure: failure != null ? failure() : this.failure,
      page: page ?? this.page,
      meta: meta != null ? meta() : this.meta,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isExporting: isExporting ?? this.isExporting,
      export: export != null ? export() : this.export,
      startDate: startDate != null ? startDate() : this.startDate,
      endDate: endDate != null ? endDate() : this.endDate,
      statusFilter: statusFilter != null ? statusFilter() : this.statusFilter,
      prefix: prefix ?? this.prefix,
      customer: customer != null ? customer() : this.customer,
      search: search ?? this.search,
      filtersExpanded: filtersExpanded ?? this.filtersExpanded,
    );
  }

  @override
  List<Object?> get props => [
    status,
    items,
    failure,
    page,
    meta,
    isLoadingMore,
    isExporting,
    export,
    startDate,
    endDate,
    statusFilter,
    prefix,
    customer,
    search,
    filtersExpanded,
  ];
}
