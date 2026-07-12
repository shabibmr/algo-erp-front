import 'package:equatable/equatable.dart';

/// Wire shape of `/inventory/sku`, matching `sku_master` + `skuMasterSchema`.
class SkuMasterDto extends Equatable {
  const SkuMasterDto({
    required this.id,
    required this.itemId,
    this.skuCode,
    this.inventoryItemId,
    this.skuName,
    this.barcode,
    this.rate,
    this.skuDescription,
    this.skuType,
    this.skuPossibleValues,
    this.skuValue,
  });

  factory SkuMasterDto.fromJson(Map<String, dynamic> json) {
    final rateRaw = json['rate'];
    return SkuMasterDto(
      id: json['id'] as int,
      itemId: json['ITEM_ID'] as String? ?? '',
      skuCode: json['sku_code'] as String?,
      inventoryItemId: json['inventory_item_id'] as int?,
      skuName: json['sku_name'] as String?,
      barcode: json['barcode'] as String?,
      rate: rateRaw?.toString(),
      skuDescription: json['SKU_DESCRIPTION'] as String?,
      skuType: json['SKU_TYPE'] as int?,
      skuPossibleValues: json['SKU_POSSIBLE_VALUES'] as String?,
      skuValue: json['SKU_VALUE'] as String?,
    );
  }

  final int id;
  final String itemId;
  final String? skuCode;
  final int? inventoryItemId;
  final String? skuName;
  final String? barcode;

  /// Decimal wire as string until the mapper.
  final String? rate;
  final String? skuDescription;
  final int? skuType;
  final String? skuPossibleValues;
  final String? skuValue;

  Map<String, dynamic> toJson() => {
    'ITEM_ID': itemId,
    if (skuCode != null && skuCode!.isNotEmpty) 'sku_code': skuCode,
    'inventory_item_id': inventoryItemId,
    if (skuName != null && skuName!.isNotEmpty) 'sku_name': skuName,
    if (barcode != null && barcode!.isNotEmpty) 'barcode': barcode,
    if (rate != null) 'rate': double.tryParse(rate!) ?? 0,
    if (skuDescription != null && skuDescription!.isNotEmpty)
      'SKU_DESCRIPTION': skuDescription,
    'SKU_TYPE': skuType,
    if (skuPossibleValues != null && skuPossibleValues!.isNotEmpty)
      'SKU_POSSIBLE_VALUES': skuPossibleValues,
    if (skuValue != null && skuValue!.isNotEmpty) 'SKU_VALUE': skuValue,
  };

  @override
  List<Object?> get props => [
    id,
    itemId,
    skuCode,
    inventoryItemId,
    skuName,
    barcode,
    rate,
    skuDescription,
    skuType,
    skuPossibleValues,
    skuValue,
  ];
}
