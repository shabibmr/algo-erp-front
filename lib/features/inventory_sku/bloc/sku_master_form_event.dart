import 'package:algo_erp_front/features/inventory_item/domain/inventory_item.dart';
import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

sealed class SkuMasterFormEvent extends Equatable {
  const SkuMasterFormEvent();

  @override
  List<Object?> get props => [];
}

final class SkuMasterFormInitialized extends SkuMasterFormEvent {
  const SkuMasterFormInitialized({this.entityId});

  final int? entityId;

  @override
  List<Object?> get props => [entityId];
}

final class SkuMasterFormItemChanged extends SkuMasterFormEvent {
  const SkuMasterFormItemChanged(this.item);

  final InventoryItem? item;

  @override
  List<Object?> get props => [item];
}

final class SkuMasterFormLegacyItemIdChanged extends SkuMasterFormEvent {
  const SkuMasterFormLegacyItemIdChanged(this.legacyItemId);

  final String legacyItemId;

  @override
  List<Object?> get props => [legacyItemId];
}

final class SkuMasterFormNameChanged extends SkuMasterFormEvent {
  const SkuMasterFormNameChanged(this.name);

  final String name;

  @override
  List<Object?> get props => [name];
}

final class SkuMasterFormCodeChanged extends SkuMasterFormEvent {
  const SkuMasterFormCodeChanged(this.code);

  final String code;

  @override
  List<Object?> get props => [code];
}

final class SkuMasterFormBarcodeChanged extends SkuMasterFormEvent {
  const SkuMasterFormBarcodeChanged(this.barcode);

  final String barcode;

  @override
  List<Object?> get props => [barcode];
}

final class SkuMasterFormRateChanged extends SkuMasterFormEvent {
  const SkuMasterFormRateChanged(this.rate);

  final Decimal rate;

  @override
  List<Object?> get props => [rate];
}

final class SkuMasterFormDescriptionChanged extends SkuMasterFormEvent {
  const SkuMasterFormDescriptionChanged(this.description);

  final String description;

  @override
  List<Object?> get props => [description];
}

final class SkuMasterFormSkuTypeChanged extends SkuMasterFormEvent {
  const SkuMasterFormSkuTypeChanged(this.skuType);

  final int? skuType;

  @override
  List<Object?> get props => [skuType];
}

final class SkuMasterFormValueChanged extends SkuMasterFormEvent {
  const SkuMasterFormValueChanged(this.value);

  final String value;

  @override
  List<Object?> get props => [value];
}

final class SkuMasterFormPossibleValuesChanged extends SkuMasterFormEvent {
  const SkuMasterFormPossibleValuesChanged(this.possibleValues);

  final String possibleValues;

  @override
  List<Object?> get props => [possibleValues];
}

final class SkuMasterFormSubmitted extends SkuMasterFormEvent {
  const SkuMasterFormSubmitted();
}
