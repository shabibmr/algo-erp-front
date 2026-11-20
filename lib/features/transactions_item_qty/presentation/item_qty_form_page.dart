import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/line_engine/line_engine.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/document_surface.dart';
import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/core/vouchers/item_qty/item_qty_kind.dart';
import 'package:algo_erp_front/core/vouchers/item_qty/item_qty_models.dart';
import 'package:algo_erp_front/core/widgets/data_display/line_item_grid.dart';
import 'package:algo_erp_front/core/widgets/dialogs/variant_picker_dialog.dart';
import 'package:algo_erp_front/core/widgets/fields/app_date_field.dart';
import 'package:algo_erp_front/core/widgets/fields/app_decimal_field.dart';
import 'package:algo_erp_front/core/widgets/fields/app_number_field.dart';
import 'package:algo_erp_front/core/widgets/fields/app_text_field.dart';
import 'package:algo_erp_front/core/widgets/layout/field_widths.dart';
import 'package:algo_erp_front/core/widgets/layout/form_field_layout.dart';
import 'package:algo_erp_front/core/widgets/lookup/fk_lookup_field.dart';
import 'package:algo_erp_front/features/accounts_ledger/domain/ledger.dart';
import 'package:algo_erp_front/features/accounts_ledger/ledger_di.dart';
import 'package:algo_erp_front/features/inventory_godown/domain/godown.dart';
import 'package:algo_erp_front/features/inventory_godown/godown_di.dart';
import 'package:algo_erp_front/features/inventory_item/domain/inventory_item.dart';
import 'package:algo_erp_front/features/inventory_item/inventory_item_di.dart';
import 'package:algo_erp_front/features/inventory_pricelist/domain/price_list.dart';
import 'package:algo_erp_front/features/inventory_pricelist/price_list_di.dart';
import 'package:algo_erp_front/features/transactions_item_qty/cubit/item_qty_form_cubit.dart';
import 'package:algo_erp_front/features/transactions_item_qty/item_qty_di.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Create form for an [ItemQtyVoucherKind] via DocumentSurface + LineEngine.
class ItemQtyFormPage extends StatelessWidget {
  const ItemQtyFormPage({required this.kind, super.key});

  final ItemQtyVoucherKind kind;

  @override
  Widget build(BuildContext context) {
    final dio = getIt<DioClient>();
    return BlocProvider(
      create: (_) => ItemQtyFormCubit(
        kind: kind,
        repository: createItemQtyRepository(dio, kind),
        godownRepository: createGodownRepository(dio),
      ),
      child: _ItemQtyFormView(kind: kind),
    );
  }
}

class _ItemQtyFormView extends StatefulWidget {
  const _ItemQtyFormView({required this.kind});

  final ItemQtyVoucherKind kind;

  @override
  State<_ItemQtyFormView> createState() => _ItemQtyFormViewState();
}

class _ItemQtyFormViewState extends State<_ItemQtyFormView> {
  final _formKey = GlobalKey<FormState>();
  late final _ledgerRepo = createLedgerRepository(getIt<DioClient>());
  late final _godownRepo = createGodownRepository(getIt<DioClient>());
  late final _itemRepo = createInventoryItemRepository(getIt<DioClient>());
  late final _priceListRepo = createPriceListRepository(getIt<DioClient>());

  ItemQtyVoucherKind get kind => widget.kind;

  LineInput? _lineInput(ItemQtyLine row) {
    if (!row.isComplete) return null;
    return LineInput(
      quantity: row.quantity,
      price: row.price,
      discountPercent: row.discountPercent,
      taxRate: row.taxRate,
    );
  }

  InventoryItem _stubItem(ItemQtyLine row) => InventoryItem(
    id: row.itemId!,
    name: row.itemLabel ?? '',
    code: '',
    price: row.price,
    basePrice: Decimal.zero,
    standardCost: Decimal.zero,
    vatRate: row.taxRate,
    openingStock: Decimal.zero,
    reorderLevel: Decimal.zero,
  );

  Widget _header(ItemQtyFormCubit cubit, ItemQtyFormState state) {
    final draft = state.draft;
    final posting = state.posting;
    final tokens = context.tokens;
    final gap = SizedBox(height: tokens.spacing.md);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              constrainFormField(
                AppTextField(
                  label: 'Prefix',
                  value: draft.voucherPrefix,
                  enabled: !posting,
                  onChanged: (v) => cubit.updateDraft(
                    draft.copyWith(
                      voucherPrefix: v.isEmpty
                          ? (kind.blueprint.defaultPrefix ?? '')
                          : v,
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                ),
                maxWidth: FieldWidths.code,
              ),
              SizedBox(width: tokens.spacing.md),
              constrainFormField(
                AppTextField(
                  label: 'Financial year',
                  value: draft.financialYear,
                  enabled: !posting,
                  onChanged: (v) =>
                      cubit.updateDraft(draft.copyWith(financialYear: v)),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                ),
                maxWidth: FieldWidths.code,
              ),
              SizedBox(width: tokens.spacing.md),
              constrainFormField(
                AppDateField(
                  label: 'Voucher date',
                  value: draft.voucherDate,
                  enabled: !posting,
                  onChanged: (d) {
                    if (d != null) {
                      cubit.updateDraft(draft.copyWith(voucherDate: d));
                    }
                  },
                ),
                maxWidth: FieldWidths.date,
              ),
            ],
          ),
          gap,
          constrainFormField(
            FkLookupField<Ledger>(
              label: kind.partyLabel,
              value: state.party,
              enabled: !posting,
              displayOf: (l) {
                final code = l.code;
                return (code == null || code.isEmpty)
                    ? l.name
                    : '$code — ${l.name}';
              },
              loader: (q) async {
                final r = await _ledgerRepo.list(PageQuery(search: q));
                return r.fold((_) => const [], (p) => p.items);
              },
              onSelected: cubit.setParty,
              validator: (v) =>
                  v == null ? '${kind.partyLabel} is required' : null,
            ),
            maxWidth: FieldWidths.picker,
          ),
          if (kind.requiresGodown) ...[
            gap,
            constrainFormField(
              FkLookupField<Godown>(
                label: 'Godown',
                value: state.godown,
                enabled: !posting,
                displayOf: (g) => g.name,
                loader: (q) async {
                  final r = await _godownRepo.list(PageQuery(search: q));
                  return r.fold((_) => const [], (p) => p.items);
                },
                onSelected: cubit.setGodown,
                validator: (v) => v == null ? 'Godown is required' : null,
              ),
              maxWidth: FieldWidths.picker,
            ),
          ],
          if (kind.supportsSource) ...[
            gap,
            constrainFormField(
              FkLookupField<ItemQtySourceLite>(
                label: 'Convert from ${kind.sourceLifecycleType}',
                value: state.source,
                enabled: !posting,
                helperText: 'Optional — loads party, godown, and lines',
                displayOf: (s) => '${s.type} ${s.displayNo}',
                loader: (q) async {
                  final r =
                      await cubit.repository.searchSourceVouchers(query: q);
                  return r.fold((_) => const [], (list) => list);
                },
                onSelected: cubit.applySource,
              ),
              maxWidth: FieldWidths.picker,
            ),
          ],
          gap,
          AppTextField(
            label: 'Billing name',
            value: draft.billingName,
            enabled: !posting,
            onChanged: (v) => cubit.updateDraft(
              draft.copyWith(billingName: v.isEmpty ? null : v),
            ),
          ),
          if (kind.supportsPriceList) ...[
            gap,
            constrainFormField(
              FkLookupField<PriceList>(
                label: 'Price list',
                value: draft.priceListId == null
                    ? null
                    : PriceList(
                        id: draft.priceListId!,
                        name: draft.priceListLabel ?? '',
                      ),
                enabled: !posting,
                displayOf: (p) => p.name,
                loader: (q) async {
                  final r = await _priceListRepo.list(PageQuery(search: q));
                  return r.fold((_) => const [], (p) => p.items);
                },
                onSelected: cubit.setPriceList,
                helperText: 'Rates use this list when items are added',
              ),
              maxWidth: FieldWidths.picker,
            ),
          ],
          if (kind.supportsCreditDays) ...[
            gap,
            constrainFormField(
              AppNumberField(
                label: 'Credit days',
                value: draft.creditDays,
                enabled: !posting,
                onChanged: (v) =>
                    cubit.updateDraft(draft.copyWith(creditDays: v ?? 30)),
              ),
              maxWidth: FieldWidths.number,
            ),
          ],
          gap,
          AppTextField(
            label: 'Narration',
            value: draft.narration,
            enabled: !posting,
            onChanged: (v) => cubit.updateDraft(
              draft.copyWith(narration: v.isEmpty ? null : v),
            ),
          ),
        ],
      ),
    );
  }

  List<LineItemColumn<ItemQtyLine>> _columns(
    ItemQtyFormCubit cubit,
    ItemQtyFormState state,
  ) {
    final posting = state.posting;
    return [
      LineItemColumn(
        label: 'Item',
        flex: 3,
        cellBuilder: (context, row, i) => FkLookupField<InventoryItem>(
          label: 'Item',
          value: row.itemId == null ? null : _stubItem(row),
          enabled: !posting,
          displayOf: (item) =>
              item.code.isEmpty ? item.name : '${item.code} — ${item.name}',
          loader: (q) async {
            final r = await _itemRepo.list(PageQuery(search: q));
            return r.fold((_) => const [], (p) => p.items);
          },
          onSelected: (item) async {
            if (item == null) {
              cubit.updateLine(
                i,
                row.copyWith(
                  itemId: null,
                  itemLabel: null,
                  itemCode: null,
                ),
              );
              return;
            }
            final price = await cubit.resolveLinePrice(item);
            if (!context.mounted) return;
            cubit.updateLine(
              i,
              row.copyWith(
                itemId: item.id,
                itemLabel: item.name,
                itemCode: item.code,
                price: price,
                taxRate: item.vatRate,
                priceLevel: cubit.priceLevelStamp(),
              ),
            );
          },
        ),
      ),
      LineItemColumn(
        label: 'Variant / SKU',
        flex: 2,
        cellBuilder: (context, row, i) {
          if (row.itemId == null) {
            return const SizedBox.shrink();
          }
          final hasVariant = row.skuId != null;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: posting
                      ? null
                      : () async {
                          final result = await VariantPickerDialog.show(
                            context,
                            itemId: row.itemId!,
                            itemName: row.itemLabel ?? 'Item',
                            itemCode: row.itemCode,
                            currentSkuId: row.skuId,
                          );
                          if (result != null) {
                            cubit.updateLine(
                              i,
                              row.copyWith(
                                skuId: result.skuId,
                                skuCode: result.skuCode,
                                skuLabel: result.attributeSummary.isNotEmpty
                                    ? result.attributeSummary
                                    : result.skuCode,
                                price: result.rate != null
                                    ? Decimal.parse(result.rate!.toString())
                                    : row.price,
                              ),
                            );
                          }
                        },
                  icon: Icon(
                    hasVariant ? Icons.check_circle : Icons.tune,
                    size: 14,
                    color: hasVariant ? Colors.green : null,
                  ),
                  label: Text(
                    row.skuLabel ?? row.skuCode ?? 'Select Variant',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              if (hasVariant)
                IconButton(
                  icon: const Icon(Icons.clear, size: 14),
                  tooltip: 'Clear variant',
                  onPressed: posting
                      ? null
                      : () {
                          cubit.updateLine(
                            i,
                            row.copyWith(
                              skuId: null,
                              skuCode: null,
                              skuLabel: null,
                            ),
                          );
                        },
                ),
            ],
          );
        },
      ),
      LineItemColumn(
        label: 'Qty',
        cellBuilder: (context, row, i) => AppDecimalField(
          label: 'Qty',
          value: row.quantity,
          enabled: !posting,
          onChanged: (v) =>
              cubit.updateLine(i, row.copyWith(quantity: v ?? Decimal.one)),
        ),
      ),
      LineItemColumn(
        label: 'Price',
        cellBuilder: (context, row, i) => AppDecimalField(
          label: 'Price',
          value: row.price,
          enabled: !posting,
          onChanged: (v) =>
              cubit.updateLine(i, row.copyWith(price: v ?? Decimal.zero)),
        ),
      ),
      LineItemColumn(
        label: 'Disc %',
        cellBuilder: (context, row, i) => AppDecimalField(
          label: 'Disc %',
          value: row.discountPercent,
          enabled: !posting,
          onChanged: (v) => cubit.updateLine(
            i,
            row.copyWith(discountPercent: v ?? Decimal.zero),
          ),
        ),
      ),
      LineItemColumn(
        label: 'Tax %',
        cellBuilder: (context, row, i) => AppDecimalField(
          label: 'Tax %',
          value: row.taxRate,
          enabled: !posting,
          onChanged: (v) =>
              cubit.updateLine(i, row.copyWith(taxRate: v ?? Decimal.zero)),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bp = kind.blueprint;
    return BlocListener<ItemQtyFormCubit, ItemQtyFormState>(
      listenWhen: (p, c) => p.posted != c.posted && c.posted != null,
      listener: (context, state) {
        final posted = state.posted!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Created ${posted.voucherNo} · ${posted.total}'),
          ),
        );
        context.go(kind.detailRoute(posted.id));
      },
      child: BlocBuilder<ItemQtyFormCubit, ItemQtyFormState>(
        builder: (context, state) {
          final cubit = context.read<ItemQtyFormCubit>();
          return AdaptiveLayout(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New ${bp.label}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: DocumentSurface<ItemQtyLine>(
                    blueprint: bp,
                    header: _header(cubit, state),
                    rows: state.draft.lines,
                    columns: _columns(cubit, state),
                    onRowsChanged: cubit.setLines,
                    newRow: ItemQtyLine.new,
                    lineInputsOf: _lineInput,
                    onPost: () => cubit.submit(
                      formIsValid: () =>
                          _formKey.currentState?.validate() ?? false,
                    ),
                    postLabel: kind.createLabel,
                    posting: state.posting,
                    enabled: !state.posting,
                    errorText: state.error,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
