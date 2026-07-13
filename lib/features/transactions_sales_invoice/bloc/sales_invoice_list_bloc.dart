// Private fields fed by public named params cannot use initializing formals.
// ignore_for_file: prefer_initializing_formals

import 'package:algo_erp_front/features/transactions_sales_invoice/bloc/sales_invoice_list_event.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/bloc/sales_invoice_list_state.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/data/sales_invoice_repository.dart';
import 'package:algo_erp_front/features/transactions_sales_invoice/domain/sales_invoice.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Export pulls far bigger pages than the screen does — the rows never render,
/// so the only cost is bytes over the wire, and fewer round trips is faster.
const _exportPageSize = 200;

/// A backstop, not a business rule: an unbounded loop against a filter that
/// matches the whole ledger would hammer the server and blow up memory. The
/// view tells the user when this trims the file.
const _exportRowCap = 5000;

class SalesInvoiceListBloc
    extends Bloc<SalesInvoiceListEvent, SalesInvoiceListState> {
  SalesInvoiceListBloc({required SalesInvoiceRepository repository})
    : _repository = repository,
      super(const SalesInvoiceListState()) {
    on<SalesInvoiceListFetchRequested>(_onFetchRequested);
    on<SalesInvoiceListRefreshed>(_onRefreshed, transformer: droppable());
    // Scroll-to-end fires this repeatedly; drop the duplicates rather than
    // queue them, or one flick would append the same page several times.
    on<SalesInvoiceListLoadMoreRequested>(
      _onLoadMoreRequested,
      transformer: droppable(),
    );
    // An export walks every page; a second tap while one is running would
    // double the traffic and race to hand the view two files.
    on<SalesInvoiceListExportRequested>(
      _onExportRequested,
      transformer: droppable(),
    );
    on<SalesInvoiceListExportHandled>(_onExportHandled);
    on<SalesInvoiceListFilterToggled>(_onFilterToggled);
    on<SalesInvoiceListStartDateChanged>(_onStartDateChanged);
    on<SalesInvoiceListEndDateChanged>(_onEndDateChanged);
    on<SalesInvoiceListStatusChanged>(_onStatusChanged);
    on<SalesInvoiceListPrefixChanged>(_onPrefixChanged);
    on<SalesInvoiceListCustomerChanged>(_onCustomerChanged);
    on<SalesInvoiceListSearchChanged>(_onSearchChanged);
    on<SalesInvoiceListFiltersCleared>(_onFiltersCleared);
    on<SalesInvoiceListFiltersApplied>(_onFiltersApplied);
  }

  final SalesInvoiceRepository _repository;

  Future<void> _onFetchRequested(
    SalesInvoiceListFetchRequested event,
    Emitter<SalesInvoiceListState> emit,
  ) async {
    emit(state.copyWith(status: SalesInvoiceListStatus.loading));
    await _loadFirstPage(emit);
  }

  Future<void> _onRefreshed(
    SalesInvoiceListRefreshed event,
    Emitter<SalesInvoiceListState> emit,
  ) => _loadFirstPage(emit);

  Future<void> _onFiltersApplied(
    SalesInvoiceListFiltersApplied event,
    Emitter<SalesInvoiceListState> emit,
  ) async {
    emit(state.copyWith(status: SalesInvoiceListStatus.loading));
    await _loadFirstPage(emit);
  }

  Future<void> _onFiltersCleared(
    SalesInvoiceListFiltersCleared event,
    Emitter<SalesInvoiceListState> emit,
  ) async {
    emit(
      state.copyWith(
        startDate: () => null,
        endDate: () => null,
        statusFilter: () => null,
        prefix: '',
        customer: () => null,
        search: '',
        status: SalesInvoiceListStatus.loading,
      ),
    );
    await _loadFirstPage(emit);
  }

  /// Always re-reads from page 1: a changed filter invalidates every page we
  /// already hold, so the accumulated items are dropped, not appended to.
  Future<void> _loadFirstPage(Emitter<SalesInvoiceListState> emit) async {
    final result = await _repository.list(state.query.firstPage());
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: SalesInvoiceListStatus.failure,
          failure: () => failure,
          isLoadingMore: false,
        ),
      ),
      (page) => emit(
        state.copyWith(
          status: SalesInvoiceListStatus.success,
          items: page.items,
          page: 1,
          meta: () => page.meta,
          failure: () => null,
          isLoadingMore: false,
        ),
      ),
    );
  }

  Future<void> _onLoadMoreRequested(
    SalesInvoiceListLoadMoreRequested event,
    Emitter<SalesInvoiceListState> emit,
  ) async {
    if (!state.isSuccess || !state.hasMore || state.isLoadingMore) return;

    emit(state.copyWith(isLoadingMore: true));

    final nextPage = state.page + 1;
    final result = await _repository.list(state.query.copyWith(page: nextPage));

    result.fold(
      // Keep the pages already on screen — a failed append must not blow the
      // list away. The page counter stays put so a retry re-asks for the same
      // page rather than skipping it.
      (failure) =>
          emit(state.copyWith(isLoadingMore: false, failure: () => failure)),
      (page) => emit(
        state.copyWith(
          items: [...state.items, ...page.items],
          page: nextPage,
          meta: () => page.meta,
          isLoadingMore: false,
          failure: () => null,
        ),
      ),
    );
  }

  /// Gathers every row matching the current filters — not just the pages
  /// already scrolled into view, which would silently export a partial file.
  ///
  /// Writing the bytes is a side effect and belongs to the view, so the rows
  /// are parked in state and the view is left to turn them into a file.
  Future<void> _onExportRequested(
    SalesInvoiceListExportRequested event,
    Emitter<SalesInvoiceListState> emit,
  ) async {
    if (state.isExporting) return;

    emit(state.copyWith(isExporting: true, export: () => null));

    final base = state.query.copyWith(limit: _exportPageSize);
    final rows = <SalesInvoiceListItem>[];
    var page = 1;
    var totalPages = 1;
    var total = 0;

    while (page <= totalPages && rows.length < _exportRowCap) {
      final result = await _repository.list(base.copyWith(page: page));

      final ok = result.fold(
        (failure) {
          emit(state.copyWith(isExporting: false, failure: () => failure));
          return false;
        },
        (fetched) {
          rows.addAll(fetched.items);
          total = fetched.meta.total;
          totalPages = fetched.meta.totalPages;
          // A page that comes back empty would otherwise spin against a server
          // whose totalPages disagrees with what it actually returns.
          return fetched.items.isNotEmpty;
        },
      );
      if (!ok) return;

      page++;
    }

    emit(
      state.copyWith(
        isExporting: false,
        failure: () => null,
        export: () => SalesInvoiceExport(
          rows: rows.take(_exportRowCap).toList(),
          // Trust the server's count over what we managed to pull, so a capped
          // export still reports the true size of the result set.
          total: total < rows.length ? rows.length : total,
        ),
      ),
    );
  }

  void _onExportHandled(
    SalesInvoiceListExportHandled event,
    Emitter<SalesInvoiceListState> emit,
  ) {
    emit(state.copyWith(export: () => null));
  }

  void _onFilterToggled(
    SalesInvoiceListFilterToggled event,
    Emitter<SalesInvoiceListState> emit,
  ) {
    emit(state.copyWith(filtersExpanded: !state.filtersExpanded));
  }

  void _onStartDateChanged(
    SalesInvoiceListStartDateChanged event,
    Emitter<SalesInvoiceListState> emit,
  ) {
    emit(state.copyWith(startDate: () => event.startDate));
  }

  void _onEndDateChanged(
    SalesInvoiceListEndDateChanged event,
    Emitter<SalesInvoiceListState> emit,
  ) {
    emit(state.copyWith(endDate: () => event.endDate));
  }

  void _onStatusChanged(
    SalesInvoiceListStatusChanged event,
    Emitter<SalesInvoiceListState> emit,
  ) {
    emit(state.copyWith(statusFilter: () => event.status));
  }

  void _onPrefixChanged(
    SalesInvoiceListPrefixChanged event,
    Emitter<SalesInvoiceListState> emit,
  ) {
    emit(state.copyWith(prefix: event.prefix));
  }

  void _onCustomerChanged(
    SalesInvoiceListCustomerChanged event,
    Emitter<SalesInvoiceListState> emit,
  ) {
    emit(state.copyWith(customer: () => event.customer));
  }

  void _onSearchChanged(
    SalesInvoiceListSearchChanged event,
    Emitter<SalesInvoiceListState> emit,
  ) {
    emit(state.copyWith(search: event.search));
  }
}
