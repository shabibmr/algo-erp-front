import 'package:equatable/equatable.dart';

sealed class LedgerListEvent extends Equatable {
  const LedgerListEvent();

  @override
  List<Object?> get props => [];
}

final class LedgerListFetchRequested extends LedgerListEvent {
  const LedgerListFetchRequested();
}

final class LedgerListRefreshed extends LedgerListEvent {
  const LedgerListRefreshed();
}

final class LedgerListSearchChanged extends LedgerListEvent {
  const LedgerListSearchChanged(this.search);
  final String search;

  @override
  List<Object?> get props => [search];
}

final class LedgerItemDeleted extends LedgerListEvent {
  const LedgerItemDeleted(this.id);
  final int id;

  @override
  List<Object?> get props => [id];
}
