import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:algo_erp_front/core/auth/permission_gate.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/core/widgets/fields/app_decimal_field.dart';
import 'package:algo_erp_front/core/widgets/fields/app_number_field.dart';
import 'package:algo_erp_front/core/widgets/layout/field_widths.dart';
import 'package:algo_erp_front/core/widgets/layout/form_field_layout.dart';
import 'package:algo_erp_front/core/widgets/layout/work_sheet.dart';
import 'package:algo_erp_front/core/widgets/lookup/fk_lookup_field.dart';
import 'package:algo_erp_front/features/employee_employee/domain/employee.dart';
import 'package:algo_erp_front/features/employee_employee/employee_di.dart';
import 'package:algo_erp_front/features/employee_leave_allocation/cubit/leave_allocation_form_cubit.dart';
import 'package:algo_erp_front/features/employee_leave_allocation/leave_allocation_di.dart';
import 'package:algo_erp_front/features/employee_leave_policy/domain/leave_policy.dart';
import 'package:algo_erp_front/features/employee_leave_policy/leave_policy_di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Create leave allocation for an employee + policy + year.
class LeaveAllocationFormPage extends StatelessWidget {
  const LeaveAllocationFormPage({
    super.key,
    this.initialEmployeeId,
    this.initialYear,
  });

  final int? initialEmployeeId;
  final int? initialYear;

  @override
  Widget build(BuildContext context) {
    final dio = getIt<DioClient>();
    return BlocProvider(
      create: (_) => LeaveAllocationFormCubit(
        allocationRepository: createLeaveAllocationRepository(dio),
        employeeRepository: createEmployeeRepository(dio),
        initialEmployeeId: initialEmployeeId,
        initialYear: initialYear,
      ),
      child: const _LeaveAllocationFormView(),
    );
  }
}

class _LeaveAllocationFormView extends StatefulWidget {
  const _LeaveAllocationFormView();

  @override
  State<_LeaveAllocationFormView> createState() =>
      _LeaveAllocationFormViewState();
}

class _LeaveAllocationFormViewState extends State<_LeaveAllocationFormView> {
  final _formKey = GlobalKey<FormState>();
  late final _employeeRepo = createEmployeeRepository(getIt<DioClient>());
  late final _policyRepo = createLeavePolicyRepository(getIt<DioClient>());

  Future<List<Employee>> _searchEmployees(String query) async {
    final result = await _employeeRepo.list(PageQuery(search: query));
    return result.fold((_) => const [], (page) => page.items);
  }

  Future<List<LeavePolicy>> _searchPolicies(String query) async {
    final result = await _policyRepo.list(PageQuery(search: query));
    return result.fold((_) => const [], (page) => page.items);
  }

  String _employeeLabel(Employee e) {
    final code = e.code;
    return (code == null || code.isEmpty) ? e.name : '$code — ${e.name}';
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return BlocListener<LeaveAllocationFormCubit, LeaveAllocationFormState>(
      listenWhen: (p, c) => !p.created && c.created,
      listener: (context, state) {
        if (context.canPop()) {
          context.pop(true);
        } else {
          context.go('/employee/leave/allocations');
        }
      },
      child: BlocBuilder<LeaveAllocationFormCubit, LeaveAllocationFormState>(
        builder: (context, state) {
          final cubit = context.read<LeaveAllocationFormCubit>();

          if (state.seeding) {
            return const AdaptiveLayout(
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final gap = SizedBox(height: tokens.spacing.md);

          return AdaptiveLayout(
            maxContentWidth: FieldWidths.formContent,
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  Text(
                    'Allocate leave',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  SizedBox(height: tokens.spacing.xs),
                  Text(
                    'Assign a leave policy balance for one employee and year.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: tokens.brand.inkMuted,
                    ),
                  ),
                  SizedBox(height: tokens.spacing.md),
                  if (state.error != null) ...[
                    Container(
                      padding: EdgeInsets.all(tokens.spacing.sm),
                      decoration: BoxDecoration(
                        color: tokens.semanticColors.danger.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(tokens.radii.sm),
                      ),
                      child: Text(
                        state.error!,
                        style: TextStyle(color: tokens.semanticColors.danger),
                      ),
                    ),
                    gap,
                  ],
                  WorkSheet(
                    fill: false,
                    padding: EdgeInsets.symmetric(
                      horizontal: tokens.spacing.md,
                      vertical: tokens.spacing.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        constrainFormField(
                          FkLookupField<Employee>(
                            label: 'Employee',
                            value: state.employee,
                            displayOf: _employeeLabel,
                            loader: _searchEmployees,
                            enabled: !state.submitting,
                            validator: (v) => v == null ? 'Required' : null,
                            onSelected: cubit.setEmployee,
                          ),
                          maxWidth: FieldWidths.picker,
                        ),
                        gap,
                        constrainFormField(
                          FkLookupField<LeavePolicy>(
                            label: 'Leave policy',
                            value: state.policy,
                            displayOf: (p) => p.displayName,
                            loader: _searchPolicies,
                            enabled: !state.submitting,
                            validator: (v) => v == null ? 'Required' : null,
                            onSelected: cubit.setPolicy,
                          ),
                          maxWidth: FieldWidths.picker,
                        ),
                        gap,
                        constrainFormField(
                          AppNumberField(
                            label: 'Year',
                            value: state.year,
                            enabled: !state.submitting,
                            validator: (v) {
                              if (v == null) return 'Required';
                              if (v < 2000 || v > 2100) {
                                return 'Enter a valid year';
                              }
                              return null;
                            },
                            onChanged: (v) {
                              if (v != null) cubit.setYear(v);
                            },
                          ),
                          maxWidth: FieldWidths.number,
                        ),
                        gap,
                        constrainFormField(
                          AppDecimalField(
                            label: 'Allocated days',
                            value: state.allocated,
                            enabled: !state.submitting,
                            onChanged: (v) {
                              if (v != null) cubit.setAllocated(v);
                            },
                          ),
                          maxWidth: FieldWidths.number,
                        ),
                        gap,
                        constrainFormField(
                          AppDecimalField(
                            label: 'Carried forward',
                            value: state.carried,
                            enabled: !state.submitting,
                            helperText:
                                'Days brought forward from prior year',
                            onChanged: (v) {
                              if (v != null) cubit.setCarried(v);
                            },
                          ),
                          maxWidth: FieldWidths.number,
                        ),
                        SizedBox(height: tokens.spacing.lg),
                        Row(
                          children: [
                            PermissionGate(
                              module: 'Employee',
                              action: PermissionAction.create,
                              child: FilledButton(
                                onPressed: state.submitting
                                    ? null
                                    : () => cubit.submit(
                                        formIsValid: () =>
                                            _formKey.currentState
                                                ?.validate() ??
                                            false,
                                      ),
                                child: Text(
                                  state.submitting ? 'Saving…' : 'Allocate',
                                ),
                              ),
                            ),
                            SizedBox(width: tokens.spacing.sm),
                            TextButton(
                              onPressed: state.submitting
                                  ? null
                                  : () {
                                      if (context.canPop()) {
                                        context.pop(false);
                                      } else {
                                        context.go(
                                          '/employee/leave/allocations',
                                        );
                                      }
                                    },
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
