import 'package:equatable/equatable.dart';

sealed class AddressBookListEvent extends Equatable {
  const AddressBookListEvent();

  @override
  List<Object?> get props => [];
}

final class AddressBookListFetchRequested extends AddressBookListEvent {
  const AddressBookListFetchRequested();
}

final class AddressBookListRefreshed extends AddressBookListEvent {
  const AddressBookListRefreshed();
}

final class AddressBookListSearchChanged extends AddressBookListEvent {
  const AddressBookListSearchChanged(this.search);
  final String search;

  @override
  List<Object?> get props => [search];
}

final class AddressBookItemDeleted extends AddressBookListEvent {
  const AddressBookItemDeleted(this.id);
  final int id;

  @override
  List<Object?> get props => [id];
}
