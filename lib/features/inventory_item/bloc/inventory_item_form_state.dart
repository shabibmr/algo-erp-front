import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/accounts_ledger/domain/ledger.dart';
import 'package:algo_erp_front/features/inventory_brand/domain/brand.dart';
import 'package:algo_erp_front/features/inventory_category/domain/category.dart';
import 'package:algo_erp_front/features/inventory_group/domain/inventory_group.dart';
import 'package:algo_erp_front/features/inventory_tax_category/domain/tax_category.dart';
import 'package:algo_erp_front/features/inventory_uom/domain/uom.dart';
import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

enum InventoryItemFormStatus {
  initial,
  loading,
  ready,
  submitting,
  success,
  failure,
}

final class InventoryItemFormState extends Equatable {
  const InventoryItemFormState({
    this.status = InventoryItemFormStatus.initial,
    this.entityId,
    this.isEdit = false,
    this.name = '',
    this.code = '',
    this.alias = '',
    this.partNumber = '',
    this.description = '',
    this.nameArabic = '',
    this.inventoryGroupId,
    this.inventoryGroup,
    this.uomId,
    this.uom,
    this.brandId,
    this.brand,
    this.categoryId,
    this.category,
    this.taxCategoryId,
    this.taxCategory,
    this.salesGlLedgerId,
    this.salesGlLedger,
    this.defaultPurchaseLedgerId,
    this.defaultPurchaseLedger,
    this.defaultSalesReturnLedgerId,
    this.defaultSalesReturnLedger,
    this.defaultPurchaseReturnLedgerId,
    this.defaultPurchaseReturnLedger,
    required this.price,
    required this.basePrice,
    required this.standardCost,
    required this.vatRate,
    required this.openingStock,
    required this.reorderLevel,
    this.isPurchaseItem = true,
    this.isSalesItem = true,
    this.isStockItem = true,
    this.isSerialized = false,
    this.isBatchTracked = false,
    this.isService = false,
    this.isPerishable = false,
    this.isActive = true,
    this.errorMessage,
    this.failure,
  });

  final InventoryItemFormStatus status;
  final int? entityId;
  final bool isEdit;

  final String name;
  final String code;
  final String alias;
  final String partNumber;
  final String description;
  final String nameArabic;

  final int? inventoryGroupId;
  final InventoryGroup? inventoryGroup;

  final int? uomId;
  final Uom? uom;

  final int? brandId;
  final Brand? brand;

  final int? categoryId;
  final Category? category;

  final int? taxCategoryId;
  final TaxCategory? taxCategory;

  final int? salesGlLedgerId;
  final Ledger? salesGlLedger;

  final int? defaultPurchaseLedgerId;
  final Ledger? defaultPurchaseLedger;

  final int? defaultSalesReturnLedgerId;
  final Ledger? defaultSalesReturnLedger;

  final int? defaultPurchaseReturnLedgerId;
  final Ledger? defaultPurchaseReturnLedger;

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

  final String? errorMessage;
  final Failure? failure;

  bool get isLoading => status == InventoryItemFormStatus.loading;
  bool get isSubmitting => status == InventoryItemFormStatus.submitting;
  bool get isSuccess => status == InventoryItemFormStatus.success;

  InventoryItemFormState copyWith({
    InventoryItemFormStatus? status,
    int? entityId,
    bool? isEdit,
    String? name,
    String? code,
    String? alias,
    String? partNumber,
    String? description,
    String? nameArabic,
    int? Function()? inventoryGroupId,
    InventoryGroup? Function()? inventoryGroup,
    int? Function()? uomId,
    Uom? Function()? uom,
    int? Function()? brandId,
    Brand? Function()? brand,
    int? Function()? categoryId,
    Category? Function()? category,
    int? Function()? taxCategoryId,
    TaxCategory? Function()? taxCategory,
    int? Function()? salesGlLedgerId,
    Ledger? Function()? salesGlLedger,
    int? Function()? defaultPurchaseLedgerId,
    Ledger? Function()? defaultPurchaseLedger,
    int? Function()? defaultSalesReturnLedgerId,
    Ledger? Function()? defaultSalesReturnLedger,
    int? Function()? defaultPurchaseReturnLedgerId,
    Ledger? Function()? defaultPurchaseReturnLedger,
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
    String? Function()? errorMessage,
    Failure? Function()? failure,
  }) {
    return InventoryItemFormState(
      status: status ?? this.status,
      entityId: entityId ?? this.entityId,
      isEdit: isEdit ?? this.isEdit,
      name: name ?? this.name,
      code: code ?? this.code,
      alias: alias ?? this.alias,
      partNumber: partNumber ?? this.partNumber,
      description: description ?? this.description,
      nameArabic: nameArabic ?? this.nameArabic,
      inventoryGroupId: inventoryGroupId != null
          ? inventoryGroupId()
          : this.inventoryGroupId,
      inventoryGroup: inventoryGroup != null
          ? inventoryGroup()
          : this.inventoryGroup,
      uomId: uomId != null ? uomId() : this.uomId,
      uom: uom != null ? uom() : this.uom,
      brandId: brandId != null ? brandId() : this.brandId,
      brand: brand != null ? brand() : this.brand,
      categoryId: categoryId != null ? categoryId() : this.categoryId,
      category: category != null ? category() : this.category,
      taxCategoryId: taxCategoryId != null
          ? taxCategoryId()
          : this.taxCategoryId,
      taxCategory: taxCategory != null ? taxCategory() : this.taxCategory,
      salesGlLedgerId: salesGlLedgerId != null
          ? salesGlLedgerId()
          : this.salesGlLedgerId,
      salesGlLedger: salesGlLedger != null
          ? salesGlLedger()
          : this.salesGlLedger,
      defaultPurchaseLedgerId: defaultPurchaseLedgerId != null
          ? defaultPurchaseLedgerId()
          : this.defaultPurchaseLedgerId,
      defaultPurchaseLedger: defaultPurchaseLedger != null
          ? defaultPurchaseLedger()
          : this.defaultPurchaseLedger,
      defaultSalesReturnLedgerId: defaultSalesReturnLedgerId != null
          ? defaultSalesReturnLedgerId()
          : this.defaultSalesReturnLedgerId,
      defaultSalesReturnLedger: defaultSalesReturnLedger != null
          ? defaultSalesReturnLedger()
          : this.defaultSalesReturnLedger,
      defaultPurchaseReturnLedgerId: defaultPurchaseReturnLedgerId != null
          ? defaultPurchaseReturnLedgerId()
          : this.defaultPurchaseReturnLedgerId,
      defaultPurchaseReturnLedger: defaultPurchaseReturnLedger != null
          ? defaultPurchaseReturnLedger()
          : this.defaultPurchaseReturnLedger,
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
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      failure: failure != null ? failure() : this.failure,
    );
  }

  @override
  List<Object?> get props => [
    status,
    entityId,
    isEdit,
    name,
    code,
    alias,
    partNumber,
    description,
    nameArabic,
    inventoryGroupId,
    inventoryGroup,
    uomId,
    uom,
    brandId,
    brand,
    categoryId,
    category,
    taxCategoryId,
    taxCategory,
    salesGlLedgerId,
    salesGlLedger,
    defaultPurchaseLedgerId,
    defaultPurchaseLedger,
    defaultSalesReturnLedgerId,
    defaultSalesReturnLedger,
    defaultPurchaseReturnLedgerId,
    defaultPurchaseReturnLedger,
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
    errorMessage,
    failure,
  ];
}
