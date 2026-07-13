import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/inventory_item/domain/inventory_item.dart';
import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

enum SkuMasterFormStatus {
  initial,
  loading,
  ready,
  submitting,
  success,
  failure,
}

final class SkuMasterFormState extends Equatable {
  const SkuMasterFormState({
    this.status = SkuMasterFormStatus.initial,
    this.entityId,
    this.isEdit = false,
    this.inventoryItem,
    this.legacyItemId = '',
    this.name = '',
    this.code = '',
    this.barcode = '',
    this.rate,
    this.description = '',
    this.skuType,
    this.value = '',
    this.possibleValues = '',
    this.errorMessage,
    this.failure,
  });

  final SkuMasterFormStatus status;
  final int? entityId;
  final bool isEdit;
  final InventoryItem? inventoryItem;
  final String legacyItemId;
  final String name;
  final String code;
  final String barcode;
  final Decimal? rate;
  final String description;
  final int? skuType;
  final String value;
  final String possibleValues;
  final String? errorMessage;
  final Failure? failure;

  bool get isLoading => status == SkuMasterFormStatus.loading;
  bool get isSubmitting => status == SkuMasterFormStatus.submitting;
  bool get isSuccess => status == SkuMasterFormStatus.success;

  SkuMasterFormState copyWith({
    SkuMasterFormStatus? status,
    int? entityId,
    bool? isEdit,
    InventoryItem? Function()? inventoryItem,
    String? legacyItemId,
    String? name,
    String? code,
    String? barcode,
    Decimal? Function()? rate,
    String? description,
    int? Function()? skuType,
    String? value,
    String? possibleValues,
    String? Function()? errorMessage,
    Failure? Function()? failure,
  }) {
    return SkuMasterFormState(
      status: status ?? this.status,
      entityId: entityId ?? this.entityId,
      isEdit: isEdit ?? this.isEdit,
      inventoryItem: inventoryItem != null
          ? inventoryItem()
          : this.inventoryItem,
      legacyItemId: legacyItemId ?? this.legacyItemId,
      name: name ?? this.name,
      code: code ?? this.code,
      barcode: barcode ?? this.barcode,
      rate: rate != null ? rate() : this.rate,
      description: description ?? this.description,
      skuType: skuType != null ? skuType() : this.skuType,
      value: value ?? this.value,
      possibleValues: possibleValues ?? this.possibleValues,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      failure: failure != null ? failure() : this.failure,
    );
  }

  @override
  List<Object?> get props => [
    status,
    entityId,
    isEdit,
    inventoryItem,
    legacyItemId,
    name,
    code,
    barcode,
    rate,
    description,
    skuType,
    value,
    possibleValues,
    errorMessage,
    failure,
  ];
}
