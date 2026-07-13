import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_form_surface.dart';
import 'package:algo_erp_front/core/widgets/fields/app_text_field.dart';
import 'package:algo_erp_front/core/widgets/states/error_state.dart';
import 'package:algo_erp_front/core/widgets/states/loading_state.dart';
import 'package:algo_erp_front/features/inventory_item_property/bloc/item_property_form_bloc.dart';
import 'package:algo_erp_front/features/inventory_item_property/bloc/item_property_form_event.dart';
import 'package:algo_erp_front/features/inventory_item_property/bloc/item_property_form_state.dart';
import 'package:algo_erp_front/features/inventory_item_property/item_property_di.dart';
import 'package:algo_erp_front/features/inventory_item_property/item_property_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ItemPropertyFormPage extends StatelessWidget {
  const ItemPropertyFormPage({required this.mode, super.key, this.entityId});

  final FormMode mode;
  final int? entityId;

  @override
  Widget build(BuildContext context) {
    final dio = getIt<DioClient>();
    return BlocProvider<ItemPropertyFormBloc>(
      create: (_) =>
          ItemPropertyFormBloc(repository: createItemPropertyRepository(dio))
            ..add(ItemPropertyFormInitialized(entityId: entityId)),
      child: BlocListener<ItemPropertyFormBloc, ItemPropertyFormState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: (context, state) {
          if (state.isSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Item property created successfully'),
              ),
            );
            context.go(itemPropertyManifest.resourcePath);
          }
        },
        child: const _ItemPropertyFormView(),
      ),
    );
  }
}

class _ItemPropertyFormView extends StatelessWidget {
  const _ItemPropertyFormView();

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      child: BlocBuilder<ItemPropertyFormBloc, ItemPropertyFormState>(
        builder: (context, state) {
          final bloc = context.read<ItemPropertyFormBloc>();

          if (state.isLoading) {
            return const LoadingState();
          }
          if (state.status == ItemPropertyFormStatus.failure) {
            return ErrorState(
              failure:
                  state.failure ??
                  const Failure.unknown('Failed to load property'),
              onRetry: () => bloc.add(
                ItemPropertyFormInitialized(entityId: state.entityId),
              ),
            );
          }

          final title = state.isEdit ? 'View Property' : 'New Property';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () =>
                        context.go(itemPropertyManifest.resourcePath),
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
                        label: 'Item ID',
                        value: state.itemId,
                        enabled: !state.isEdit,
                        onChanged: (v) =>
                            bloc.add(ItemPropertyFormItemIdChanged(v)),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Default Value',
                        value: state.defaultValue,
                        enabled: !state.isEdit,
                        onChanged: (v) =>
                            bloc.add(ItemPropertyFormDefaultValueChanged(v)),
                      ),
                      if (state.isEdit) ...[
                        const SizedBox(height: 12),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Item Properties cannot be updated after creation.',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: state.isSubmitting
                                ? null
                                : () => context.go(
                                    itemPropertyManifest.resourcePath,
                                  ),
                            child: Text(state.isEdit ? 'Back' : 'Cancel'),
                          ),
                          if (!state.isEdit) ...[
                            const SizedBox(width: 12),
                            FilledButton(
                              onPressed: state.isSubmitting
                                  ? null
                                  : () => bloc.add(
                                      const ItemPropertyFormSubmitted(),
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
