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
import 'package:algo_erp_front/core/widgets/layout/page_header.dart';
import 'package:algo_erp_front/core/widgets/layout/work_sheet.dart';
import 'package:algo_erp_front/core/widgets/lookup/fk_lookup_field.dart';
import 'package:algo_erp_front/core/widgets/states/error_state.dart';
import 'package:algo_erp_front/core/widgets/states/loading_state.dart';
import 'package:algo_erp_front/features/inventory_item/domain/inventory_item.dart';
import 'package:algo_erp_front/features/inventory_item/inventory_item_di.dart';
import 'package:algo_erp_front/features/inventory_sku/bloc/sku_master_form_bloc.dart';
import 'package:algo_erp_front/features/inventory_sku/bloc/sku_master_form_event.dart';
import 'package:algo_erp_front/features/inventory_sku/bloc/sku_master_form_state.dart';
import 'package:algo_erp_front/features/inventory_sku/domain/sku_master.dart';
import 'package:algo_erp_front/features/inventory_sku/sku_master_di.dart';
import 'package:algo_erp_front/features/inventory_sku/sku_master_manifest.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SkuMasterFormPage extends StatelessWidget {
  const SkuMasterFormPage({required this.mode, super.key, this.entityId});

  final FormMode mode;
  final int? entityId;

  @override
  Widget build(BuildContext context) {
    final dio = getIt<DioClient>();
    return BlocProvider<SkuMasterFormBloc>(
      create: (_) => SkuMasterFormBloc(
        repository: createSkuMasterRepository(dio),
        inventoryItemRepository: createInventoryItemRepository(dio),
      )..add(SkuMasterFormInitialized(entityId: entityId)),
      child: BlocListener<SkuMasterFormBloc, SkuMasterFormState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: (context, state) {
          if (state.isSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.isEdit
                      ? 'SKU updated successfully'
                      : 'SKU created successfully',
                ),
              ),
            );
            context.go(skuMasterManifest.resourcePath);
          }
        },
        child: const _SkuMasterFormView(),
      ),
    );
  }
}

class _SkuMasterFormView extends StatelessWidget {
  const _SkuMasterFormView();

  @override
  Widget build(BuildContext context) {
    final itemRepo = createInventoryItemRepository(getIt<DioClient>());
    final tokens = context.tokens;
    final gap = SizedBox(height: tokens.spacing.md);

    return AdaptiveLayout(
      maxContentWidth: FieldWidths.formContent,
      child: BlocBuilder<SkuMasterFormBloc, SkuMasterFormState>(
        builder: (context, state) {
          final bloc = context.read<SkuMasterFormBloc>();

          if (state.isLoading) {
            return const LoadingState();
          }
          if (state.status == SkuMasterFormStatus.failure) {
            return ErrorState(
              failure:
                  state.failure ?? const Failure.unknown('Failed to load SKU'),
              onRetry: () =>
                  bloc.add(SkuMasterFormInitialized(entityId: state.entityId)),
            );
          }

          final title = state.isEdit ? 'Edit SKU' : 'New SKU';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                eyebrow: skuMasterManifest.eyebrowText,
                title: title,
                actions: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => context.go(skuMasterManifest.resourcePath),
                    icon: const Icon(Icons.arrow_back),
                  ),
                ],
              ),
              SizedBox(height: tokens.spacing.md),
              if (state.errorMessage != null) ...[
                Text(
                  state.errorMessage!,
                  style: TextStyle(color: tokens.semanticColors.danger),
                ),
                gap,
              ],
              Expanded(
                child: SingleChildScrollView(
                  child: WorkSheet(
                    fill: false,
                    padding: EdgeInsets.symmetric(
                      horizontal: tokens.spacing.md,
                      vertical: tokens.spacing.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        constrainFormField(
                          FkLookupField<InventoryItem>(
                            label: 'Parent Inventory Item',
                            value: state.inventoryItem,
                            displayOf: (i) => '${i.code} — ${i.name}',
                            loader: (q) async {
                              final res = await itemRepo.list(
                                PageQuery(search: q),
                              );
                              return res.fold((_) => const [], (p) => p.items);
                            },
                            onSelected: (i) =>
                                bloc.add(SkuMasterFormItemChanged(i)),
                          ),
                          maxWidth: FieldWidths.picker,
                        ),
                        gap,
                        constrainFormField(
                          AppTextField(
                            label: 'Legacy Item ID',
                            value: state.legacyItemId,
                            hintText:
                                'Auto-filled from item code when possible',
                            onChanged: (v) =>
                                bloc.add(SkuMasterFormLegacyItemIdChanged(v)),
                          ),
                          maxWidth: FieldWidths.code,
                        ),
                        gap,
                        AppTextField(
                          label: 'Name',
                          value: state.name,
                          hintText: 'e.g. Wireless Mouse - Red',
                          onChanged: (v) =>
                              bloc.add(SkuMasterFormNameChanged(v)),
                        ),
                        gap,
                        constrainFormField(
                          AppTextField(
                            label: 'SKU Code',
                            value: state.code,
                            hintText: 'e.g. WM-01-RED',
                            onChanged: (v) =>
                                bloc.add(SkuMasterFormCodeChanged(v)),
                          ),
                          maxWidth: FieldWidths.code,
                        ),
                        gap,
                        constrainFormField(
                          AppTextField(
                            label: 'Barcode',
                            value: state.barcode,
                            hintText: 'e.g. 123456789012',
                            onChanged: (v) =>
                                bloc.add(SkuMasterFormBarcodeChanged(v)),
                          ),
                          maxWidth: FieldWidths.textShort,
                        ),
                        gap,
                        constrainFormField(
                          AppDecimalField(
                            label: 'Rate',
                            value: state.rate,
                            onChanged: (v) => bloc.add(
                              SkuMasterFormRateChanged(v ?? Decimal.zero),
                            ),
                          ),
                          maxWidth: FieldWidths.number,
                        ),
                        gap,
                        AppTextField(
                          label: 'Description',
                          value: state.description,
                          onChanged: (v) =>
                              bloc.add(SkuMasterFormDescriptionChanged(v)),
                        ),
                        gap,
                        constrainFormField(
                          DropdownButtonFormField<int?>(
                            initialValue: state.skuType,
                            decoration: const InputDecoration(
                              labelText: 'SKU Type',
                              helperText: '1 = Variant, 2 = Serial, 3 = Batch',
                            ),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('None'),
                              ),
                              for (final entry in SkuMaster.skuTypes.entries)
                                DropdownMenuItem<int?>(
                                  value: entry.key,
                                  child: Text('${entry.key} = ${entry.value}'),
                                ),
                            ],
                            onChanged: (v) =>
                                bloc.add(SkuMasterFormSkuTypeChanged(v)),
                          ),
                          maxWidth: FieldWidths.dropdown,
                        ),
                        gap,
                        constrainFormField(
                          AppTextField(
                            label: 'Value',
                            value: state.value,
                            hintText: 'e.g. Red',
                            onChanged: (v) =>
                                bloc.add(SkuMasterFormValueChanged(v)),
                          ),
                          maxWidth: FieldWidths.textShort,
                        ),
                        gap,
                        AppTextField(
                          label: 'Possible Values',
                          value: state.possibleValues,
                          hintText: 'e.g. Red, Blue, Green',
                          onChanged: (v) =>
                              bloc.add(SkuMasterFormPossibleValuesChanged(v)),
                        ),
                        SizedBox(height: tokens.spacing.lg),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: state.isSubmitting
                                  ? null
                                  : () => context.go(
                                      skuMasterManifest.resourcePath,
                                    ),
                              child: const Text('Cancel'),
                            ),
                            SizedBox(width: tokens.spacing.sm),
                            FilledButton(
                              onPressed: state.isSubmitting
                                  ? null
                                  : () => bloc.add(
                                      const SkuMasterFormSubmitted(),
                                    ),
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
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
