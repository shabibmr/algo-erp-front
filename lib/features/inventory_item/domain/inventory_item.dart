import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

const _unset = Object();

/// Inventory item master — soft-deleted via `is_active`.
///
/// Identity, classification FKs (incl. inventory group), pricing, stock
/// flags, and GL ledger FKs (cross-module → Accounts).
class InventoryItem extends Equatable {
  const InventoryItem({
    required this.id,
    required this.name,
    required this.code,
    required this.price,
    required this.basePrice,
    required this.standardCost,
    required this.vatRate,
    required this.openingStock,
    required this.reorderLevel,
    this.alias,
    this.partNumber,
    this.description,
    this.nameArabic,
    this.inventoryGroupId,
    this.legacyGroupKey,
    this.uomId,
    this.brandId,
    this.categoryId,
    this.taxCategoryId,
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

  final int id;
  final String name;
  final String code;
  final String? alias;
  final String? partNumber;
  final String? description;
  final String? nameArabic;

  final int? inventoryGroupId;

  /// Legacy `Group_Id` string — filled from the group's `Group_ID` when
  /// the FK picker is used; falls back to id string or `"0"` on write.
  final String? legacyGroupKey;

  final int? uomId;
  final int? brandId;
  final int? categoryId;
  final int? taxCategoryId;

  /// GL postings — optional FKs into `ledger_master` (Accounts).
  final int? salesGlLedgerId;
  final int? defaultPurchaseLedgerId;
  final int? defaultSalesReturnLedgerId;
  final int? defaultPurchaseReturnLedgerId;

  /// Money / rates as [Decimal] — never `double`.
  final Decimal price;
  final Decimal basePrice;
  final Decimal standardCost;
  final Decimal vatRate;
  final Decimal openingStock;
  final Decimal reorderLevel;

  final bool isPurchaseItem;
  final bool isSalesItem;
  final bool isStockItem;
  final bool isSerialized;
  final bool isBatchTracked;
  final bool isService;
  final bool isPerishable;
  final bool isActive;

  InventoryItem copyWith({
    int? id,
    String? name,
    String? code,
    Object? alias = _unset,
    Object? partNumber = _unset,
    Object? description = _unset,
    Object? nameArabic = _unset,
    Object? inventoryGroupId = _unset,
    Object? legacyGroupKey = _unset,
    Object? uomId = _unset,
    Object? brandId = _unset,
    Object? categoryId = _unset,
    Object? taxCategoryId = _unset,
    Object? salesGlLedgerId = _unset,
    Object? defaultPurchaseLedgerId = _unset,
    Object? defaultSalesReturnLedgerId = _unset,
    Object? defaultPurchaseReturnLedgerId = _unset,
    Decimal? price,
    Decimal? basePrice,
    Decimal? standardCost,
    Decimal? vatRate,
    Decimal? openingStock,
    Decimal? reorderLevel,
    bool? isPurchaseItem,
    bool? isSalesItem,
    bool? isStockItem,
    bool? isSerialized,
    bool? isBatchTracked,
    bool? isService,
    bool? isPerishable,
    bool? isActive,
  }) =>
      InventoryItem(
        id: id ?? this.id,
        name: name ?? this.name,
        code: code ?? this.code,
        alias: identical(alias, _unset) ? this.alias : alias as String?,
        partNumber: identical(partNumber, _unset)
            ? this.partNumber
            : partNumber as String?,
        description: identical(description, _unset)
            ? this.description
            : description as String?,
        nameArabic: identical(nameArabic, _unset)
            ? this.nameArabic
            : nameArabic as String?,
        inventoryGroupId: identical(inventoryGroupId, _unset)
            ? this.inventoryGroupId
            : inventoryGroupId as int?,
        legacyGroupKey: identical(legacyGroupKey, _unset)
            ? this.legacyGroupKey
            : legacyGroupKey as String?,
        uomId: identical(uomId, _unset) ? this.uomId : uomId as int?,
        brandId: identical(brandId, _unset) ? this.brandId : brandId as int?,
        categoryId: identical(categoryId, _unset)
            ? this.categoryId
            : categoryId as int?,
        taxCategoryId: identical(taxCategoryId, _unset)
            ? this.taxCategoryId
            : taxCategoryId as int?,
        salesGlLedgerId: identical(salesGlLedgerId, _unset)
            ? this.salesGlLedgerId
            : salesGlLedgerId as int?,
        defaultPurchaseLedgerId: identical(defaultPurchaseLedgerId, _unset)
            ? this.defaultPurchaseLedgerId
            : defaultPurchaseLedgerId as int?,
        defaultSalesReturnLedgerId:
            identical(defaultSalesReturnLedgerId, _unset)
                ? this.defaultSalesReturnLedgerId
                : defaultSalesReturnLedgerId as int?,
        defaultPurchaseReturnLedgerId:
            identical(defaultPurchaseReturnLedgerId, _unset)
                ? this.defaultPurchaseReturnLedgerId
                : defaultPurchaseReturnLedgerId as int?,
        price: price ?? this.price,
        basePrice: basePrice ?? this.basePrice,
        standardCost: standardCost ?? this.standardCost,
        vatRate: vatRate ?? this.vatRate,
        openingStock: openingStock ?? this.openingStock,
        reorderLevel: reorderLevel ?? this.reorderLevel,
        isPurchaseItem: isPurchaseItem ?? this.isPurchaseItem,
        isSalesItem: isSalesItem ?? this.isSalesItem,
        isStockItem: isStockItem ?? this.isStockItem,
        isSerialized: isSerialized ?? this.isSerialized,
        isBatchTracked: isBatchTracked ?? this.isBatchTracked,
        isService: isService ?? this.isService,
        isPerishable: isPerishable ?? this.isPerishable,
        isActive: isActive ?? this.isActive,
      );

  @override
  List<Object?> get props => [
        id,
        name,
        code,
        alias,
        partNumber,
        description,
        nameArabic,
        inventoryGroupId,
        legacyGroupKey,
        uomId,
        brandId,
        categoryId,
        taxCategoryId,
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
