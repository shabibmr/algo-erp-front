import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:algo_erp_front/core/auth/permission_gate.dart';
import 'package:algo_erp_front/core/bloc/crud_contract.dart';
import 'package:algo_erp_front/core/bloc/detail_bloc.dart';
import 'package:algo_erp_front/core/bloc/master_form_cubit.dart';
import 'package:algo_erp_front/core/bloc/master_form_state.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/manifest/field_renderer.dart';
import 'package:algo_erp_front/core/manifest/form_field_spec.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/core/utils/extensions/view_state_x.dart';
import 'package:algo_erp_front/core/widgets/async_state_view.dart';
import 'package:algo_erp_front/core/widgets/dialogs/confirm_dialog.dart';
import 'package:algo_erp_front/core/widgets/layout/field_widths.dart';
import 'package:algo_erp_front/core/widgets/layout/form_field_layout.dart';
import 'package:algo_erp_front/features/employee_employee/domain/employee.dart';
import 'package:algo_erp_front/features/employee_employee/employee_di.dart';
import 'package:algo_erp_front/features/employee_employee/employee_extension_fields.dart';
import 'package:algo_erp_front/features/employee_employee/employee_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Tabbed employee form: Core + Bank + Salary (nested in one payload).
class EmployeeFormPage extends StatelessWidget {
  const EmployeeFormPage({required this.mode, super.key, this.entityId});

  final FormMode mode;
  final int? entityId;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<Repository<Employee, int>>(
      create: (_) => createEmployeeRepository(getIt<DioClient>()),
      child: Builder(
        builder: (context) {
          final title = mode == FormMode.create
              ? 'New ${employeeManifest.label}'
              : employeeManifest.supportsUpdate
              ? 'Edit ${employeeManifest.label}'
              : 'View ${employeeManifest.label}';
          return AdaptiveLayout(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 16),
                Expanded(
                  child: BlocProvider(
                    create: (_) => MasterFormCubit<Employee, int>(
                      manifest: employeeManifest,
                      mode: mode,
                      idOf: (e) => e.id,
                      formFields: allEmployeeFormFields(
                        employeeManifest.formFields,
                      ),
                    ),
                    child: mode == FormMode.edit
                        ? BlocProvider<DetailBloc<Employee, int>>(
                            create: (ctx) => DetailBloc<Employee, int>(
                              repository: ctx.read<Repository<Employee, int>>(),
                              id: entityId!,
                            )..add(const DetailLoadRequested()),
                            child: _EmployeeTabbedForm(mode: mode),
                          )
                        : _EmployeeTabbedForm(mode: mode),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EmployeeTabbedForm extends StatefulWidget {
  const _EmployeeTabbedForm({required this.mode});

  final FormMode mode;

  @override
  State<_EmployeeTabbedForm> createState() => _EmployeeTabbedFormState();
}

class _EmployeeTabbedFormState extends State<_EmployeeTabbedForm>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _refreshListAndReturn(BuildContext context) {
    employeeCrudBloc(context).add(const CrudRefreshRequested());
    context.go(employeeManifest.resourcePath);
  }

  Future<void> _delete(BuildContext context) async {
    if (!employeeManifest.supportsDelete) return;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete ${employeeManifest.label}?',
      message: employeeManifest.hardDelete
          ? 'This cannot be undone.'
          : 'This can be restored later.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    context.read<DetailBloc<Employee, int>>().add(
      const DetailDeleteRequested(),
    );
  }

  Widget _fieldList(
    MasterFormCubit<Employee, int> cubit,
    MasterFormState<Employee> state,
    List<FormFieldSpec<Employee>> fields,
  ) {
    final tokens = context.tokens;
    final isReadOnlyEdit =
        widget.mode == FormMode.edit && !employeeManifest.supportsUpdate;
    final draft = state.draft;
    if (draft == null) return const SizedBox.shrink();

    final items = <FormFieldLayoutItem>[
      for (final field in fields)
        FormFieldLayoutItem(
          type: field.type,
          half: field.half,
          child: FieldRenderer.build<Employee>(
            field: field,
            value: MasterFormCubit.isFkType(field.type)
                ? state.fkDisplayCache[field.key]
                : field.getValue(draft),
            onChanged: (value) => cubit.setField(field, value),
            enabled: !state.submitting && !isReadOnlyEdit,
            errorText: state.fieldErrors[field.errorKey],
            fkLoaderOverride: MasterFormCubit.isFkType(field.type)
                ? (q) => cubit.fkLoader(field, q)
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

  Widget _buildForm(
    Repository<Employee, int> repo,
    MasterFormCubit<Employee, int> cubit,
    MasterFormState<Employee> state,
  ) {
    final tokens = context.tokens;
    final action = widget.mode == FormMode.create
        ? PermissionAction.create
        : PermissionAction.update;
    final isReadOnlyEdit =
        widget.mode == FormMode.edit && !employeeManifest.supportsUpdate;
    final canDelete =
        widget.mode == FormMode.edit && employeeManifest.supportsDelete;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isReadOnlyEdit) ...[
            Container(
              padding: EdgeInsets.all(tokens.spacing.sm),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(tokens.radii.sm),
              ),
              child: const Text('This entity cannot be edited.'),
            ),
            SizedBox(height: tokens.spacing.md),
          ],
          if (state.generalError != null) ...[
            Container(
              padding: EdgeInsets.all(tokens.spacing.sm),
              decoration: BoxDecoration(
                color: tokens.semanticColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(tokens.radii.sm),
              ),
              child: Text(
                state.generalError!,
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
              Tab(text: 'Salary'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _fieldList(cubit, state, employeeManifest.formFields),
                _fieldList(cubit, state, employeeBankFormFields),
                _fieldList(cubit, state, employeeSalaryFormFields),
              ],
            ),
          ),
          SizedBox(height: tokens.spacing.md),
          Row(
            children: [
              if (!isReadOnlyEdit)
                PermissionGate(
                  module: employeeManifest.rbacModule,
                  action: action,
                  child: FilledButton(
                    onPressed: state.submitting
                        ? null
                        : () => cubit.submit(
                            repository: repo,
                            formIsValid: () =>
                                _formKey.currentState?.validate() ?? false,
                          ),
                    child: Text(
                      state.submitting
                          ? 'Saving...'
                          : (widget.mode == FormMode.create
                                ? 'Create'
                                : 'Save'),
                    ),
                  ),
                ),
              if (canDelete) ...[
                if (!isReadOnlyEdit) SizedBox(width: tokens.spacing.sm),
                PermissionGate(
                  module: employeeManifest.rbacModule,
                  action: PermissionAction.delete,
                  child: OutlinedButton(
                    onPressed: state.submitting ? null : () => _delete(context),
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryProvider.of<Repository<Employee, int>>(context);

    return BlocListener<
      MasterFormCubit<Employee, int>,
      MasterFormState<Employee>
    >(
      listenWhen: (previous, current) =>
          previous.savedEntity != current.savedEntity &&
              current.savedEntity != null ||
          previous.serverErrorsVersion != current.serverErrorsVersion,
      listener: (context, state) {
        if (state.savedEntity != null) {
          _refreshListAndReturn(context);
          return;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _formKey.currentState?.validate();
        });
      },
      child: widget.mode == FormMode.create
          ? BlocBuilder<
              MasterFormCubit<Employee, int>,
              MasterFormState<Employee>
            >(
              builder: (context, state) {
                final cubit = context.read<MasterFormCubit<Employee, int>>();
                return _buildForm(repo, cubit, state);
              },
            )
          : MultiBlocListener(
              listeners: [
                BlocListener<DetailBloc<Employee, int>, DetailState<Employee>>(
                  listener: (context, state) {
                    if (state is DetailDeleted<Employee>) {
                      _refreshListAndReturn(context);
                    }
                  },
                ),
                BlocListener<DetailBloc<Employee, int>, DetailState<Employee>>(
                  listenWhen: (previous, current) =>
                      current is DetailLoaded<Employee> &&
                      previous is! DetailLoaded<Employee>,
                  listener: (context, state) {
                    if (state is DetailLoaded<Employee>) {
                      context
                          .read<MasterFormCubit<Employee, int>>()
                          .seedFromEntity(state.entity);
                    }
                  },
                ),
              ],
              child:
                  BlocBuilder<DetailBloc<Employee, int>, DetailState<Employee>>(
                    builder: (context, detailState) {
                      return AsyncStateView<Employee>(
                        state: detailState.toViewState(),
                        onRetry: () => context
                            .read<DetailBloc<Employee, int>>()
                            .add(const DetailLoadRequested()),
                        builder: (context, _) {
                          return BlocBuilder<
                            MasterFormCubit<Employee, int>,
                            MasterFormState<Employee>
                          >(
                            builder: (context, formState) {
                              final cubit = context
                                  .read<MasterFormCubit<Employee, int>>();
                              if (formState.draft == null) {
                                return const SizedBox.shrink();
                              }
                              return _buildForm(repo, cubit, formState);
                            },
                          );
                        },
                      );
                    },
                  ),
            ),
    );
  }
}
