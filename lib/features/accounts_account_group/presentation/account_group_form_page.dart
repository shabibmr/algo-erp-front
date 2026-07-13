import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_form_surface.dart';
import 'package:algo_erp_front/core/widgets/fields/app_text_field.dart';
import 'package:algo_erp_front/core/widgets/states/error_state.dart';
import 'package:algo_erp_front/core/widgets/states/loading_state.dart';
import 'package:algo_erp_front/features/accounts_account_group/account_group_di.dart';
import 'package:algo_erp_front/features/accounts_account_group/account_group_manifest.dart';
import 'package:algo_erp_front/features/accounts_account_group/bloc/account_group_form_bloc.dart';
import 'package:algo_erp_front/features/accounts_account_group/bloc/account_group_form_event.dart';
import 'package:algo_erp_front/features/accounts_account_group/bloc/account_group_form_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AccountGroupFormPage extends StatelessWidget {
  const AccountGroupFormPage({required this.mode, super.key, this.entityId});

  final FormMode mode;
  final int? entityId;

  @override
  Widget build(BuildContext context) {
    final dio = getIt<DioClient>();
    return BlocProvider<AccountGroupFormBloc>(
      create: (_) =>
          AccountGroupFormBloc(repository: createAccountGroupRepository(dio))
            ..add(AccountGroupFormInitialized(entityId: entityId)),
      child: BlocListener<AccountGroupFormBloc, AccountGroupFormState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: (context, state) {
          if (state.isSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.isEdit
                      ? 'Account Group updated successfully'
                      : 'Account Group created successfully',
                ),
              ),
            );
            context.go(accountGroupManifest.resourcePath);
          }
        },
        child: const _AccountGroupFormView(),
      ),
    );
  }
}

class _AccountGroupFormView extends StatelessWidget {
  const _AccountGroupFormView();

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      child: BlocBuilder<AccountGroupFormBloc, AccountGroupFormState>(
        builder: (context, state) {
          final bloc = context.read<AccountGroupFormBloc>();

          if (state.isLoading) {
            return const LoadingState();
          }
          if (state.status == AccountGroupFormStatus.failure) {
            return ErrorState(
              failure:
                  state.failure ??
                  const Failure.unknown('Failed to load account group'),
              onRetry: () => bloc.add(
                AccountGroupFormInitialized(entityId: state.entityId),
              ),
            );
          }

          final title = state.isEdit
              ? 'Edit Account Group'
              : 'New Account Group';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () =>
                        context.go(accountGroupManifest.resourcePath),
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
                        hintText: 'e.g. Current Assets',
                        onChanged: (v) =>
                            bloc.add(AccountGroupFormNameChanged(v)),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Code',
                        value: state.code,
                        hintText: 'e.g. CA',
                        onChanged: (v) =>
                            bloc.add(AccountGroupFormCodeChanged(v)),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int?>(
                        value: state.parentGroupId,
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
                            bloc.add(AccountGroupFormParentGroupIdChanged(v)),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: state.isSubmitting
                                ? null
                                : () => context.go(
                                    accountGroupManifest.resourcePath,
                                  ),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: state.isSubmitting
                                ? null
                                : () => bloc.add(
                                    const AccountGroupFormSubmitted(),
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
