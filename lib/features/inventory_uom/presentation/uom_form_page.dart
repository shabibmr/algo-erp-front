import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_form_surface.dart';
import 'package:algo_erp_front/core/widgets/fields/app_number_field.dart';
import 'package:algo_erp_front/core/widgets/fields/app_text_field.dart';
import 'package:algo_erp_front/core/widgets/states/error_state.dart';
import 'package:algo_erp_front/core/widgets/states/loading_state.dart';
import 'package:algo_erp_front/features/inventory_uom/bloc/uom_form_bloc.dart';
import 'package:algo_erp_front/features/inventory_uom/bloc/uom_form_event.dart';
import 'package:algo_erp_front/features/inventory_uom/bloc/uom_form_state.dart';
import 'package:algo_erp_front/features/inventory_uom/uom_di.dart';
import 'package:algo_erp_front/features/inventory_uom/uom_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class UomFormPage extends StatelessWidget {
  const UomFormPage({required this.mode, super.key, this.entityId});

  final FormMode mode;
  final int? entityId;

  @override
  Widget build(BuildContext context) {
    final dio = getIt<DioClient>();
    return BlocProvider<UomFormBloc>(
      create: (_) =>
          UomFormBloc(repository: createUomRepository(dio))
            ..add(UomFormInitialized(entityId: entityId)),
      child: BlocListener<UomFormBloc, UomFormState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: (context, state) {
          if (state.isSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.isEdit
                      ? 'UOM updated successfully'
                      : 'UOM created successfully',
                ),
              ),
            );
            context.go(uomManifest.resourcePath);
          }
        },
        child: const _UomFormView(),
      ),
    );
  }
}

class _UomFormView extends StatelessWidget {
  const _UomFormView();

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      child: BlocBuilder<UomFormBloc, UomFormState>(
        builder: (context, state) {
          final bloc = context.read<UomFormBloc>();

          if (state.isLoading) {
            return const LoadingState();
          }
          if (state.status == UomFormStatus.failure) {
            return ErrorState(
              failure:
                  state.failure ?? const Failure.unknown('Failed to load UOM'),
              onRetry: () =>
                  bloc.add(UomFormInitialized(entityId: state.entityId)),
            );
          }

          final title = state.isEdit ? 'Edit UOM' : 'New UOM';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => context.go(uomManifest.resourcePath),
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
                        hintText: 'e.g. Kilogram',
                        onChanged: (v) => bloc.add(UomFormNameChanged(v)),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Code',
                        value: state.code,
                        hintText: 'e.g. KG',
                        onChanged: (v) => bloc.add(UomFormCodeChanged(v)),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Symbol',
                        value: state.symbol,
                        hintText: 'e.g. kg',
                        onChanged: (v) => bloc.add(UomFormSymbolChanged(v)),
                      ),
                      const SizedBox(height: 12),
                      AppNumberField(
                        label: 'Decimal Places',
                        value: state.decimalPlaces,
                        onChanged: (v) =>
                            bloc.add(UomFormDecimalPlacesChanged(v ?? 0)),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: state.isSubmitting
                                ? null
                                : () => context.go(uomManifest.resourcePath),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: state.isSubmitting
                                ? null
                                : () => bloc.add(const UomFormSubmitted()),
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
