import 'package:equatable/equatable.dart';

sealed class ItemPropertyFormEvent extends Equatable {
  const ItemPropertyFormEvent();

  @override
  List<Object?> get props => [];
}

final class ItemPropertyFormInitialized extends ItemPropertyFormEvent {
  const ItemPropertyFormInitialized({this.entityId});

  final int? entityId;

  @override
  List<Object?> get props => [entityId];
}

final class ItemPropertyFormItemIdChanged extends ItemPropertyFormEvent {
  const ItemPropertyFormItemIdChanged(this.itemId);

  final String itemId;

  @override
  List<Object?> get props => [itemId];
}

final class ItemPropertyFormDefaultValueChanged extends ItemPropertyFormEvent {
  const ItemPropertyFormDefaultValueChanged(this.defaultValue);

  final String defaultValue;

  @override
  List<Object?> get props => [defaultValue];
}

final class ItemPropertyFormSubmitted extends ItemPropertyFormEvent {
  const ItemPropertyFormSubmitted();
}
