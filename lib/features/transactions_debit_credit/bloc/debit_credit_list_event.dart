import 'package:equatable/equatable.dart';

sealed class DebitCreditListEvent extends Equatable {
  const DebitCreditListEvent();

  @override
  List<Object?> get props => [];
}

final class DebitCreditListFetchRequested extends DebitCreditListEvent {
  const DebitCreditListFetchRequested();
}

final class DebitCreditListRefreshed extends DebitCreditListEvent {
  const DebitCreditListRefreshed();
}

final class DebitCreditListFilterToggled extends DebitCreditListEvent {
  const DebitCreditListFilterToggled();
}

final class DebitCreditListStartDateChanged extends DebitCreditListEvent {
  const DebitCreditListStartDateChanged(this.startDate);
  final DateTime? startDate;

  @override
  List<Object?> get props => [startDate];
}

final class DebitCreditListEndDateChanged extends DebitCreditListEvent {
  const DebitCreditListEndDateChanged(this.endDate);
  final DateTime? endDate;

  @override
  List<Object?> get props => [endDate];
}

final class DebitCreditListStatusChanged extends DebitCreditListEvent {
  const DebitCreditListStatusChanged(this.status);
  final String? status;

  @override
  List<Object?> get props => [status];
}

final class DebitCreditListPrefixChanged extends DebitCreditListEvent {
  const DebitCreditListPrefixChanged(this.prefix);
  final String prefix;

  @override
  List<Object?> get props => [prefix];
}

final class DebitCreditListSearchChanged extends DebitCreditListEvent {
  const DebitCreditListSearchChanged(this.search);
  final String search;

  @override
  List<Object?> get props => [search];
}

final class DebitCreditListFiltersCleared extends DebitCreditListEvent {
  const DebitCreditListFiltersCleared();
}
