import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_form_surface.dart';
import 'package:algo_erp_front/core/widgets/fields/app_decimal_field.dart';
import 'package:algo_erp_front/core/widgets/fields/app_text_field.dart';
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

    return AdaptiveLayout(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => context.go(skuMasterManifest.resourcePath),
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
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 12),
              ],
              Expanded(
                child: SingleChildScrollView(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
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
                          const SizedBox(height: 12),
                          AppTextField(
                            label: 'Legacy Item ID',
                            value: state.legacyItemId,
                            hintText:
                                'Auto-filled from item code when possible',
                            onChanged: (v) =>
                                bloc.add(SkuMasterFormLegacyItemIdChanged(v)),
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            label: 'Name',
                            value: state.name,
                            hintText: 'e.g. Wireless Mouse - Red',
                            onChanged: (v) =>
                                bloc.add(SkuMasterFormNameChanged(v)),
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            label: 'SKU Code',
                            value: state.code,
                            hintText: 'e.g. WM-01-RED',
                            onChanged: (v) =>
                                bloc.add(SkuMasterFormCodeChanged(v)),
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            label: 'Barcode',
                            value: state.barcode,
                            hintText: 'e.g. 123456789012',
                            onChanged: (v) =>
                                bloc.add(SkuMasterFormBarcodeChanged(v)),
                          ),
                          const SizedBox(height: 12),
                          AppDecimalField(
                            label: 'Rate',
                            value: state.rate,
                            onChanged: (v) => bloc.add(
                              SkuMasterFormRateChanged(v ?? Decimal.zero),
                            ),
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            label: 'Description',
                            value: state.description,
                            onChanged: (v) =>
                                bloc.add(SkuMasterFormDescriptionChanged(v)),
                          ),
                          const SizedBox(height: 12),
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
                          const SizedBox(height: 12),
                          AppTextField(
                            label: 'Value',
                            value: state.value,
                            hintText: 'e.g. Red',
                            onChanged: (v) =>
                                bloc.add(SkuMasterFormValueChanged(v)),
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            label: 'Possible Values',
                            value: state.possibleValues,
                            hintText: 'e.g. Red, Blue, Green',
                            onChanged: (v) =>
                                bloc.add(SkuMasterFormPossibleValuesChanged(v)),
                          ),
                          const SizedBox(height: 20),
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
                              const SizedBox(width: 12),
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
              ),
            ],
          );
        },
      ),
    );
  }
}
