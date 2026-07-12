import 'package:algo_erp_front/core/data/mapper.dart';
import 'package:algo_erp_front/features/inventory_item/data/inventory_item_dto.dart';
import 'package:algo_erp_front/features/inventory_item/domain/inventory_item.dart';
import 'package:decimal/decimal.dart';

class InventoryItemMapper implements Mapper<InventoryItemDto, InventoryItem> {
  const InventoryItemMapper();

  static Decimal _d(String raw) => Decimal.tryParse(raw) ?? Decimal.zero;

  @override
  InventoryItem toEntity(InventoryItemDto dto) => InventoryItem(
        id: dto.id,
        name: dto.itemName,
        code: dto.itemCode,
        alias: dto.itemAlias,
        partNumber: dto.partNumber,
        description: dto.itemDescription,
        nameArabic: dto.itemNameArabic,
        inventoryGroupId: dto.inventoryGroupId,
        legacyGroupKey: dto.legacyGroupKey,
        uomId: dto.uomId,
        brandId: dto.inventoryBrandId,
        categoryId: dto.categoryId,
        taxCategoryId: dto.defaultTaxCategoryId,
        salesGlLedgerId: dto.salesGlLedgerId,
        defaultPurchaseLedgerId: dto.defaultPurchaseLedgerId,
        defaultSalesReturnLedgerId: dto.defaultSalesReturnLedgerId,
        defaultPurchaseReturnLedgerId: dto.defaultPurchaseReturnLedgerId,
        price: _d(dto.price),
        basePrice: _d(dto.basePrice),
        standardCost: _d(dto.standardCost),
        vatRate: _d(dto.vatRate),
        openingStock: _d(dto.openingStock),
        reorderLevel: _d(dto.reorderLevel),
        isPurchaseItem: dto.isPurchaseItem,
        isSalesItem: dto.isSalesItem,
        isStockItem: dto.isStockItem,
        isSerialized: dto.isSerialized,
        isBatchTracked: dto.isBatchTracked,
        isService: dto.isService,
        isPerishable: dto.isPerishable,
        isActive: dto.isActive,
      );

  @override
  InventoryItemDto toDto(InventoryItem entity) => InventoryItemDto(
        id: entity.id,
        itemName: entity.name,
        itemCode: entity.code,
        itemAlias: entity.alias,
        partNumber: entity.partNumber,
        itemDescription: entity.description,
        itemNameArabic: entity.nameArabic,
        inventoryGroupId: entity.inventoryGroupId,
        legacyGroupKey: entity.legacyGroupKey,
        uomId: entity.uomId,
        inventoryBrandId: entity.brandId,
        categoryId: entity.categoryId,
        defaultTaxCategoryId: entity.taxCategoryId,
        salesGlLedgerId: entity.salesGlLedgerId,
        defaultPurchaseLedgerId: entity.defaultPurchaseLedgerId,
        defaultSalesReturnLedgerId: entity.defaultSalesReturnLedgerId,
        defaultPurchaseReturnLedgerId: entity.defaultPurchaseReturnLedgerId,
        price: entity.price.toString(),
        basePrice: entity.basePrice.toString(),
        standardCost: entity.standardCost.toString(),
        vatRate: entity.vatRate.toString(),
        openingStock: entity.openingStock.toString(),
        reorderLevel: entity.reorderLevel.toString(),
        isPurchaseItem: entity.isPurchaseItem,
        isSalesItem: entity.isSalesItem,
        isStockItem: entity.isStockItem,
        isSerialized: entity.isSerialized,
        isBatchTracked: entity.isBatchTracked,
        isService: entity.isService,
        isPerishable: entity.isPerishable,
        isActive: entity.isActive,
      );
}
