import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/accounts_ledger/domain/ledger.dart';
import 'package:algo_erp_front/features/accounts_ledger/ledger_di.dart';
import 'package:algo_erp_front/features/inventory_brand/brand_di.dart';
import 'package:algo_erp_front/features/inventory_brand/domain/brand.dart';
import 'package:algo_erp_front/features/inventory_category/category_di.dart';
import 'package:algo_erp_front/features/inventory_category/domain/category.dart';
import 'package:algo_erp_front/features/inventory_group/domain/inventory_group.dart';
import 'package:algo_erp_front/features/inventory_group/inventory_group_di.dart';
import 'package:algo_erp_front/features/inventory_item/bloc/inventory_item_form_event.dart';
import 'package:algo_erp_front/features/inventory_item/bloc/inventory_item_form_state.dart';
import 'package:algo_erp_front/features/inventory_item/domain/inventory_item.dart';
import 'package:algo_erp_front/features/inventory_tax_category/domain/tax_category.dart';
import 'package:algo_erp_front/features/inventory_tax_category/tax_category_di.dart';
import 'package:algo_erp_front/features/inventory_uom/domain/uom.dart';
import 'package:algo_erp_front/features/inventory_uom/uom_di.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InventoryItemFormBloc
    extends Bloc<InventoryItemFormEvent, InventoryItemFormState> {
  InventoryItemFormBloc({
    required Repository<InventoryItem, int> repository,
    required Repository<InventoryGroup, int> inventoryGroupRepository,
    required Repository<Uom, int> uomRepository,
    required Repository<Brand, int> brandRepository,
    required Repository<Category, int> categoryRepository,
    required Repository<TaxCategory, int> taxCategoryRepository,
    required Repository<Ledger, int> ledgerRepository,
  }) : _repository = repository,
       _inventoryGroupRepository = inventoryGroupRepository,
       _uomRepository = uomRepository,
       _brandRepository = brandRepository,
       _categoryRepository = categoryRepository,
       _taxCategoryRepository = taxCategoryRepository,
       _ledgerRepository = ledgerRepository,
       super(
         InventoryItemFormState(
           price: Decimal.zero,
           basePrice: Decimal.zero,
           standardCost: Decimal.zero,
           vatRate: Decimal.zero,
           openingStock: Decimal.zero,
           reorderLevel: Decimal.zero,
         ),
       ) {
    on<InventoryItemFormInitialized>(_onInitialized);
    on<InventoryItemFormNameChanged>(_onNameChanged);
    on<InventoryItemFormCodeChanged>(_onCodeChanged);
    on<InventoryItemFormAliasChanged>(_onAliasChanged);
    on<InventoryItemFormPartNumberChanged>(_onPartNumberChanged);
    on<InventoryItemFormDescriptionChanged>(_onDescriptionChanged);
    on<InventoryItemFormNameArabicChanged>(_onNameArabicChanged);
    on<InventoryItemFormGroupChanged>(_onGroupChanged);
    on<InventoryItemFormUomChanged>(_onUomChanged);
    on<InventoryItemFormBrandChanged>(_onBrandChanged);
    on<InventoryItemFormCategoryChanged>(_onCategoryChanged);
    on<InventoryItemFormTaxCategoryChanged>(_onTaxCategoryChanged);
    on<InventoryItemFormPriceChanged>(_onPriceChanged);
    on<InventoryItemFormBasePriceChanged>(_onBasePriceChanged);
    on<InventoryItemFormStandardCostChanged>(_onStandardCostChanged);
    on<InventoryItemFormVatRateChanged>(_onVatRateChanged);
    on<InventoryItemFormOpeningStockChanged>(_onOpeningStockChanged);
    on<InventoryItemFormReorderLevelChanged>(_onReorderLevelChanged);
    on<InventoryItemFormSalesGlLedgerChanged>(_onSalesGlLedgerChanged);
    on<InventoryItemFormDefaultPurchaseLedgerChanged>(
      _onDefaultPurchaseLedgerChanged,
    );
    on<InventoryItemFormDefaultSalesReturnLedgerChanged>(
      _onDefaultSalesReturnLedgerChanged,
    );
    on<InventoryItemFormDefaultPurchaseReturnLedgerChanged>(
      _onDefaultPurchaseReturnLedgerChanged,
    );
    on<InventoryItemFormIsPurchaseItemChanged>(_onIsPurchaseItemChanged);
    on<InventoryItemFormIsSalesItemChanged>(_onIsSalesItemChanged);
    on<InventoryItemFormIsStockItemChanged>(_onIsStockItemChanged);
    on<InventoryItemFormIsSerializedChanged>(_onIsSerializedChanged);
    on<InventoryItemFormIsBatchTrackedChanged>(_onIsBatchTrackedChanged);
    on<InventoryItemFormIsServiceChanged>(_onIsServiceChanged);
    on<InventoryItemFormIsPerishableChanged>(_onIsPerishableChanged);
    on<InventoryItemFormIsActiveChanged>(_onIsActiveChanged);
    on<InventoryItemFormSubmitted>(_onSubmitted);
  }

  final Repository<InventoryItem, int> _repository;
  final Repository<InventoryGroup, int> _inventoryGroupRepository;
  final Repository<Uom, int> _uomRepository;
  final Repository<Brand, int> _brandRepository;
  final Repository<Category, int> _categoryRepository;
  final Repository<TaxCategory, int> _taxCategoryRepository;
  final Repository<Ledger, int> _ledgerRepository;

  Future<void> _onInitialized(
    InventoryItemFormInitialized event,
    Emitter<InventoryItemFormState> emit,
  ) async {
    if (event.entityId == null) {
      emit(
        state.copyWith(status: InventoryItemFormStatus.ready, isEdit: false),
      );
      return;
    }

    emit(
      state.copyWith(
        status: InventoryItemFormStatus.loading,
        entityId: event.entityId,
        isEdit: true,
      ),
    );

    final result = await _repository.getById(event.entityId!);
    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            status: InventoryItemFormStatus.failure,
            failure: () => failure,
          ),
        );
      },
      (item) async {
        InventoryGroup? group;
        if (item.inventoryGroupId != null) {
          final res = await _inventoryGroupRepository.getById(
            item.inventoryGroupId!,
          );
          group = res.fold((_) => null, (g) => g);
        }

        Uom? uom;
        if (item.uomId != null) {
          final res = await _uomRepository.getById(item.uomId!);
          uom = res.fold((_) => null, (u) => u);
        }

        Brand? brand;
        if (item.brandId != null) {
          final res = await _brandRepository.getById(item.brandId!);
          brand = res.fold((_) => null, (b) => b);
        }

        Category? category;
        if (item.categoryId != null) {
          final res = await _categoryRepository.getById(item.categoryId!);
          category = res.fold((_) => null, (c) => c);
        }

        TaxCategory? taxCategory;
        if (item.taxCategoryId != null) {
          final res = await _taxCategoryRepository.getById(item.taxCategoryId!);
          taxCategory = res.fold((_) => null, (t) => t);
        }

        Ledger? salesGlLedger;
        if (item.salesGlLedgerId != null) {
          final res = await _ledgerRepository.getById(item.salesGlLedgerId!);
          salesGlLedger = res.fold((_) => null, (l) => l);
        }

        Ledger? defaultPurchaseLedger;
        if (item.defaultPurchaseLedgerId != null) {
          final res = await _ledgerRepository.getById(
            item.defaultPurchaseLedgerId!,
          );
          defaultPurchaseLedger = res.fold((_) => null, (l) => l);
        }

        Ledger? defaultSalesReturnLedger;
        if (item.defaultSalesReturnLedgerId != null) {
          final res = await _ledgerRepository.getById(
            item.defaultSalesReturnLedgerId!,
          );
          defaultSalesReturnLedger = res.fold((_) => null, (l) => l);
        }

        Ledger? defaultPurchaseReturnLedger;
        if (item.defaultPurchaseReturnLedgerId != null) {
          final res = await _ledgerRepository.getById(
            item.defaultPurchaseReturnLedgerId!,
          );
          defaultPurchaseReturnLedger = res.fold((_) => null, (l) => l);
        }

        emit(
          state.copyWith(
            status: InventoryItemFormStatus.ready,
            name: item.name,
            code: item.code,
            alias: item.alias ?? '',
            partNumber: item.partNumber ?? '',
            description: item.description ?? '',
            nameArabic: item.nameArabic ?? '',
            inventoryGroupId: () => item.inventoryGroupId,
            inventoryGroup: () => group,
            uomId: () => item.uomId,
            uom: () => uom,
            brandId: () => item.brandId,
            brand: () => brand,
            categoryId: () => item.categoryId,
            category: () => category,
            taxCategoryId: () => item.taxCategoryId,
            taxCategory: () => taxCategory,
            salesGlLedgerId: () => item.salesGlLedgerId,
            salesGlLedger: () => salesGlLedger,
            defaultPurchaseLedgerId: () => item.defaultPurchaseLedgerId,
            defaultPurchaseLedger: () => defaultPurchaseLedger,
            defaultSalesReturnLedgerId: () => item.defaultSalesReturnLedgerId,
            defaultSalesReturnLedger: () => defaultSalesReturnLedger,
            defaultPurchaseReturnLedgerId: () =>
                item.defaultPurchaseReturnLedgerId,
            defaultPurchaseReturnLedger: () => defaultPurchaseReturnLedger,
            price: item.price,
            basePrice: item.basePrice,
            standardCost: item.standardCost,
            vatRate: item.vatRate,
            openingStock: item.openingStock,
            reorderLevel: item.reorderLevel,
            isPurchaseItem: item.isPurchaseItem,
            isSalesItem: item.isSalesItem,
            isStockItem: item.isStockItem,
            isSerialized: item.isSerialized,
            isBatchTracked: item.isBatchTracked,
            isService: item.isService,
            isPerishable: item.isPerishable,
            isActive: item.isActive,
          ),
        );
      },
    );
  }

  void _onNameChanged(
    InventoryItemFormNameChanged event,
    Emitter<InventoryItemFormState> emit,
  ) {
    emit(state.copyWith(name: event.name));
  }

  void _onCodeChanged(
    InventoryItemFormCodeChanged event,
    Emitter<InventoryItemFormState> emit,
  ) {
    emit(state.copyWith(code: event.code));
  }

  void _onAliasChanged(
    InventoryItemFormAliasChanged event,
    Emitter<InventoryItemFormState> emit,
  ) {
    emit(state.copyWith(alias: event.alias));
  }

  void _onPartNumberChanged(
    InventoryItemFormPartNumberChanged event,
    Emitter<InventoryItemFormState> emit,
  ) {
    emit(state.copyWith(partNumber: event.partNumber));
  }

  void _onDescriptionChanged(
    InventoryItemFormDescriptionChanged event,
    Emitter<InventoryItemFormState> emit,
  ) {
    emit(state.copyWith(description: event.description));
  }

  void _onNameArabicChanged(
    InventoryItemFormNameArabicChanged event,
    Emitter<InventoryItemFormState> emit,
  ) {
    emit(state.copyWith(nameArabic: event.nameArabic));
  }

  void _onGroupChanged(
    InventoryItemFormGroupChanged event,
    Emitter<InventoryItemFormState> emit,
  ) {
    emit(
      state.copyWith(
        inventoryGroup: () => event.group,
        inventoryGroupId: () => event.group?.id,
      ),
    );
  }

  void _onUomChanged(
    InventoryItemFormUomChanged event,
    Emitter<InventoryItemFormState> emit,
  ) {
    emit(state.copyWith(uom: () => event.uom, uomId: () => event.uom?.id));
  }

  void _onBrandChanged(
    InventoryItemFormBrandChanged event,
    Emitter<InventoryItemFormState> emit,
  ) {
    emit(
      state.copyWith(brand: () => event.brand, brandId: () => event.brand?.id),
    );
  }

  void _onCategoryChanged(
    InventoryItemFormCategoryChanged event,
    Emitter<InventoryItemFormState> emit,
  ) {
    emit(
      state.copyWith(
        category: () => event.category,
        categoryId: () => event.category?.id,
      ),
    );
  }

  void _onTaxCategoryChanged(
    InventoryItemFormTaxCategoryChanged event,
    Emitter<InventoryItemFormState> emit,
  ) {
    emit(
      state.copyWith(
        taxCategory: () => event.taxCategory,
        taxCategoryId: () => event.taxCategory?.id,
      ),
    );
  }

  void _onPriceChanged(
    InventoryItemFormPriceChanged event,
    Emitter<InventoryItemFormState> emit,
  ) {
    emit(state.copyWith(price: event.price));
  }

  void _onBasePriceChanged(
    InventoryItemFormBasePriceChanged event,
    Emitter<InventoryItemFormState> emit,
  ) {
    emit(state.copyWith(basePrice: event.basePrice));
  }

  void _onStandardCostChanged(
    InventoryItemFormStandardCostChanged event,
    Emitter<InventoryItemFormState> emit,
  ) {
    emit(state.copyWith(standardCost: event.standardCost));
  }

  void _onVatRateChanged(
    InventoryItemFormVatRateChanged event,
    Emitter<InventoryItemFormState> emit,
  ) {
    emit(state.copyWith(vatRate: event.vatRate));
  }

  void _onOpeningStockChanged(
    InventoryItemFormOpeningStockChanged event,
    Emitter<InventoryItemFormState> emit,
  ) {
    emit(state.copyWith(openingStock: event.openingStock));
  }

  void _onReorderLevelChanged(
    InventoryItemFormReorderLevelChanged event,
    Emitter<InventoryItemFormState> emit,
  ) {
    emit(state.copyWith(reorderLevel: event.reorderLevel));
  }

  void _onSalesGlLedgerChanged(
    InventoryItemFormSalesGlLedgerChanged event,
    Emitter<InventoryItemFormState> emit,
  ) {
    emit(
      state.copyWith(
        salesGlLedger: () => event.ledger,
        salesGlLedgerId: () => event.ledger?.id,
      ),
    );
  }

  void _onDefaultPurchaseLedgerChanged(
    InventoryItemFormDefaultPurchaseLedgerChanged event,
    Emitter<InventoryItemFormState> emit,
  ) {
    emit(
      state.copyWith(
        defaultPurchaseLedger: () => event.ledger,
        defaultPurchaseLedgerId: () => event.ledger?.id,
      ),
    );
  }

  void _onDefaultSalesReturnLedgerChanged(
    InventoryItemFormDefaultSalesReturnLedgerChanged event,
    Emitter<InventoryItemFormState> emit,
  ) {
    emit(
      state.copyWith(
        defaultSalesReturnLedger: () => event.ledger,
        defaultSalesReturnLedgerId: () => event.ledger?.id,
      ),
    );
  }

  void _onDefaultPurchaseReturnLedgerChanged(
    InventoryItemFormDefaultPurchaseReturnLedgerChanged event,
    Emitter<InventoryItemFormState> emit,
  ) {
    emit(
      state.copyWith(
        defaultPurchaseReturnLedger: () => event.ledger,
        defaultPurchaseReturnLedgerId: () => event.ledger?.id,
      ),
    );
  }

  void _onIsPurchaseItemChanged(
    InventoryItemFormIsPurchaseItemChanged event,
    Emitter<InventoryItemFormState> emit,
  ) {
    emit(state.copyWith(isPurchaseItem: event.value));
  }

  void _onIsSalesItemChanged(
    InventoryItemFormIsSalesItemChanged event,
    Emitter<InventoryItemFormState> emit,
  ) {
    emit(state.copyWith(isSalesItem: event.value));
  }

  void _onIsStockItemChanged(
    InventoryItemFormIsStockItemChanged event,
    Emitter<InventoryItemFormState> emit,
  ) {
    emit(state.copyWith(isStockItem: event.value));
  }

  void _onIsSerializedChanged(
    InventoryItemFormIsSerializedChanged event,
    Emitter<InventoryItemFormState> emit,
  ) {
    emit(state.copyWith(isSerialized: event.value));
  }

  void _onIsBatchTrackedChanged(
    InventoryItemFormIsBatchTrackedChanged event,
    Emitter<InventoryItemFormState> emit,
  ) {
    emit(state.copyWith(isBatchTracked: event.value));
  }

  void _onIsServiceChanged(
    InventoryItemFormIsServiceChanged event,
    Emitter<InventoryItemFormState> emit,
  ) {
    emit(state.copyWith(isService: event.value));
  }

  void _onIsPerishableChanged(
    InventoryItemFormIsPerishableChanged event,
    Emitter<InventoryItemFormState> emit,
  ) {
    emit(state.copyWith(isPerishable: event.value));
  }

  void _onIsActiveChanged(
    InventoryItemFormIsActiveChanged event,
    Emitter<InventoryItemFormState> emit,
  ) {
    emit(state.copyWith(isActive: event.value));
  }

  Future<void> _onSubmitted(
    InventoryItemFormSubmitted event,
    Emitter<InventoryItemFormState> emit,
  ) async {
    if (state.name.trim().isEmpty) {
      emit(state.copyWith(errorMessage: () => 'Name is required'));
      return;
    }
    if (state.code.trim().isEmpty) {
      emit(state.copyWith(errorMessage: () => 'Code is required'));
      return;
    }

    emit(
      state.copyWith(
        status: InventoryItemFormStatus.submitting,
        errorMessage: () => null,
      ),
    );

    final legacyGroup = state.inventoryGroup != null
        ? (state.inventoryGroup!.groupId.isNotEmpty
              ? state.inventoryGroup!.groupId
              : (state.inventoryGroup!.code != null &&
                        state.inventoryGroup!.code!.isNotEmpty
                    ? state.inventoryGroup!.code!
                    : state.inventoryGroup!.id.toString()))
        : null;

    final item = InventoryItem(
      id: state.entityId ?? 0,
      name: state.name.trim(),
      code: state.code.trim(),
      alias: state.alias.trim().isEmpty ? null : state.alias.trim(),
      partNumber: state.partNumber.trim().isEmpty
          ? null
          : state.partNumber.trim(),
      description: state.description.trim().isEmpty
          ? null
          : state.description.trim(),
      nameArabic: state.nameArabic.trim().isEmpty
          ? null
          : state.nameArabic.trim(),
      inventoryGroupId: state.inventoryGroupId,
      legacyGroupKey: legacyGroup,
      uomId: state.uomId,
      brandId: state.brandId,
      categoryId: state.categoryId,
      taxCategoryId: state.taxCategoryId,
      salesGlLedgerId: state.salesGlLedgerId,
      defaultPurchaseLedgerId: state.defaultPurchaseLedgerId,
      defaultSalesReturnLedgerId: state.defaultSalesReturnLedgerId,
      defaultPurchaseReturnLedgerId: state.defaultPurchaseReturnLedgerId,
      price: state.price,
      basePrice: state.basePrice,
      standardCost: state.standardCost,
      vatRate: state.vatRate,
      openingStock: state.openingStock,
      reorderLevel: state.reorderLevel,
      isPurchaseItem: state.isPurchaseItem,
      isSalesItem: state.isSalesItem,
      isStockItem: state.isStockItem,
      isSerialized: state.isSerialized,
      isBatchTracked: state.isBatchTracked,
      isService: state.isService,
      isPerishable: state.isPerishable,
      isActive: state.isActive,
    );

    if (state.isEdit) {
      final result = await _repository.update(state.entityId!, item);
      result.fold(
        (failure) => emit(
          state.copyWith(
            status: InventoryItemFormStatus.ready,
            errorMessage: () => _messageOf(failure),
          ),
        ),
        (_) => emit(state.copyWith(status: InventoryItemFormStatus.success)),
      );
      return;
    }

    final result = await _repository.create(item);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: InventoryItemFormStatus.ready,
          errorMessage: () => _messageOf(failure),
        ),
      ),
      (_) => emit(state.copyWith(status: InventoryItemFormStatus.success)),
    );
  }

  String _messageOf(Failure f) => switch (f) {
    NetworkFailure(:final message) => message,
    ValidationFailure(:final message) => message,
    ForbiddenFailure(:final message) => message,
    ServerFailure(:final message) => message,
    _ => f.toString(),
  };
}
