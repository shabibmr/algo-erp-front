import 'package:equatable/equatable.dart';

sealed class CategoryFormEvent extends Equatable {
  const CategoryFormEvent();

  @override
  List<Object?> get props => [];
}

final class CategoryFormInitialized extends CategoryFormEvent {
  const CategoryFormInitialized({this.entityId});

  final int? entityId;

  @override
  List<Object?> get props => [entityId];
}

final class CategoryFormNameChanged extends CategoryFormEvent {
  const CategoryFormNameChanged(this.name);

  final String name;

  @override
  List<Object?> get props => [name];
}

final class CategoryFormCodeChanged extends CategoryFormEvent {
  const CategoryFormCodeChanged(this.code);

  final String code;

  @override
  List<Object?> get props => [code];
}

final class CategoryFormDescriptionChanged extends CategoryFormEvent {
  const CategoryFormDescriptionChanged(this.description);

  final String description;

  @override
  List<Object?> get props => [description];
}

final class CategoryFormSubmitted extends CategoryFormEvent {
  const CategoryFormSubmitted();
}
