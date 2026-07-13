import 'package:equatable/equatable.dart';

sealed class LedgerAmountListEvent extends Equatable {
  const LedgerAmountListEvent();

  @override
  List<Object?> get props => [];
}

final class LedgerAmountListFetchRequested extends LedgerAmountListEvent {
  const LedgerAmountListFetchRequested();
}

final class LedgerAmountListRefreshed extends LedgerAmountListEvent {
  const LedgerAmountListRefreshed();
}

final class LedgerAmountListFilterToggled extends LedgerAmountListEvent {
  const LedgerAmountListFilterToggled();
}

final class LedgerAmountListStartDateChanged extends LedgerAmountListEvent {
  const LedgerAmountListStartDateChanged(this.startDate);
  final DateTime? startDate;

  @override
  List<Object?> get props => [startDate];
}

final class LedgerAmountListEndDateChanged extends LedgerAmountListEvent {
  const LedgerAmountListEndDateChanged(this.endDate);
  final DateTime? endDate;

  @override
  List<Object?> get props => [endDate];
}

final class LedgerAmountListStatusChanged extends LedgerAmountListEvent {
  const LedgerAmountListStatusChanged(this.status);
  final String? status;

  @override
  List<Object?> get props => [status];
}

final class LedgerAmountListPrefixChanged extends LedgerAmountListEvent {
  const LedgerAmountListPrefixChanged(this.prefix);
  final String prefix;

  @override
  List<Object?> get props => [prefix];
}

final class LedgerAmountListSearchChanged extends LedgerAmountListEvent {
  const LedgerAmountListSearchChanged(this.search);
  final String search;

  @override
  List<Object?> get props => [search];
}

final class LedgerAmountListFiltersCleared extends LedgerAmountListEvent {
  const LedgerAmountListFiltersCleared();
}
