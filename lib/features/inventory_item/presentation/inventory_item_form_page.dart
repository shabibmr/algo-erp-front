import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_form_surface.dart';
import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/core/widgets/fields/app_decimal_field.dart';
import 'package:algo_erp_front/core/widgets/fields/app_text_field.dart';
import 'package:algo_erp_front/core/widgets/layout/field_widths.dart';
import 'package:algo_erp_front/core/widgets/layout/form_field_layout.dart';
import 'package:algo_erp_front/core/widgets/layout/work_sheet.dart';
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
import 'package:decimal/decimal.dart';
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
    final tokens = context.tokens;

    return AdaptiveLayout(
      maxContentWidth: FieldWidths.formContent,
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                SizedBox(height: tokens.spacing.md),
                if (state.errorMessage != null) ...[
                  Text(
                    state.errorMessage!,
                    style: TextStyle(color: tokens.semanticColors.danger),
                  ),
                  SizedBox(height: tokens.spacing.md),
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
                SizedBox(height: tokens.spacing.md),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildGeneralTab(context, bloc, state),
                      _buildCategorizationTab(context, bloc, state),
                      _buildPricingTab(context, bloc, state),
                      _buildStockTab(context, bloc, state),
                      _buildGlAccountsTab(context, bloc, state),
                      _buildStatusTab(context, bloc, state),
                    ],
                  ),
                ),
                Divider(color: tokens.brand.mist),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: tokens.spacing.md),
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
                      SizedBox(width: tokens.spacing.sm),
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

  Widget _sheet(
    BuildContext context, {
    required List<Widget> children,
  }) {
    final tokens = context.tokens;
    return SingleChildScrollView(
      child: WorkSheet(
        fill: false,
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spacing.md,
          vertical: tokens.spacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }

  List<Widget> _spaced(BuildContext context, List<Widget> fields) {
    final gap = SizedBox(height: context.tokens.spacing.md);
    final out = <Widget>[];
    for (var i = 0; i < fields.length; i++) {
      if (i > 0) out.add(gap);
      out.add(fields[i]);
    }
    return out;
  }

  Widget _buildGeneralTab(
    BuildContext context,
    InventoryItemFormBloc bloc,
    InventoryItemFormState state,
  ) {
    return _sheet(
      context,
      children: _spaced(context, [
        AppTextField(
          label: 'Name',
          value: state.name,
          hintText: 'e.g. Wireless Mouse',
          onChanged: (v) => bloc.add(InventoryItemFormNameChanged(v)),
        ),
        constrainFormField(
          AppTextField(
            label: 'Code',
            value: state.code,
            hintText: 'e.g. WM-01',
            onChanged: (v) => bloc.add(InventoryItemFormCodeChanged(v)),
          ),
          maxWidth: FieldWidths.code,
        ),
        constrainFormField(
          AppTextField(
            label: 'Alias',
            value: state.alias,
            hintText: 'e.g. Mouse Wireless',
            onChanged: (v) => bloc.add(InventoryItemFormAliasChanged(v)),
          ),
          maxWidth: FieldWidths.textShort,
        ),
        constrainFormField(
          AppTextField(
            label: 'Part Number',
            value: state.partNumber,
            hintText: 'Optional part number',
            onChanged: (v) =>
                bloc.add(InventoryItemFormPartNumberChanged(v)),
          ),
          maxWidth: FieldWidths.code,
        ),
        AppTextField(
          label: 'Description',
          value: state.description,
          hintText: 'Optional description',
          onChanged: (v) =>
              bloc.add(InventoryItemFormDescriptionChanged(v)),
        ),
        AppTextField(
          label: 'Name (Arabic)',
          value: state.nameArabic,
          hintText: 'Optional Arabic name',
          onChanged: (v) =>
              bloc.add(InventoryItemFormNameArabicChanged(v)),
        ),
      ]),
    );
  }

  Widget _buildCategorizationTab(
    BuildContext context,
    InventoryItemFormBloc bloc,
    InventoryItemFormState state,
  ) {
    return _sheet(
      context,
      children: _spaced(context, [
        constrainFormField(
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
          maxWidth: FieldWidths.picker,
        ),
        constrainFormField(
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
          maxWidth: FieldWidths.picker,
        ),
        constrainFormField(
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
          maxWidth: FieldWidths.picker,
        ),
        constrainFormField(
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
          maxWidth: FieldWidths.picker,
        ),
        constrainFormField(
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
          maxWidth: FieldWidths.picker,
        ),
      ]),
    );
  }

  Widget _buildPricingTab(
    BuildContext context,
    InventoryItemFormBloc bloc,
    InventoryItemFormState state,
  ) {
    return _sheet(
      context,
      children: _spaced(context, [
        constrainFormField(
          AppDecimalField(
            label: 'Price',
            value: state.price,
            onChanged: (v) =>
                bloc.add(InventoryItemFormPriceChanged(v ?? Decimal.zero)),
          ),
          maxWidth: FieldWidths.number,
        ),
        constrainFormField(
          AppDecimalField(
            label: 'Base Price',
            value: state.basePrice,
            onChanged: (v) => bloc.add(
              InventoryItemFormBasePriceChanged(v ?? Decimal.zero),
            ),
          ),
          maxWidth: FieldWidths.number,
        ),
        constrainFormField(
          AppDecimalField(
            label: 'Standard Cost',
            value: state.standardCost,
            onChanged: (v) => bloc.add(
              InventoryItemFormStandardCostChanged(v ?? Decimal.zero),
            ),
          ),
          maxWidth: FieldWidths.number,
        ),
        constrainFormField(
          AppDecimalField(
            label: 'VAT Rate %',
            value: state.vatRate,
            onChanged: (v) => bloc.add(
              InventoryItemFormVatRateChanged(v ?? Decimal.zero),
            ),
          ),
          maxWidth: FieldWidths.number,
        ),
      ]),
    );
  }

  Widget _buildStockTab(
    BuildContext context,
    InventoryItemFormBloc bloc,
    InventoryItemFormState state,
  ) {
    return _sheet(
      context,
      children: _spaced(context, [
        constrainFormField(
          AppDecimalField(
            label: 'Opening Stock',
            value: state.openingStock,
            onChanged: (v) => bloc.add(
              InventoryItemFormOpeningStockChanged(v ?? Decimal.zero),
            ),
          ),
          maxWidth: FieldWidths.number,
        ),
        constrainFormField(
          AppDecimalField(
            label: 'Reorder Level',
            value: state.reorderLevel,
            onChanged: (v) => bloc.add(
              InventoryItemFormReorderLevelChanged(v ?? Decimal.zero),
            ),
          ),
          maxWidth: FieldWidths.number,
        ),
      ]),
    );
  }

  Widget _buildGlAccountsTab(
    BuildContext context,
    InventoryItemFormBloc bloc,
    InventoryItemFormState state,
  ) {
    return _sheet(
      context,
      children: _spaced(context, [
        constrainFormField(
          _buildLedgerLookup(
            label: 'Sales GL Ledger',
            value: state.salesGlLedger,
            onSelected: (l) =>
                bloc.add(InventoryItemFormSalesGlLedgerChanged(l)),
          ),
          maxWidth: FieldWidths.picker,
        ),
        constrainFormField(
          _buildLedgerLookup(
            label: 'Purchase Ledger',
            value: state.defaultPurchaseLedger,
            onSelected: (l) =>
                bloc.add(InventoryItemFormDefaultPurchaseLedgerChanged(l)),
          ),
          maxWidth: FieldWidths.picker,
        ),
        constrainFormField(
          _buildLedgerLookup(
            label: 'Sales Return Ledger',
            value: state.defaultSalesReturnLedger,
            onSelected: (l) => bloc.add(
              InventoryItemFormDefaultSalesReturnLedgerChanged(l),
            ),
          ),
          maxWidth: FieldWidths.picker,
        ),
        constrainFormField(
          _buildLedgerLookup(
            label: 'Purchase Return Ledger',
            value: state.defaultPurchaseReturnLedger,
            onSelected: (l) => bloc.add(
              InventoryItemFormDefaultPurchaseReturnLedgerChanged(l),
            ),
          ),
          maxWidth: FieldWidths.picker,
        ),
      ]),
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
    BuildContext context,
    InventoryItemFormBloc bloc,
    InventoryItemFormState state,
  ) {
    return _sheet(
      context,
      children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Purchase Item'),
                value: state.isPurchaseItem,
                onChanged: (v) =>
                    bloc.add(InventoryItemFormIsPurchaseItemChanged(v)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Sales Item'),
                value: state.isSalesItem,
                onChanged: (v) =>
                    bloc.add(InventoryItemFormIsSalesItemChanged(v)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Stock Item'),
                value: state.isStockItem,
                onChanged: (v) =>
                    bloc.add(InventoryItemFormIsStockItemChanged(v)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Serialized'),
                value: state.isSerialized,
                onChanged: (v) =>
                    bloc.add(InventoryItemFormIsSerializedChanged(v)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Batch Tracked'),
                value: state.isBatchTracked,
                onChanged: (v) =>
                    bloc.add(InventoryItemFormIsBatchTrackedChanged(v)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Service'),
                value: state.isService,
                onChanged: (v) =>
                    bloc.add(InventoryItemFormIsServiceChanged(v)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Perishable'),
                value: state.isPerishable,
                onChanged: (v) =>
                    bloc.add(InventoryItemFormIsPerishableChanged(v)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: state.isActive,
                onChanged: (v) => bloc.add(InventoryItemFormIsActiveChanged(v)),
              ),
      ],
    );
  }
}
