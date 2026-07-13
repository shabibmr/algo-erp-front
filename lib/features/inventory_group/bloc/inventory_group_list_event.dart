import 'package:equatable/equatable.dart';

sealed class InventoryGroupListEvent extends Equatable {
  const InventoryGroupListEvent();

  @override
  List<Object?> get props => [];
}

final class InventoryGroupListFetchRequested extends InventoryGroupListEvent {
  const InventoryGroupListFetchRequested();
}

final class InventoryGroupListRefreshed extends InventoryGroupListEvent {
  const InventoryGroupListRefreshed();
}

final class InventoryGroupListSearchChanged extends InventoryGroupListEvent {
  const InventoryGroupListSearchChanged(this.search);

  final String search;

  @override
  List<Object?> get props => [search];
}

final class InventoryGroupItemDeleted extends InventoryGroupListEvent {
  const InventoryGroupItemDeleted(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}
