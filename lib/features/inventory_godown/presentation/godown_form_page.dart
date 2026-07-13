import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_form_surface.dart';
import 'package:algo_erp_front/core/widgets/fields/app_text_field.dart';
import 'package:algo_erp_front/core/widgets/states/error_state.dart';
import 'package:algo_erp_front/core/widgets/states/loading_state.dart';
import 'package:algo_erp_front/features/inventory_godown/bloc/godown_form_bloc.dart';
import 'package:algo_erp_front/features/inventory_godown/bloc/godown_form_event.dart';
import 'package:algo_erp_front/features/inventory_godown/bloc/godown_form_state.dart';
import 'package:algo_erp_front/features/inventory_godown/godown_di.dart';
import 'package:algo_erp_front/features/inventory_godown/godown_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class GodownFormPage extends StatelessWidget {
  const GodownFormPage({required this.mode, super.key, this.entityId});

  final FormMode mode;
  final int? entityId;

  @override
  Widget build(BuildContext context) {
    final dio = getIt<DioClient>();
    return BlocProvider<GodownFormBloc>(
      create: (_) =>
          GodownFormBloc(repository: createGodownRepository(dio))
            ..add(GodownFormInitialized(entityId: entityId)),
      child: BlocListener<GodownFormBloc, GodownFormState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: (context, state) {
          if (state.isSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.isEdit
                      ? 'Godown updated successfully'
                      : 'Godown created successfully',
                ),
              ),
            );
            context.go(godownManifest.resourcePath);
          }
        },
        child: const _GodownFormView(),
      ),
    );
  }
}

class _GodownFormView extends StatelessWidget {
  const _GodownFormView();

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      child: BlocBuilder<GodownFormBloc, GodownFormState>(
        builder: (context, state) {
          final bloc = context.read<GodownFormBloc>();

          if (state.isLoading) {
            return const LoadingState();
          }
          if (state.status == GodownFormStatus.failure) {
            return ErrorState(
              failure:
                  state.failure ??
                  const Failure.unknown('Failed to load godown'),
              onRetry: () =>
                  bloc.add(GodownFormInitialized(entityId: state.entityId)),
            );
          }

          final title = state.isEdit ? 'Edit Godown' : 'New Godown';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => context.go(godownManifest.resourcePath),
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
                        hintText: 'e.g. Main Warehouse',
                        onChanged: (v) => bloc.add(GodownFormNameChanged(v)),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Code',
                        value: state.code,
                        hintText: 'e.g. WH-01',
                        onChanged: (v) => bloc.add(GodownFormCodeChanged(v)),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Location',
                        value: state.location,
                        hintText: 'e.g. Building A, Floor 2',
                        onChanged: (v) =>
                            bloc.add(GodownFormLocationChanged(v)),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Narration',
                        value: state.narration,
                        onChanged: (v) =>
                            bloc.add(GodownFormNarrationChanged(v)),
                      ),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        title: const Text('Profit Centre'),
                        value: state.isProfitCentre,
                        onChanged: (v) => bloc.add(
                          GodownFormIsProfitCentreToggled(v ?? false),
                        ),
                      ),
                      CheckboxListTile(
                        title: const Text('Default Warehouse'),
                        value: state.isDefault,
                        onChanged: (v) =>
                            bloc.add(GodownFormIsDefaultToggled(v ?? false)),
                      ),
                      CheckboxListTile(
                        title: const Text('Production Unit'),
                        value: state.isProduction,
                        onChanged: (v) =>
                            bloc.add(GodownFormIsProductionToggled(v ?? false)),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: state.isSubmitting
                                ? null
                                : () => context.go(godownManifest.resourcePath),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: state.isSubmitting
                                ? null
                                : () => bloc.add(const GodownFormSubmitted()),
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
