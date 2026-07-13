import 'package:algo_erp_front/features/accounts_ledger/domain/ledger.dart';
import 'package:algo_erp_front/features/inventory_brand/domain/brand.dart';
import 'package:algo_erp_front/features/inventory_category/domain/category.dart';
import 'package:algo_erp_front/features/inventory_group/domain/inventory_group.dart';
import 'package:algo_erp_front/features/inventory_tax_category/domain/tax_category.dart';
import 'package:algo_erp_front/features/inventory_uom/domain/uom.dart';
import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

sealed class InventoryItemFormEvent extends Equatable {
  const InventoryItemFormEvent();

  @override
  List<Object?> get props => [];
}

final class InventoryItemFormInitialized extends InventoryItemFormEvent {
  const InventoryItemFormInitialized({this.entityId});

  final int? entityId;

  @override
  List<Object?> get props => [entityId];
}

final class InventoryItemFormNameChanged extends InventoryItemFormEvent {
  const InventoryItemFormNameChanged(this.name);

  final String name;

  @override
  List<Object?> get props => [name];
}

final class InventoryItemFormCodeChanged extends InventoryItemFormEvent {
  const InventoryItemFormCodeChanged(this.code);

  final String code;

  @override
  List<Object?> get props => [code];
}

final class InventoryItemFormAliasChanged extends InventoryItemFormEvent {
  const InventoryItemFormAliasChanged(this.alias);

  final String alias;

  @override
  List<Object?> get props => [alias];
}

final class InventoryItemFormPartNumberChanged extends InventoryItemFormEvent {
  const InventoryItemFormPartNumberChanged(this.partNumber);

  final String partNumber;

  @override
  List<Object?> get props => [partNumber];
}

final class InventoryItemFormDescriptionChanged extends InventoryItemFormEvent {
  const InventoryItemFormDescriptionChanged(this.description);

  final String description;

  @override
  List<Object?> get props => [description];
}

final class InventoryItemFormNameArabicChanged extends InventoryItemFormEvent {
  const InventoryItemFormNameArabicChanged(this.nameArabic);

  final String nameArabic;

  @override
  List<Object?> get props => [nameArabic];
}

final class InventoryItemFormGroupChanged extends InventoryItemFormEvent {
  const InventoryItemFormGroupChanged(this.group);

  final InventoryGroup? group;

  @override
  List<Object?> get props => [group];
}

final class InventoryItemFormUomChanged extends InventoryItemFormEvent {
  const InventoryItemFormUomChanged(this.uom);

  final Uom? uom;

  @override
  List<Object?> get props => [uom];
}

final class InventoryItemFormBrandChanged extends InventoryItemFormEvent {
  const InventoryItemFormBrandChanged(this.brand);

  final Brand? brand;

  @override
  List<Object?> get props => [brand];
}

final class InventoryItemFormCategoryChanged extends InventoryItemFormEvent {
  const InventoryItemFormCategoryChanged(this.category);

  final Category? category;

  @override
  List<Object?> get props => [category];
}

final class InventoryItemFormTaxCategoryChanged extends InventoryItemFormEvent {
  const InventoryItemFormTaxCategoryChanged(this.taxCategory);

  final TaxCategory? taxCategory;

  @override
  List<Object?> get props => [taxCategory];
}

final class InventoryItemFormPriceChanged extends InventoryItemFormEvent {
  const InventoryItemFormPriceChanged(this.price);

  final Decimal price;

  @override
  List<Object?> get props => [price];
}

final class InventoryItemFormBasePriceChanged extends InventoryItemFormEvent {
  const InventoryItemFormBasePriceChanged(this.basePrice);

  final Decimal basePrice;

  @override
  List<Object?> get props => [basePrice];
}

final class InventoryItemFormStandardCostChanged
    extends InventoryItemFormEvent {
  const InventoryItemFormStandardCostChanged(this.standardCost);

  final Decimal standardCost;

  @override
  List<Object?> get props => [standardCost];
}

final class InventoryItemFormVatRateChanged extends InventoryItemFormEvent {
  const InventoryItemFormVatRateChanged(this.vatRate);

  final Decimal vatRate;

  @override
  List<Object?> get props => [vatRate];
}

final class InventoryItemFormOpeningStockChanged
    extends InventoryItemFormEvent {
  const InventoryItemFormOpeningStockChanged(this.openingStock);

  final Decimal openingStock;

  @override
  List<Object?> get props => [openingStock];
}

final class InventoryItemFormReorderLevelChanged
    extends InventoryItemFormEvent {
  const InventoryItemFormReorderLevelChanged(this.reorderLevel);

  final Decimal reorderLevel;

  @override
  List<Object?> get props => [reorderLevel];
}

final class InventoryItemFormSalesGlLedgerChanged
    extends InventoryItemFormEvent {
  const InventoryItemFormSalesGlLedgerChanged(this.ledger);

  final Ledger? ledger;

  @override
  List<Object?> get props => [ledger];
}

final class InventoryItemFormDefaultPurchaseLedgerChanged
    extends InventoryItemFormEvent {
  const InventoryItemFormDefaultPurchaseLedgerChanged(this.ledger);

  final Ledger? ledger;

  @override
  List<Object?> get props => [ledger];
}

final class InventoryItemFormDefaultSalesReturnLedgerChanged
    extends InventoryItemFormEvent {
  const InventoryItemFormDefaultSalesReturnLedgerChanged(this.ledger);

  final Ledger? ledger;

  @override
  List<Object?> get props => [ledger];
}

final class InventoryItemFormDefaultPurchaseReturnLedgerChanged
    extends InventoryItemFormEvent {
  const InventoryItemFormDefaultPurchaseReturnLedgerChanged(this.ledger);

  final Ledger? ledger;

  @override
  List<Object?> get props => [ledger];
}

final class InventoryItemFormIsPurchaseItemChanged
    extends InventoryItemFormEvent {
  const InventoryItemFormIsPurchaseItemChanged(this.value);

  final bool value;

  @override
  List<Object?> get props => [value];
}

final class InventoryItemFormIsSalesItemChanged extends InventoryItemFormEvent {
  const InventoryItemFormIsSalesItemChanged(this.value);

  final bool value;

  @override
  List<Object?> get props => [value];
}

final class InventoryItemFormIsStockItemChanged extends InventoryItemFormEvent {
  const InventoryItemFormIsStockItemChanged(this.value);

  final bool value;

  @override
  List<Object?> get props => [value];
}

final class InventoryItemFormIsSerializedChanged
    extends InventoryItemFormEvent {
  const InventoryItemFormIsSerializedChanged(this.value);

  final bool value;

  @override
  List<Object?> get props => [value];
}

final class InventoryItemFormIsBatchTrackedChanged
    extends InventoryItemFormEvent {
  const InventoryItemFormIsBatchTrackedChanged(this.value);

  final bool value;

  @override
  List<Object?> get props => [value];
}

final class InventoryItemFormIsServiceChanged extends InventoryItemFormEvent {
  const InventoryItemFormIsServiceChanged(this.value);

  final bool value;

  @override
  List<Object?> get props => [value];
}

final class InventoryItemFormIsPerishableChanged
    extends InventoryItemFormEvent {
  const InventoryItemFormIsPerishableChanged(this.value);

  final bool value;

  @override
  List<Object?> get props => [value];
}

final class InventoryItemFormIsActiveChanged extends InventoryItemFormEvent {
  const InventoryItemFormIsActiveChanged(this.value);

  final bool value;

  @override
  List<Object?> get props => [value];
}

final class InventoryItemFormSubmitted extends InventoryItemFormEvent {
  const InventoryItemFormSubmitted();
}
