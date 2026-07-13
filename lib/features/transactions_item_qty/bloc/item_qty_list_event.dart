import 'package:algo_erp_front/features/accounts_ledger/domain/ledger.dart';
import 'package:equatable/equatable.dart';

sealed class ItemQtyListEvent extends Equatable {
  const ItemQtyListEvent();

  @override
  List<Object?> get props => [];
}

final class ItemQtyListFetchRequested extends ItemQtyListEvent {
  const ItemQtyListFetchRequested();
}

final class ItemQtyListRefreshed extends ItemQtyListEvent {
  const ItemQtyListRefreshed();
}

final class ItemQtyListFilterToggled extends ItemQtyListEvent {
  const ItemQtyListFilterToggled();
}

final class ItemQtyListStartDateChanged extends ItemQtyListEvent {
  const ItemQtyListStartDateChanged(this.startDate);
  final DateTime? startDate;

  @override
  List<Object?> get props => [startDate];
}

final class ItemQtyListEndDateChanged extends ItemQtyListEvent {
  const ItemQtyListEndDateChanged(this.endDate);
  final DateTime? endDate;

  @override
  List<Object?> get props => [endDate];
}

final class ItemQtyListStatusChanged extends ItemQtyListEvent {
  const ItemQtyListStatusChanged(this.status);
  final String? status;

  @override
  List<Object?> get props => [status];
}

final class ItemQtyListPrefixChanged extends ItemQtyListEvent {
  const ItemQtyListPrefixChanged(this.prefix);
  final String prefix;

  @override
  List<Object?> get props => [prefix];
}

final class ItemQtyListPartyChanged extends ItemQtyListEvent {
  const ItemQtyListPartyChanged(this.party);
  final Ledger? party;

  @override
  List<Object?> get props => [party];
}

final class ItemQtyListSearchChanged extends ItemQtyListEvent {
  const ItemQtyListSearchChanged(this.search);
  final String search;

  @override
  List<Object?> get props => [search];
}

final class ItemQtyListFiltersCleared extends ItemQtyListEvent {
  const ItemQtyListFiltersCleared();
}
