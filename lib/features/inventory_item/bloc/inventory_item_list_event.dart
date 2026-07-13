import 'package:equatable/equatable.dart';

sealed class InventoryItemListEvent extends Equatable {
  const InventoryItemListEvent();

  @override
  List<Object?> get props => [];
}

final class InventoryItemListFetchRequested extends InventoryItemListEvent {
  const InventoryItemListFetchRequested();
}

final class InventoryItemListRefreshed extends InventoryItemListEvent {
  const InventoryItemListRefreshed();
}

final class InventoryItemListSearchChanged extends InventoryItemListEvent {
  const InventoryItemListSearchChanged(this.search);

  final String search;

  @override
  List<Object?> get props => [search];
}

final class InventoryItemItemDeleted extends InventoryItemListEvent {
  const InventoryItemItemDeleted(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}
