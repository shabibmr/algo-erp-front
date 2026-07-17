import 'package:algo_erp_front/features/accounts_ledger/domain/ledger.dart';
import 'package:equatable/equatable.dart';

sealed class SalesInvoiceListEvent extends Equatable {
  const SalesInvoiceListEvent();

  @override
  List<Object?> get props => [];
}

final class SalesInvoiceListFetchRequested extends SalesInvoiceListEvent {
  const SalesInvoiceListFetchRequested();
}

final class SalesInvoiceListRefreshed extends SalesInvoiceListEvent {
  const SalesInvoiceListRefreshed();
}

/// Appends the next page. Fired on scroll-to-end; the bloc ignores it when
/// there is no next page or one is already in flight, so the list view can
/// dispatch freely.
final class SalesInvoiceListLoadMoreRequested extends SalesInvoiceListEvent {
  const SalesInvoiceListLoadMoreRequested();
}

final class SalesInvoiceListFilterToggled extends SalesInvoiceListEvent {
  const SalesInvoiceListFilterToggled();
}

final class SalesInvoiceListStartDateChanged extends SalesInvoiceListEvent {
  const SalesInvoiceListStartDateChanged(this.startDate);
  final DateTime? startDate;

  @override
  List<Object?> get props => [startDate];
}

final class SalesInvoiceListEndDateChanged extends SalesInvoiceListEvent {
  const SalesInvoiceListEndDateChanged(this.endDate);
  final DateTime? endDate;

  @override
  List<Object?> get props => [endDate];
}

final class SalesInvoiceListStatusChanged extends SalesInvoiceListEvent {
  const SalesInvoiceListStatusChanged(this.status);
  final String? status;

  @override
  List<Object?> get props => [status];
}

final class SalesInvoiceListPrefixChanged extends SalesInvoiceListEvent {
  const SalesInvoiceListPrefixChanged(this.prefix);
  final String prefix;

  @override
  List<Object?> get props => [prefix];
}

final class SalesInvoiceListCustomerChanged extends SalesInvoiceListEvent {
  const SalesInvoiceListCustomerChanged(this.customer);
  final Ledger? customer;

  @override
  List<Object?> get props => [customer];
}

final class SalesInvoiceListSearchChanged extends SalesInvoiceListEvent {
  const SalesInvoiceListSearchChanged(this.search);
  final String search;

  @override
  List<Object?> get props => [search];
}

final class SalesInvoiceListFiltersCleared extends SalesInvoiceListEvent {
  const SalesInvoiceListFiltersCleared();
}

final class SalesInvoiceListFiltersApplied extends SalesInvoiceListEvent {
  const SalesInvoiceListFiltersApplied();
}
