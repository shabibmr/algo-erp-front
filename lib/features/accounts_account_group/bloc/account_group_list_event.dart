import 'package:equatable/equatable.dart';

sealed class AccountGroupListEvent extends Equatable {
  const AccountGroupListEvent();

  @override
  List<Object?> get props => [];
}

final class AccountGroupListFetchRequested extends AccountGroupListEvent {
  const AccountGroupListFetchRequested();
}

final class AccountGroupListRefreshed extends AccountGroupListEvent {
  const AccountGroupListRefreshed();
}

final class AccountGroupListSearchChanged extends AccountGroupListEvent {
  const AccountGroupListSearchChanged(this.search);
  final String search;

  @override
  List<Object?> get props => [search];
}

final class AccountGroupItemDeleted extends AccountGroupListEvent {
  const AccountGroupItemDeleted(this.id);
  final int id;

  @override
  List<Object?> get props => [id];
}
