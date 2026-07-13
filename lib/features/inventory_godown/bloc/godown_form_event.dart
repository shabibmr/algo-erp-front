import 'package:equatable/equatable.dart';

sealed class GodownFormEvent extends Equatable {
  const GodownFormEvent();

  @override
  List<Object?> get props => [];
}

final class GodownFormInitialized extends GodownFormEvent {
  const GodownFormInitialized({this.entityId});
  final int? entityId;

  @override
  List<Object?> get props => [entityId];
}

final class GodownFormNameChanged extends GodownFormEvent {
  const GodownFormNameChanged(this.name);
  final String name;

  @override
  List<Object?> get props => [name];
}

final class GodownFormCodeChanged extends GodownFormEvent {
  const GodownFormCodeChanged(this.code);
  final String code;

  @override
  List<Object?> get props => [code];
}

final class GodownFormLocationChanged extends GodownFormEvent {
  const GodownFormLocationChanged(this.location);
  final String location;

  @override
  List<Object?> get props => [location];
}

final class GodownFormNarrationChanged extends GodownFormEvent {
  const GodownFormNarrationChanged(this.narration);
  final String narration;

  @override
  List<Object?> get props => [narration];
}

final class GodownFormIsProfitCentreToggled extends GodownFormEvent {
  const GodownFormIsProfitCentreToggled(this.value);
  final bool value;

  @override
  List<Object?> get props => [value];
}

final class GodownFormIsDefaultToggled extends GodownFormEvent {
  const GodownFormIsDefaultToggled(this.value);
  final bool value;

  @override
  List<Object?> get props => [value];
}

final class GodownFormIsProductionToggled extends GodownFormEvent {
  const GodownFormIsProductionToggled(this.value);
  final bool value;

  @override
  List<Object?> get props => [value];
}

final class GodownFormSubmitted extends GodownFormEvent {
  const GodownFormSubmitted();
}
