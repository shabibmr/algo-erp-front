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
import 'package:algo_erp_front/core/widgets/layout/field_widths.dart';
import 'package:algo_erp_front/core/widgets/layout/form_field_layout.dart';
import 'package:algo_erp_front/core/widgets/states/error_state.dart';
import 'package:algo_erp_front/core/widgets/states/loading_state.dart';
import 'package:algo_erp_front/features/accounts_ledger/bloc/ledger_form_bloc.dart';
import 'package:algo_erp_front/features/accounts_ledger/bloc/ledger_form_event.dart';
import 'package:algo_erp_front/features/accounts_ledger/bloc/ledger_form_state.dart';
import 'package:algo_erp_front/features/accounts_ledger/domain/ledger.dart';
import 'package:algo_erp_front/features/accounts_ledger/ledger_di.dart';
import 'package:algo_erp_front/features/accounts_ledger/ledger_extension_fields.dart';
import 'package:algo_erp_front/features/accounts_ledger/ledger_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Tabbed ledger form powered by [LedgerFormBloc]: Core + Bank + Credit + Tax.
class LedgerFormPage extends StatelessWidget {
  const LedgerFormPage({required this.mode, super.key, this.entityId});

  final FormMode mode;
  final int? entityId;

  @override
  Widget build(BuildContext context) {
    final dio = getIt<DioClient>();
    return BlocProvider<LedgerFormBloc>(
      create: (_) =>
          LedgerFormBloc(repository: createLedgerRepository(dio))
            ..add(LedgerFormInitialized(entityId: entityId)),
      child: BlocListener<LedgerFormBloc, LedgerFormState>(
        listenWhen: (prev, curr) =>
            prev.status != curr.status ||
            prev.errorMessage != curr.errorMessage,
        listener: (context, state) {
          if (state.isSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.isEdit
                      ? 'Ledger updated successfully'
                      : 'Ledger created successfully',
                ),
              ),
            );
            context.go(ledgerManifest.resourcePath);
          } else if (state.isDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ledger deleted successfully')),
            );
            context.go(ledgerManifest.resourcePath);
          }
        },
        child: _LedgerFormView(mode: mode),
      ),
    );
  }
}

class _LedgerFormView extends StatefulWidget {
  const _LedgerFormView({required this.mode});

  final FormMode mode;

  @override
  State<_LedgerFormView> createState() => _LedgerFormViewState();
}

class _LedgerFormViewState extends State<_LedgerFormView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  static bool _isFkType(FieldType type) =>
      type == FieldType.fk || type == FieldType.selfFk;

  void _setField(
    BuildContext context,
    Ledger current,
    FormFieldSpec<Ledger> field,
    Object? value,
  ) {
    final updated = field.setValue(current, value);
    context.read<LedgerFormBloc>().add(LedgerFormEntityUpdated(updated));
  }

  Future<void> _delete(BuildContext context) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete Ledger?',
      message: 'This will deactivate the ledger account.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (ok && context.mounted) {
      context.read<LedgerFormBloc>().add(const LedgerFormDeleted());
    }
  }

  Widget _fieldList(
    BuildContext context,
    LedgerFormState state,
    List<FormFieldSpec<Ledger>> fields,
  ) {
    final tokens = context.tokens;
    final isReadOnlyEdit =
        widget.mode == FormMode.edit && !ledgerManifest.supportsUpdate;

    final items = <FormFieldLayoutItem>[
      for (final field in fields)
        FormFieldLayoutItem(
          type: field.type,
          half: field.half,
          child: FieldRenderer.build<Ledger>(
            field: field,
            value: field.getValue(state.currentEntity),
            onChanged: (value) =>
                _setField(context, state.currentEntity, field, value),
            enabled: !state.isSubmitting && !isReadOnlyEdit,
            errorText: state.fieldErrors[field.errorKey],
            fkLoaderOverride: _isFkType(field.type)
                ? (q) => field.fkSearch!(q)
                : null,
          ),
        ),
    ];

    return ListView(
      padding: EdgeInsets.only(top: tokens.spacing.sm),
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: FieldWidths.formContent,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: FormFieldLayout.buildRows(context, items),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return AdaptiveLayout(
      child: BlocBuilder<LedgerFormBloc, LedgerFormState>(
        builder: (context, state) {
          final bloc = context.read<LedgerFormBloc>();

          if (state.isLoading) {
            return const LoadingState();
          }
          if (state.status == LedgerFormStatus.failure) {
            return ErrorState(
              failure:
                  state.failure ??
                  const Failure.unknown('Failed to load ledger'),
              onRetry: () =>
                  bloc.add(LedgerFormInitialized(entityId: state.entityId)),
            );
          }

          final title = state.isEdit ? 'Edit Ledger' : 'New Ledger';
          final action = state.isEdit
              ? PermissionAction.update
              : PermissionAction.create;
          final isReadOnlyEdit =
              widget.mode == FormMode.edit && !ledgerManifest.supportsUpdate;
          final canDelete =
              widget.mode == FormMode.edit && ledgerManifest.supportsDelete;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => context.go(ledgerManifest.resourcePath),
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
              TabBar(
                controller: _tabs,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Core'),
                  Tab(text: 'Bank'),
                  Tab(text: 'Credit'),
                  Tab(text: 'Tax'),
                ],
              ),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _fieldList(context, state, ledgerManifest.formFields),
                      _fieldList(context, state, ledgerBankFormFields),
                      _fieldList(context, state, ledgerCreditFormFields),
                      _fieldList(context, state, ledgerTaxFormFields),
                    ],
                  ),
                ),
              ),
              SizedBox(height: tokens.spacing.md),
              Row(
                children: [
                  if (!isReadOnlyEdit)
                    PermissionGate(
                      module: ledgerManifest.rbacModule,
                      action: action,
                      child: FilledButton(
                        onPressed: state.isSubmitting
                            ? null
                            : () {
                                if (_formKey.currentState?.validate() ??
                                    false) {
                                  bloc.add(const LedgerFormSubmitted());
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
                      module: ledgerManifest.rbacModule,
                      action: PermissionAction.delete,
                      child: OutlinedButton(
                        onPressed: state.isSubmitting
                            ? null
                            : () => _delete(context),
                        child: const Text('Delete'),
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
