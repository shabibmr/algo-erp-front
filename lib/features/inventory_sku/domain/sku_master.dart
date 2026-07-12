import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

const _unset = Object();

/// SKU master — hard-deleted (no `is_active` on `sku_master`).
///
/// `ITEM_ID` is a legacy required string; `inventory_item_id` is the real
/// optional FK to InventoryItem. Form prefers the FK and mirrors the item
/// code (or id) into [itemId] when a parent is picked.
class SkuMaster extends Equatable {
  const SkuMaster({
    required this.id,
    required this.itemId,
    this.code,
    this.inventoryItemId,
    this.name,
    this.barcode,
    this.rate,
    this.description,
    this.skuType,
    this.possibleValues,
    this.value,
  });

  /// Wire values for `SKU_TYPE` (backend `SkuType` enum).
  static const skuTypes = <int, String>{
    1: 'Variant',
    2: 'Bundle',
    3: 'Alternate unit',
  };

  final int id;

  /// Legacy required string column `ITEM_ID`.
  final String itemId;
  final String? code;
  final int? inventoryItemId;
  final String? name;
  final String? barcode;
  final Decimal? rate;
  final String? description;

  /// 1=Variant, 2=Bundle, 3=Alternate unit.
  final int? skuType;
  final String? possibleValues;
  final String? value;

  SkuMaster copyWith({
    int? id,
    String? itemId,
    Object? code = _unset,
    Object? inventoryItemId = _unset,
    Object? name = _unset,
    Object? barcode = _unset,
    Object? rate = _unset,
    Object? description = _unset,
    Object? skuType = _unset,
    Object? possibleValues = _unset,
    Object? value = _unset,
  }) =>
      SkuMaster(
        id: id ?? this.id,
        itemId: itemId ?? this.itemId,
        code: identical(code, _unset) ? this.code : code as String?,
        inventoryItemId: identical(inventoryItemId, _unset)
            ? this.inventoryItemId
            : inventoryItemId as int?,
        name: identical(name, _unset) ? this.name : name as String?,
        barcode:
            identical(barcode, _unset) ? this.barcode : barcode as String?,
        rate: identical(rate, _unset) ? this.rate : rate as Decimal?,
        description: identical(description, _unset)
            ? this.description
            : description as String?,
        skuType:
            identical(skuType, _unset) ? this.skuType : skuType as int?,
        possibleValues: identical(possibleValues, _unset)
            ? this.possibleValues
            : possibleValues as String?,
        value: identical(value, _unset) ? this.value : value as String?,
      );

  @override
  List<Object?> get props => [
        id,
        itemId,
        code,
        inventoryItemId,
        name,
        barcode,
        rate,
        description,
        skuType,
        possibleValues,
        value,
      ];
}
