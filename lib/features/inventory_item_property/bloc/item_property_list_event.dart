import 'package:equatable/equatable.dart';

sealed class ItemPropertyListEvent extends Equatable {
  const ItemPropertyListEvent();

  @override
  List<Object?> get props => [];
}

final class ItemPropertyListFetchRequested extends ItemPropertyListEvent {
  const ItemPropertyListFetchRequested();
}

final class ItemPropertyListRefreshed extends ItemPropertyListEvent {
  const ItemPropertyListRefreshed();
}

final class ItemPropertyListSearchChanged extends ItemPropertyListEvent {
  const ItemPropertyListSearchChanged(this.search);

  final String search;

  @override
  List<Object?> get props => [search];
}

final class ItemPropertyItemDeleted extends ItemPropertyListEvent {
  const ItemPropertyItemDeleted(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}
