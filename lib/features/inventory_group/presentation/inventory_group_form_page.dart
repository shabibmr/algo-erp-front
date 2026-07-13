import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_form_surface.dart';
import 'package:algo_erp_front/core/widgets/fields/app_text_field.dart';
import 'package:algo_erp_front/core/widgets/states/error_state.dart';
import 'package:algo_erp_front/core/widgets/states/loading_state.dart';
import 'package:algo_erp_front/features/inventory_group/bloc/inventory_group_form_bloc.dart';
import 'package:algo_erp_front/features/inventory_group/bloc/inventory_group_form_event.dart';
import 'package:algo_erp_front/features/inventory_group/bloc/inventory_group_form_state.dart';
import 'package:algo_erp_front/features/inventory_group/domain/inventory_group.dart';
import 'package:algo_erp_front/features/inventory_group/inventory_group_di.dart';
import 'package:algo_erp_front/features/inventory_group/inventory_group_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class InventoryGroupFormPage extends StatelessWidget {
  const InventoryGroupFormPage({required this.mode, super.key, this.entityId});

  final FormMode mode;
  final int? entityId;

  @override
  Widget build(BuildContext context) {
    final dio = getIt<DioClient>();
    return BlocProvider<InventoryGroupFormBloc>(
      create: (_) => InventoryGroupFormBloc(
        repository: createInventoryGroupRepository(dio),
      )..add(InventoryGroupFormInitialized(entityId: entityId)),
      child: BlocListener<InventoryGroupFormBloc, InventoryGroupFormState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: (context, state) {
          if (state.isSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.isEdit
                      ? 'Group updated successfully'
                      : 'Group created successfully',
                ),
              ),
            );
            context.go(inventoryGroupManifest.resourcePath);
          }
        },
        child: const _InventoryGroupFormView(),
      ),
    );
  }
}

class _InventoryGroupFormView extends StatelessWidget {
  const _InventoryGroupFormView();

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      child: BlocBuilder<InventoryGroupFormBloc, InventoryGroupFormState>(
        builder: (context, state) {
          final bloc = context.read<InventoryGroupFormBloc>();

          if (state.isLoading) {
            return const LoadingState();
          }
          if (state.status == InventoryGroupFormStatus.failure) {
            return ErrorState(
              failure:
                  state.failure ??
                  const Failure.unknown('Failed to load group'),
              onRetry: () => bloc.add(
                InventoryGroupFormInitialized(entityId: state.entityId),
              ),
            );
          }

          final title = state.isEdit ? 'Edit Group' : 'New Group';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () =>
                        context.go(inventoryGroupManifest.resourcePath),
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      AppTextField(
                        label: 'Name',
                        value: state.name,
                        hintText: 'e.g. Peripherals',
                        onChanged: (v) =>
                            bloc.add(InventoryGroupFormNameChanged(v)),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Code',
                        value: state.code,
                        hintText: 'e.g. PERIPH',
                        onChanged: (v) =>
                            bloc.add(InventoryGroupFormCodeChanged(v)),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Name (Arabic)',
                        value: state.nameArabic,
                        hintText: 'Optional Arabic name',
                        onChanged: (v) =>
                            bloc.add(InventoryGroupFormNameArabicChanged(v)),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Group Type',
                        value: state.groupType,
                        hintText: 'e.g. Stock',
                        onChanged: (v) =>
                            bloc.add(InventoryGroupFormGroupTypeChanged(v)),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int?>(
                        initialValue: state.parentGroupId,
                        decoration: const InputDecoration(
                          labelText: 'Parent Group',
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('None (Top Level)'),
                          ),
                          for (final group in state.availableGroups)
                            DropdownMenuItem<int?>(
                              value: group.id,
                              child: Text(group.fullPath ?? group.name),
                            ),
                        ],
                        onChanged: (v) =>
                            bloc.add(InventoryGroupFormParentGroupIdChanged(v)),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: state.isSubmitting
                                ? null
                                : () => context.go(
                                    inventoryGroupManifest.resourcePath,
                                  ),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: state.isSubmitting
                                ? null
                                : () => bloc.add(
                                    const InventoryGroupFormSubmitted(),
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
            ],
          );
        },
      ),
    );
  }
}
