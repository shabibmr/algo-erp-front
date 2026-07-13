import 'package:equatable/equatable.dart';

sealed class UserCredentialsListEvent extends Equatable {
  const UserCredentialsListEvent();

  @override
  List<Object?> get props => [];
}

final class UserCredentialsListFetchRequested extends UserCredentialsListEvent {
  const UserCredentialsListFetchRequested();
}

final class UserCredentialsListRefreshed extends UserCredentialsListEvent {
  const UserCredentialsListRefreshed();
}

final class UserCredentialsListSearchChanged extends UserCredentialsListEvent {
  const UserCredentialsListSearchChanged(this.search);
  final String search;

  @override
  List<Object?> get props => [search];
}

final class UserCredentialsItemDeleted extends UserCredentialsListEvent {
  const UserCredentialsItemDeleted(this.id);
  final int id;

  @override
  List<Object?> get props => [id];
}
