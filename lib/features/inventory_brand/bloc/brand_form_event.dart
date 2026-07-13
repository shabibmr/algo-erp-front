import 'package:equatable/equatable.dart';

sealed class BrandFormEvent extends Equatable {
  const BrandFormEvent();

  @override
  List<Object?> get props => [];
}

final class BrandFormInitialized extends BrandFormEvent {
  const BrandFormInitialized({this.entityId});

  final int? entityId;

  @override
  List<Object?> get props => [entityId];
}

final class BrandFormNameChanged extends BrandFormEvent {
  const BrandFormNameChanged(this.name);

  final String name;

  @override
  List<Object?> get props => [name];
}

final class BrandFormDescriptionChanged extends BrandFormEvent {
  const BrandFormDescriptionChanged(this.description);

  final String description;

  @override
  List<Object?> get props => [description];
}

final class BrandFormSubmitted extends BrandFormEvent {
  const BrandFormSubmitted();
}
