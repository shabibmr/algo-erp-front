import 'package:equatable/equatable.dart';

/// Wire shape of `/inventory/item`, matching `sales_inventory_items` +
/// `inventoryItemSchema`.
class InventoryItemDto extends Equatable {
  const InventoryItemDto({
    required this.id,
    required this.itemName,
    required this.itemCode,
    required this.price,
    required this.basePrice,
    required this.standardCost,
    required this.vatRate,
    required this.openingStock,
    required this.reorderLevel,
    this.itemAlias,
    this.partNumber,
    this.itemDescription,
    this.itemNameArabic,
    this.inventoryGroupId,
    this.legacyGroupKey,
    this.uomId,
    this.inventoryBrandId,
    this.categoryId,
    this.defaultTaxCategoryId,
    this.salesGlLedgerId,
    this.defaultPurchaseLedgerId,
    this.defaultSalesReturnLedgerId,
    this.defaultPurchaseReturnLedgerId,
    this.isPurchaseItem = true,
    this.isSalesItem = true,
    this.isStockItem = true,
    this.isSerialized = false,
    this.isBatchTracked = false,
    this.isService = false,
    this.isPerishable = false,
    this.isActive = true,
  });

  factory InventoryItemDto.fromJson(Map<String, dynamic> json) {
    String asWireNumber(dynamic v, [String fallback = '0']) {
      if (v == null) return fallback;
      return v.toString();
    }

    return InventoryItemDto(
      id: json['id'] as int,
      itemName: json['Item_Name'] as String? ?? '',
      itemCode: json['Item_Code'] as String? ?? '',
      itemAlias: json['Item_Alias'] as String?,
      partNumber: json['Part_Number'] as String?,
      itemDescription: json['Item_Description'] as String?,
      itemNameArabic: json['Item_Name_Arabic'] as String?,
      inventoryGroupId: json['inventory_group_id'] as int?,
      legacyGroupKey: json['Group_Id'] as String?,
      uomId: json['uom_id'] as int?,
      inventoryBrandId: json['inventory_brand_id'] as int?,
      categoryId: json['category_id'] as int?,
      defaultTaxCategoryId: json['default_tax_category_id'] as int?,
      salesGlLedgerId: json['sales_gl_ledger_id'] as int?,
      defaultPurchaseLedgerId: json['default_purchase_ledger_id'] as int?,
      defaultSalesReturnLedgerId:
          json['default_sales_return_ledger_id'] as int?,
      defaultPurchaseReturnLedgerId:
          json['default_purchase_return_ledger_id'] as int?,
      price: asWireNumber(json['Price']),
      basePrice: asWireNumber(json['base_price']),
      standardCost: asWireNumber(json['standard_cost']),
      vatRate: asWireNumber(json['Vat_Rate']),
      openingStock: asWireNumber(json['Opening_Stock']),
      reorderLevel: asWireNumber(json['Reorder_Level']),
      isPurchaseItem: json['is_purchase_item'] as bool? ?? true,
      isSalesItem: json['is_sales_item'] as bool? ?? true,
      isStockItem: json['is_stock_item'] as bool? ?? true,
      isSerialized: json['is_serialized'] as bool? ?? false,
      isBatchTracked: json['is_batch_tracked'] as bool? ?? false,
      isService: json['is_service'] as bool? ?? false,
      isPerishable: json['is_perishable'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  final int id;
  final String itemName;
  final String itemCode;
  final String? itemAlias;
  final String? partNumber;
  final String? itemDescription;
  final String? itemNameArabic;

  final int? inventoryGroupId;
  final String? legacyGroupKey;

  final int? uomId;
  final int? inventoryBrandId;
  final int? categoryId;
  final int? defaultTaxCategoryId;

  final int? salesGlLedgerId;
  final int? defaultPurchaseLedgerId;
  final int? defaultSalesReturnLedgerId;
  final int? defaultPurchaseReturnLedgerId;

  /// Backend accepts numbers; we keep wire strings until the mapper.
  final String price;
  final String basePrice;
  final String standardCost;
  final String vatRate;
  final String openingStock;
  final String reorderLevel;

  final bool isPurchaseItem;
  final bool isSalesItem;
  final bool isStockItem;
  final bool isSerialized;
  final bool isBatchTracked;
  final bool isService;
  final bool isPerishable;
  final bool isActive;

  Map<String, dynamic> toJson() {
    double numOf(String s) => double.tryParse(s) ?? 0;

    // Required legacy string column — prefer group key, else int id, else "0".
    final groupKey = (legacyGroupKey != null && legacyGroupKey!.isNotEmpty)
        ? legacyGroupKey!
        : (inventoryGroupId?.toString() ?? '0');

    return {
      'Item_Name': itemName,
      'Item_Code': itemCode,
      'Group_Id': groupKey,
      if (itemAlias != null && itemAlias!.isNotEmpty) 'Item_Alias': itemAlias,
      if (partNumber != null && partNumber!.isNotEmpty)
        'Part_Number': partNumber,
      if (itemDescription != null && itemDescription!.isNotEmpty)
        'Item_Description': itemDescription,
      if (itemNameArabic != null && itemNameArabic!.isNotEmpty)
        'Item_Name_Arabic': itemNameArabic,
      'inventory_group_id': inventoryGroupId,
      'uom_id': uomId,
      'inventory_brand_id': inventoryBrandId,
      'category_id': categoryId,
      'default_tax_category_id': defaultTaxCategoryId,
      'sales_gl_ledger_id': salesGlLedgerId,
      'default_purchase_ledger_id': defaultPurchaseLedgerId,
      'default_sales_return_ledger_id': defaultSalesReturnLedgerId,
      'default_purchase_return_ledger_id': defaultPurchaseReturnLedgerId,
      'Price': numOf(price),
      'base_price': numOf(basePrice),
      'standard_cost': numOf(standardCost),
      'Vat_Rate': numOf(vatRate),
      'Opening_Stock': numOf(openingStock),
      'Reorder_Level': numOf(reorderLevel),
      'is_purchase_item': isPurchaseItem,
      'is_sales_item': isSalesItem,
      'is_stock_item': isStockItem,
      'is_serialized': isSerialized,
      'is_batch_tracked': isBatchTracked,
      'is_service': isService,
      'is_perishable': isPerishable,
      'is_active': isActive,
    };
  }

  @override
  List<Object?> get props => [
        id,
        itemName,
        itemCode,
        itemAlias,
        partNumber,
        itemDescription,
        itemNameArabic,
        inventoryGroupId,
        legacyGroupKey,
        uomId,
        inventoryBrandId,
        categoryId,
        defaultTaxCategoryId,
        salesGlLedgerId,
        defaultPurchaseLedgerId,
        defaultSalesReturnLedgerId,
        defaultPurchaseReturnLedgerId,
        price,
        basePrice,
        standardCost,
        vatRate,
        openingStock,
        reorderLevel,
        isPurchaseItem,
        isSalesItem,
        isStockItem,
        isSerialized,
        isBatchTracked,
        isService,
        isPerishable,
        isActive,
      ];
}
