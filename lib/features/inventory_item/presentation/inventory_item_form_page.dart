import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:decimal/decimal.dart';
import 'package:algo_erp_front/core/surfaces/master_form_surface.dart';
import 'package:algo_erp_front/core/widgets/fields/app_decimal_field.dart';
import 'package:algo_erp_front/core/widgets/fields/app_text_field.dart';
import 'package:algo_erp_front/core/widgets/lookup/fk_lookup_field.dart';
import 'package:algo_erp_front/core/widgets/states/error_state.dart';
import 'package:algo_erp_front/core/widgets/states/loading_state.dart';
import 'package:algo_erp_front/features/accounts_ledger/domain/ledger.dart';
import 'package:algo_erp_front/features/accounts_ledger/ledger_di.dart';
import 'package:algo_erp_front/features/inventory_brand/brand_di.dart';
import 'package:algo_erp_front/features/inventory_brand/domain/brand.dart';
import 'package:algo_erp_front/features/inventory_category/category_di.dart';
import 'package:algo_erp_front/features/inventory_category/domain/category.dart';
import 'package:algo_erp_front/features/inventory_group/domain/inventory_group.dart';
import 'package:algo_erp_front/features/inventory_group/inventory_group_di.dart';
import 'package:algo_erp_front/features/inventory_item/bloc/inventory_item_form_bloc.dart';
import 'package:algo_erp_front/features/inventory_item/bloc/inventory_item_form_event.dart';
import 'package:algo_erp_front/features/inventory_item/bloc/inventory_item_form_state.dart';
import 'package:algo_erp_front/features/inventory_item/inventory_item_di.dart';
import 'package:algo_erp_front/features/inventory_item/inventory_item_manifest.dart';
import 'package:algo_erp_front/features/inventory_tax_category/domain/tax_category.dart';
import 'package:algo_erp_front/features/inventory_tax_category/tax_category_di.dart';
import 'package:algo_erp_front/features/inventory_uom/domain/uom.dart';
import 'package:algo_erp_front/features/inventory_uom/uom_di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

final DioClient _dio = getIt<DioClient>();
final _itemRepo = createInventoryItemRepository(_dio);
final _groupRepo = createInventoryGroupRepository(_dio);
final _uomRepo = createUomRepository(_dio);
final _brandRepo = createBrandRepository(_dio);
final _categoryRepo = createCategoryRepository(_dio);
final _taxCategoryRepo = createTaxCategoryRepository(_dio);
final _ledgerRepo = createLedgerRepository(_dio);

class InventoryItemFormPage extends StatelessWidget {
  const InventoryItemFormPage({required this.mode, super.key, this.entityId});

  final FormMode mode;
  final int? entityId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InventoryItemFormBloc>(
      create: (_) => InventoryItemFormBloc(
        repository: _itemRepo,
        inventoryGroupRepository: _groupRepo,
        uomRepository: _uomRepo,
        brandRepository: _brandRepo,
        categoryRepository: _categoryRepo,
        taxCategoryRepository: _taxCategoryRepo,
        ledgerRepository: _ledgerRepo,
      )..add(InventoryItemFormInitialized(entityId: entityId)),
      child: BlocListener<InventoryItemFormBloc, InventoryItemFormState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: (context, state) {
          if (state.isSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.isEdit
                      ? 'Item updated successfully'
                      : 'Item created successfully',
                ),
              ),
            );
            context.go(inventoryItemManifest.resourcePath);
          }
        },
        child: const _InventoryItemFormView(),
      ),
    );
  }
}

class _InventoryItemFormView extends StatelessWidget {
  const _InventoryItemFormView();

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      child: BlocBuilder<InventoryItemFormBloc, InventoryItemFormState>(
        builder: (context, state) {
          final bloc = context.read<InventoryItemFormBloc>();

          if (state.isLoading) {
            return const LoadingState();
          }
          if (state.status == InventoryItemFormStatus.failure) {
            return ErrorState(
              failure:
                  state.failure ?? const Failure.unknown('Failed to load item'),
              onRetry: () => bloc.add(
                InventoryItemFormInitialized(entityId: state.entityId),
              ),
            );
          }

          final title = state.isEdit ? 'Edit Item' : 'New Item';

          return DefaultTabController(
            length: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      onPressed: () =>
                          context.go(inventoryItemManifest.resourcePath),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (state.errorMessage != null) ...[
                  Text(
                    state.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                const TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: [
                    Tab(text: 'General'),
                    Tab(text: 'Categorization'),
                    Tab(text: 'Pricing & Cost'),
                    Tab(text: 'Stock Settings'),
                    Tab(text: 'GL Accounts'),
                    Tab(text: 'Status & Toggles'),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TabBarView(
                    children: [
                      // General Tab
                      _buildGeneralTab(bloc, state),
                      // Categorization Tab
                      _buildCategorizationTab(bloc, state),
                      // Pricing & Cost Tab
                      _buildPricingTab(bloc, state),
                      // Stock Settings Tab
                      _buildStockTab(bloc, state),
                      // GL Accounts Tab
                      _buildGlAccountsTab(bloc, state),
                      // Status & Toggles Tab
                      _buildStatusTab(bloc, state),
                    ],
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: state.isSubmitting
                            ? null
                            : () => context.go(
                                inventoryItemManifest.resourcePath,
                              ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: state.isSubmitting
                            ? null
                            : () =>
                                  bloc.add(const InventoryItemFormSubmitted()),
                        child: state.isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Save'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGeneralTab(
    InventoryItemFormBloc bloc,
    InventoryItemFormState state,
  ) {
    return SingleChildScrollView(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              AppTextField(
                label: 'Name',
                value: state.name,
                hintText: 'e.g. Wireless Mouse',
                onChanged: (v) => bloc.add(InventoryItemFormNameChanged(v)),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Code',
                value: state.code,
                hintText: 'e.g. WM-01',
                onChanged: (v) => bloc.add(InventoryItemFormCodeChanged(v)),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Alias',
                value: state.alias,
                hintText: 'e.g. Mouse Wireless',
                onChanged: (v) => bloc.add(InventoryItemFormAliasChanged(v)),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Part Number',
                value: state.partNumber,
                hintText: 'Optional part number',
                onChanged: (v) =>
                    bloc.add(InventoryItemFormPartNumberChanged(v)),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Description',
                value: state.description,
                hintText: 'Optional description',
                onChanged: (v) =>
                    bloc.add(InventoryItemFormDescriptionChanged(v)),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Name (Arabic)',
                value: state.nameArabic,
                hintText: 'Optional Arabic name',
                onChanged: (v) =>
                    bloc.add(InventoryItemFormNameArabicChanged(v)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorizationTab(
    InventoryItemFormBloc bloc,
    InventoryItemFormState state,
  ) {
    return SingleChildScrollView(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              FkLookupField<InventoryGroup>(
                label: 'Item Group',
                value: state.inventoryGroup,
                displayOf: (g) => g.fullPath ?? g.name,
                loader: (q) async {
                  final res = await _groupRepo.list(PageQuery(search: q));
                  return res.fold((_) => const [], (p) => p.items);
                },
                onSelected: (g) => bloc.add(InventoryItemFormGroupChanged(g)),
              ),
              const SizedBox(height: 12),
              FkLookupField<Uom>(
                label: 'UOM',
                value: state.uom,
                displayOf: (u) => (u.code == null || u.code!.isEmpty)
                    ? u.name
                    : '${u.code} — ${u.name}',
                loader: (q) async {
                  final res = await _uomRepo.list(PageQuery(search: q));
                  return res.fold((_) => const [], (p) => p.items);
                },
                onSelected: (u) => bloc.add(InventoryItemFormUomChanged(u)),
              ),
              const SizedBox(height: 12),
              FkLookupField<Brand>(
                label: 'Brand',
                value: state.brand,
                displayOf: (b) => b.name,
                loader: (q) async {
                  final res = await _brandRepo.list(PageQuery(search: q));
                  return res.fold((_) => const [], (p) => p.items);
                },
                onSelected: (b) => bloc.add(InventoryItemFormBrandChanged(b)),
              ),
              const SizedBox(height: 12),
              FkLookupField<Category>(
                label: 'Category',
                value: state.category,
                displayOf: (c) => c.name,
                loader: (q) async {
                  final res = await _categoryRepo.list(PageQuery(search: q));
                  return res.fold((_) => const [], (p) => p.items);
                },
                onSelected: (c) =>
                    bloc.add(InventoryItemFormCategoryChanged(c)),
              ),
              const SizedBox(height: 12),
              FkLookupField<TaxCategory>(
                label: 'Tax Category',
                value: state.taxCategory,
                displayOf: (t) => '${t.name} (${t.rate}%)',
                loader: (q) async {
                  final res = await _taxCategoryRepo.list(PageQuery(search: q));
                  return res.fold((_) => const [], (p) => p.items);
                },
                onSelected: (t) =>
                    bloc.add(InventoryItemFormTaxCategoryChanged(t)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPricingTab(
    InventoryItemFormBloc bloc,
    InventoryItemFormState state,
  ) {
    return SingleChildScrollView(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              AppDecimalField(
                label: 'Price',
                value: state.price,
                onChanged: (v) =>
                    bloc.add(InventoryItemFormPriceChanged(v ?? Decimal.zero)),
              ),
              const SizedBox(height: 12),
              AppDecimalField(
                label: 'Base Price',
                value: state.basePrice,
                onChanged: (v) => bloc.add(
                  InventoryItemFormBasePriceChanged(v ?? Decimal.zero),
                ),
              ),
              const SizedBox(height: 12),
              AppDecimalField(
                label: 'Standard Cost',
                value: state.standardCost,
                onChanged: (v) => bloc.add(
                  InventoryItemFormStandardCostChanged(v ?? Decimal.zero),
                ),
              ),
              const SizedBox(height: 12),
              AppDecimalField(
                label: 'VAT Rate %',
                value: state.vatRate,
                onChanged: (v) => bloc.add(
                  InventoryItemFormVatRateChanged(v ?? Decimal.zero),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStockTab(
    InventoryItemFormBloc bloc,
    InventoryItemFormState state,
  ) {
    return SingleChildScrollView(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              AppDecimalField(
                label: 'Opening Stock',
                value: state.openingStock,
                onChanged: (v) => bloc.add(
                  InventoryItemFormOpeningStockChanged(v ?? Decimal.zero),
                ),
              ),
              const SizedBox(height: 12),
              AppDecimalField(
                label: 'Reorder Level',
                value: state.reorderLevel,
                onChanged: (v) => bloc.add(
                  InventoryItemFormReorderLevelChanged(v ?? Decimal.zero),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlAccountsTab(
    InventoryItemFormBloc bloc,
    InventoryItemFormState state,
  ) {
    return SingleChildScrollView(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildLedgerLookup(
                label: 'Sales GL Ledger',
                value: state.salesGlLedger,
                onSelected: (l) =>
                    bloc.add(InventoryItemFormSalesGlLedgerChanged(l)),
              ),
              const SizedBox(height: 12),
              _buildLedgerLookup(
                label: 'Purchase Ledger',
                value: state.defaultPurchaseLedger,
                onSelected: (l) =>
                    bloc.add(InventoryItemFormDefaultPurchaseLedgerChanged(l)),
              ),
              const SizedBox(height: 12),
              _buildLedgerLookup(
                label: 'Sales Return Ledger',
                value: state.defaultSalesReturnLedger,
                onSelected: (l) => bloc.add(
                  InventoryItemFormDefaultSalesReturnLedgerChanged(l),
                ),
              ),
              const SizedBox(height: 12),
              _buildLedgerLookup(
                label: 'Purchase Return Ledger',
                value: state.defaultPurchaseReturnLedger,
                onSelected: (l) => bloc.add(
                  InventoryItemFormDefaultPurchaseReturnLedgerChanged(l),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLedgerLookup({
    required String label,
    required Ledger? value,
    required ValueChanged<Ledger?> onSelected,
  }) {
    return FkLookupField<Ledger>(
      label: label,
      value: value,
      displayOf: (l) => (l.code == null || l.code!.isEmpty)
          ? l.name
          : '${l.code} — ${l.name}',
      loader: (q) async {
        final res = await _ledgerRepo.list(PageQuery(search: q));
        return res.fold((_) => const [], (p) => p.items);
      },
      onSelected: onSelected,
    );
  }

  Widget _buildStatusTab(
    InventoryItemFormBloc bloc,
    InventoryItemFormState state,
  ) {
    return SingleChildScrollView(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Purchase Item'),
                value: state.isPurchaseItem,
                onChanged: (v) =>
                    bloc.add(InventoryItemFormIsPurchaseItemChanged(v)),
              ),
              SwitchListTile(
                title: const Text('Sales Item'),
                value: state.isSalesItem,
                onChanged: (v) =>
                    bloc.add(InventoryItemFormIsSalesItemChanged(v)),
              ),
              SwitchListTile(
                title: const Text('Stock Item'),
                value: state.isStockItem,
                onChanged: (v) =>
                    bloc.add(InventoryItemFormIsStockItemChanged(v)),
              ),
              SwitchListTile(
                title: const Text('Serialized'),
                value: state.isSerialized,
                onChanged: (v) =>
                    bloc.add(InventoryItemFormIsSerializedChanged(v)),
              ),
              SwitchListTile(
                title: const Text('Batch Tracked'),
                value: state.isBatchTracked,
                onChanged: (v) =>
                    bloc.add(InventoryItemFormIsBatchTrackedChanged(v)),
              ),
              SwitchListTile(
                title: const Text('Service'),
                value: state.isService,
                onChanged: (v) =>
                    bloc.add(InventoryItemFormIsServiceChanged(v)),
              ),
              SwitchListTile(
                title: const Text('Perishable'),
                value: state.isPerishable,
                onChanged: (v) =>
                    bloc.add(InventoryItemFormIsPerishableChanged(v)),
              ),
              SwitchListTile(
                title: const Text('Active'),
                value: state.isActive,
                onChanged: (v) => bloc.add(InventoryItemFormIsActiveChanged(v)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
