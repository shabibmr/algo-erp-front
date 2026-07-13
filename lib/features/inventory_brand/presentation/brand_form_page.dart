import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_form_surface.dart';
import 'package:algo_erp_front/core/widgets/fields/app_text_field.dart';
import 'package:algo_erp_front/core/widgets/states/error_state.dart';
import 'package:algo_erp_front/core/widgets/states/loading_state.dart';
import 'package:algo_erp_front/features/inventory_brand/bloc/brand_form_bloc.dart';
import 'package:algo_erp_front/features/inventory_brand/bloc/brand_form_event.dart';
import 'package:algo_erp_front/features/inventory_brand/bloc/brand_form_state.dart';
import 'package:algo_erp_front/features/inventory_brand/brand_di.dart';
import 'package:algo_erp_front/features/inventory_brand/brand_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class BrandFormPage extends StatelessWidget {
  const BrandFormPage({required this.mode, super.key, this.entityId});

  final FormMode mode;
  final int? entityId;

  @override
  Widget build(BuildContext context) {
    final dio = getIt<DioClient>();
    return BlocProvider<BrandFormBloc>(
      create: (_) =>
          BrandFormBloc(repository: createBrandRepository(dio))
            ..add(BrandFormInitialized(entityId: entityId)),
      child: BlocListener<BrandFormBloc, BrandFormState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: (context, state) {
          if (state.isSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.isEdit
                      ? 'Brand updated successfully'
                      : 'Brand created successfully',
                ),
              ),
            );
            context.go(brandManifest.resourcePath);
          }
        },
        child: const _BrandFormView(),
      ),
    );
  }
}

class _BrandFormView extends StatelessWidget {
  const _BrandFormView();

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      child: BlocBuilder<BrandFormBloc, BrandFormState>(
        builder: (context, state) {
          final bloc = context.read<BrandFormBloc>();

          if (state.isLoading) {
            return const LoadingState();
          }
          if (state.status == BrandFormStatus.failure) {
            return ErrorState(
              failure:
                  state.failure ??
                  const Failure.unknown('Failed to load brand'),
              onRetry: () =>
                  bloc.add(BrandFormInitialized(entityId: state.entityId)),
            );
          }

          final title = state.isEdit ? 'Edit Brand' : 'New Brand';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => context.go(brandManifest.resourcePath),
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
                        hintText: 'e.g. Sony',
                        onChanged: (v) => bloc.add(BrandFormNameChanged(v)),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Description',
                        value: state.description,
                        hintText: 'Optional description of the brand',
                        onChanged: (v) =>
                            bloc.add(BrandFormDescriptionChanged(v)),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: state.isSubmitting
                                ? null
                                : () => context.go(brandManifest.resourcePath),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: state.isSubmitting
                                ? null
                                : () => bloc.add(const BrandFormSubmitted()),
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
