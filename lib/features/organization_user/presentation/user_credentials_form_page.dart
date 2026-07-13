import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:algo_erp_front/core/auth/permission_gate.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/manifest/field_renderer.dart';
import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:algo_erp_front/core/manifest/form_field_spec.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_form_surface.dart';
import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/core/widgets/dialogs/confirm_dialog.dart';
import 'package:algo_erp_front/core/widgets/states/error_state.dart';
import 'package:algo_erp_front/core/widgets/states/loading_state.dart';
import 'package:algo_erp_front/features/organization_user/bloc/user_credentials_form_bloc.dart';
import 'package:algo_erp_front/features/organization_user/bloc/user_credentials_form_event.dart';
import 'package:algo_erp_front/features/organization_user/bloc/user_credentials_form_state.dart';
import 'package:algo_erp_front/features/organization_user/domain/user_credentials.dart';
import 'package:algo_erp_front/features/organization_user/user_credentials_di.dart';
import 'package:algo_erp_front/features/organization_user/user_credentials_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class UserCredentialsFormPage extends StatelessWidget {
  const UserCredentialsFormPage({required this.mode, super.key, this.entityId});

  final FormMode mode;
  final int? entityId;

  @override
  Widget build(BuildContext context) {
    final dio = getIt<DioClient>();
    return BlocProvider<UserCredentialsFormBloc>(
      create: (_) => UserCredentialsFormBloc(
        repository: createUserCredentialsRepository(dio),
      )..add(UserCredentialsFormInitialized(entityId: entityId)),
      child: BlocListener<UserCredentialsFormBloc, UserCredentialsFormState>(
        listenWhen: (prev, curr) =>
            prev.status != curr.status ||
            prev.errorMessage != curr.errorMessage,
        listener: (context, state) {
          if (state.isSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.isEdit
                      ? 'User updated successfully'
                      : 'User created successfully',
                ),
              ),
            );
            context.go(userCredentialsManifest.resourcePath);
          } else if (state.isDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User deactivated successfully')),
            );
            context.go(userCredentialsManifest.resourcePath);
          }
        },
        child: _UserCredentialsFormView(mode: mode),
      ),
    );
  }
}

class _UserCredentialsFormView extends StatefulWidget {
  const _UserCredentialsFormView({required this.mode});

  final FormMode mode;

  @override
  State<_UserCredentialsFormView> createState() =>
      _UserCredentialsFormViewState();
}

class _UserCredentialsFormViewState extends State<_UserCredentialsFormView> {
  final _formKey = GlobalKey<FormState>();

  static bool _isFkType(FieldType type) =>
      type == FieldType.fk || type == FieldType.selfFk;

  void _setField(
    BuildContext context,
    UserCredentials current,
    FormFieldSpec<UserCredentials> field,
    Object? value,
  ) {
    final updated = field.setValue(current, value);
    context.read<UserCredentialsFormBloc>().add(
      UserCredentialsFormEntityUpdated(updated),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Deactivate User?',
      message: 'This will temporarily deactivate the user account.',
      confirmLabel: 'Deactivate',
      destructive: true,
    );
    if (ok && context.mounted) {
      context.read<UserCredentialsFormBloc>().add(
        const UserCredentialsFormDeleted(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return AdaptiveLayout(
      child: BlocBuilder<UserCredentialsFormBloc, UserCredentialsFormState>(
        builder: (context, state) {
          final bloc = context.read<UserCredentialsFormBloc>();

          if (state.isLoading) {
            return const LoadingState();
          }
          if (state.status == UserCredentialsFormStatus.failure) {
            return ErrorState(
              failure:
                  state.failure ?? const Failure.unknown('Failed to load user'),
              onRetry: () => bloc.add(
                UserCredentialsFormInitialized(entityId: state.entityId),
              ),
            );
          }

          final title = state.isEdit ? 'Edit User' : 'New User';
          final action = state.isEdit
              ? PermissionAction.update
              : PermissionAction.create;
          final isReadOnlyEdit =
              widget.mode == FormMode.edit &&
              !userCredentialsManifest.supportsUpdate;
          final canDelete =
              widget.mode == FormMode.edit &&
              userCredentialsManifest.supportsDelete;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () =>
                        context.go(userCredentialsManifest.resourcePath),
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
                Container(
                  padding: EdgeInsets.all(tokens.spacing.sm),
                  decoration: BoxDecoration(
                    color: tokens.semanticColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(tokens.radii.sm),
                  ),
                  child: Text(
                    state.errorMessage!,
                    style: TextStyle(color: tokens.semanticColors.danger),
                  ),
                ),
                SizedBox(height: tokens.spacing.md),
              ],
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: EdgeInsets.only(top: tokens.spacing.sm),
                    children: [
                      for (final field
                          in userCredentialsManifest.formFields) ...[
                        FieldRenderer.build<UserCredentials>(
                          field: field,
                          value: field.getValue(state.currentEntity),
                          onChanged: (value) => _setField(
                            context,
                            state.currentEntity,
                            field,
                            value,
                          ),
                          enabled: !state.isSubmitting && !isReadOnlyEdit,
                          errorText: state.fieldErrors[field.errorKey],
                          fkLoaderOverride: _isFkType(field.type)
                              ? (q) => field.fkSearch!(q)
                              : null,
                        ),
                        SizedBox(height: tokens.spacing.sm),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: tokens.spacing.md),
              Row(
                children: [
                  if (!isReadOnlyEdit)
                    PermissionGate(
                      module: userCredentialsManifest.rbacModule,
                      action: action,
                      child: FilledButton(
                        onPressed: state.isSubmitting
                            ? null
                            : () {
                                if (_formKey.currentState?.validate() ??
                                    false) {
                                  bloc.add(
                                    const UserCredentialsFormSubmitted(),
                                  );
                                }
                              },
                        child: Text(
                          state.isSubmitting
                              ? 'Saving...'
                              : (state.isEdit ? 'Save' : 'Create'),
                        ),
                      ),
                    ),
                  if (canDelete) ...[
                    if (!isReadOnlyEdit) SizedBox(width: tokens.spacing.sm),
                    PermissionGate(
                      module: userCredentialsManifest.rbacModule,
                      action: PermissionAction.delete,
                      child: OutlinedButton(
                        onPressed: state.isSubmitting
                            ? null
                            : () => _delete(context),
                        child: const Text('Deactivate'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
