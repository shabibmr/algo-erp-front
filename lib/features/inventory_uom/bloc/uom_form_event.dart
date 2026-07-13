import 'package:equatable/equatable.dart';

sealed class UomFormEvent extends Equatable {
  const UomFormEvent();

  @override
  List<Object?> get props => [];
}

final class UomFormInitialized extends UomFormEvent {
  const UomFormInitialized({this.entityId});
  final int? entityId;

  @override
  List<Object?> get props => [entityId];
}

final class UomFormNameChanged extends UomFormEvent {
  const UomFormNameChanged(this.name);
  final String name;

  @override
  List<Object?> get props => [name];
}

final class UomFormCodeChanged extends UomFormEvent {
  const UomFormCodeChanged(this.code);
  final String code;

  @override
  List<Object?> get props => [code];
}

final class UomFormSymbolChanged extends UomFormEvent {
  const UomFormSymbolChanged(this.symbol);
  final String symbol;

  @override
  List<Object?> get props => [symbol];
}

final class UomFormDecimalPlacesChanged extends UomFormEvent {
  const UomFormDecimalPlacesChanged(this.decimalPlaces);
  final int decimalPlaces;

  @override
  List<Object?> get props => [decimalPlaces];
}

final class UomFormSubmitted extends UomFormEvent {
  const UomFormSubmitted();
}
