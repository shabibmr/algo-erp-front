import 'package:equatable/equatable.dart';

sealed class StockVoucherListEvent extends Equatable {
  const StockVoucherListEvent();

  @override
  List<Object?> get props => [];
}

final class StockVoucherListFetchRequested extends StockVoucherListEvent {
  const StockVoucherListFetchRequested();
}

final class StockVoucherListRefreshed extends StockVoucherListEvent {
  const StockVoucherListRefreshed();
}

final class StockVoucherListFilterToggled extends StockVoucherListEvent {
  const StockVoucherListFilterToggled();
}

final class StockVoucherListStartDateChanged extends StockVoucherListEvent {
  const StockVoucherListStartDateChanged(this.startDate);
  final DateTime? startDate;

  @override
  List<Object?> get props => [startDate];
}

final class StockVoucherListEndDateChanged extends StockVoucherListEvent {
  const StockVoucherListEndDateChanged(this.endDate);
  final DateTime? endDate;

  @override
  List<Object?> get props => [endDate];
}

final class StockVoucherListStatusChanged extends StockVoucherListEvent {
  const StockVoucherListStatusChanged(this.status);
  final String? status;

  @override
  List<Object?> get props => [status];
}

final class StockVoucherListPrefixChanged extends StockVoucherListEvent {
  const StockVoucherListPrefixChanged(this.prefix);
  final String prefix;

  @override
  List<Object?> get props => [prefix];
}

final class StockVoucherListSearchChanged extends StockVoucherListEvent {
  const StockVoucherListSearchChanged(this.search);
  final String search;

  @override
  List<Object?> get props => [search];
}

final class StockVoucherListFiltersCleared extends StockVoucherListEvent {
  const StockVoucherListFiltersCleared();
}
