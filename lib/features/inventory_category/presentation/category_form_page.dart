import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_form_surface.dart';
import 'package:algo_erp_front/core/widgets/fields/app_text_field.dart';
import 'package:algo_erp_front/core/widgets/states/error_state.dart';
import 'package:algo_erp_front/core/widgets/states/loading_state.dart';
import 'package:algo_erp_front/features/inventory_category/bloc/category_form_bloc.dart';
import 'package:algo_erp_front/features/inventory_category/bloc/category_form_event.dart';
import 'package:algo_erp_front/features/inventory_category/bloc/category_form_state.dart';
import 'package:algo_erp_front/features/inventory_category/category_di.dart';
import 'package:algo_erp_front/features/inventory_category/category_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class CategoryFormPage extends StatelessWidget {
  const CategoryFormPage({required this.mode, super.key, this.entityId});

  final FormMode mode;
  final int? entityId;

  @override
  Widget build(BuildContext context) {
    final dio = getIt<DioClient>();
    return BlocProvider<CategoryFormBloc>(
      create: (_) =>
          CategoryFormBloc(repository: createCategoryRepository(dio))
            ..add(CategoryFormInitialized(entityId: entityId)),
      child: BlocListener<CategoryFormBloc, CategoryFormState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: (context, state) {
          if (state.isSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.isEdit
                      ? 'Category updated successfully'
                      : 'Category created successfully',
                ),
              ),
            );
            context.go(categoryManifest.resourcePath);
          }
        },
        child: const _CategoryFormView(),
      ),
    );
  }
}

class _CategoryFormView extends StatelessWidget {
  const _CategoryFormView();

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      child: BlocBuilder<CategoryFormBloc, CategoryFormState>(
        builder: (context, state) {
          final bloc = context.read<CategoryFormBloc>();

          if (state.isLoading) {
            return const LoadingState();
          }
          if (state.status == CategoryFormStatus.failure) {
            return ErrorState(
              failure:
                  state.failure ??
                  const Failure.unknown('Failed to load category'),
              onRetry: () =>
                  bloc.add(CategoryFormInitialized(entityId: state.entityId)),
            );
          }

          final title = state.isEdit ? 'Edit Category' : 'New Category';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => context.go(categoryManifest.resourcePath),
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
                        hintText: 'e.g. Electronics',
                        onChanged: (v) => bloc.add(CategoryFormNameChanged(v)),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Code',
                        value: state.code,
                        hintText: 'e.g. ELEC',
                        onChanged: (v) => bloc.add(CategoryFormCodeChanged(v)),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Description',
                        value: state.description,
                        hintText: 'Optional description of the category',
                        onChanged: (v) =>
                            bloc.add(CategoryFormDescriptionChanged(v)),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: state.isSubmitting
                                ? null
                                : () =>
                                      context.go(categoryManifest.resourcePath),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: state.isSubmitting
                                ? null
                                : () => bloc.add(const CategoryFormSubmitted()),
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
