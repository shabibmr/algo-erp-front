import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:algo_erp_front/core/auth/permission_gate.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/core/widgets/data_display/adaptive_entity_list.dart';
import 'package:algo_erp_front/core/widgets/fields/app_number_field.dart';
import 'package:algo_erp_front/core/widgets/layout/page_header.dart';
import 'package:algo_erp_front/core/widgets/lookup/fk_lookup_field.dart';
import 'package:algo_erp_front/core/widgets/shortcuts/create_new_shortcuts.dart';
import 'package:algo_erp_front/core/widgets/states/empty_state.dart';
import 'package:algo_erp_front/core/widgets/states/error_state.dart';
import 'package:algo_erp_front/core/widgets/states/loading_state.dart';
import 'package:algo_erp_front/features/employee_employee/domain/employee.dart';
import 'package:algo_erp_front/features/employee_employee/employee_di.dart';
import 'package:algo_erp_front/features/employee_leave_allocation/cubit/leave_allocation_list_cubit.dart';
import 'package:algo_erp_front/features/employee_leave_allocation/domain/leave_allocation.dart';
import 'package:algo_erp_front/features/employee_leave_allocation/leave_allocation_di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Per-employee leave balances for a year (no global list API).
class LeaveAllocationListPage extends StatelessWidget {
  const LeaveAllocationListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LeaveAllocationListCubit(
        allocationRepository: createLeaveAllocationRepository(
          getIt<DioClient>(),
        ),
      ),
      child: const _LeaveAllocationListView(),
    );
  }
}

class _LeaveAllocationListView extends StatelessWidget {
  const _LeaveAllocationListView();

  Future<List<Employee>> _searchEmployees(String query) async {
    final result = await createEmployeeRepository(
      getIt<DioClient>(),
    ).list(PageQuery(search: query));
    return result.fold((_) => const [], (page) => page.items);
  }

  String _employeeLabel(Employee e) {
    final code = e.code;
    return (code == null || code.isEmpty) ? e.name : '$code — ${e.name}';
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return BlocBuilder<LeaveAllocationListCubit, LeaveAllocationListState>(
      builder: (context, state) {
        final cubit = context.read<LeaveAllocationListCubit>();
        final items = state.items;

        Future<void> openAllocate() async {
          final created = await context.push<bool>(
            '/employee/leave/allocations/new',
            extra: {'employeeId': state.employee?.id, 'year': state.year},
          );
          if ((created ?? false) && context.mounted) {
            await cubit.load();
          }
        }

        return AdaptiveLayout(
          child: CreateNewShortcuts(
            module: 'Employee',
            onCreate: openAllocate,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(
                  eyebrow: 'Employee',
                  title: 'Leave allocation',
                  subtitle: items == null ? null : '${items.length} policies',
                  actions: [
                    PermissionGate(
                      module: 'Employee',
                      action: PermissionAction.create,
                      child: FilledButton.icon(
                        onPressed: openAllocate,
                        icon: const Icon(Icons.add),
                        label: const Text('Allocate'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: tokens.spacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: FkLookupField<Employee>(
                        label: 'Employee',
                        value: state.employee,
                        displayOf: _employeeLabel,
                        loader: _searchEmployees,
                        onSelected: cubit.setEmployee,
                      ),
                    ),
                    SizedBox(width: tokens.spacing.md),
                    Expanded(
                      child: AppNumberField(
                        label: 'Year',
                        value: state.year,
                        onChanged: (v) {
                          if (v == null) return;
                          cubit.setYear(v);
                        },
                      ),
                    ),
                    SizedBox(width: tokens.spacing.sm),
                    Padding(
                      padding: EdgeInsets.only(top: tokens.spacing.lg),
                      child: OutlinedButton(
                        onPressed: state.employee == null || state.loading
                            ? null
                            : cubit.load,
                        child: const Text('Refresh'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: tokens.spacing.lg),
                Expanded(child: _body(context, state)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _body(BuildContext context, LeaveAllocationListState state) {
    if (state.employee == null) {
      return const EmptyState(
        message: 'Choose an employee — allocations are listed per year.',
      );
    }
    if (state.loading) {
      return const LoadingState();
    }
    if (state.error != null) {
      return ErrorState(
        failure: Failure.unknown(state.error!),
        onRetry: context.read<LeaveAllocationListCubit>().load,
      );
    }
    final items = state.items ?? const <LeaveAllocation>[];
    if (items.isEmpty) {
      return EmptyState(
        message: 'No allocations for ${state.year}. Allocate a leave policy.',
        actionLabel: 'Allocate',
        onAction: () => context.push(
          '/employee/leave/allocations/new',
          extra: {'employeeId': state.employee?.id, 'year': state.year},
        ),
      );
    }

    return AdaptiveEntityList<LeaveAllocation>(
      items: items,
      keyOf: (a) => a.id,
      columns: [
        EntityColumn(
          label: 'Policy',
          primary: true,
          flex: 2,
          cellBuilder: (_, a) =>
              Text(a.policyName ?? a.policyLeaveType ?? '#${a.leavePolicyId}'),
        ),
        EntityColumn(
          label: 'Type',
          cellBuilder: (_, a) => Text(a.policyLeaveType ?? '—'),
        ),
        EntityColumn(
          label: 'Allocated',
          mono: true,
          cellBuilder: (_, a) => Text(a.allocatedDays.toString()),
        ),
        EntityColumn(
          label: 'Carried',
          mono: true,
          cellBuilder: (_, a) => Text(a.carriedForward.toString()),
        ),
        EntityColumn(
          label: 'Used',
          mono: true,
          cellBuilder: (_, a) => Text(a.usedDays.toString()),
        ),
        EntityColumn(
          label: 'Remaining',
          mono: true,
          cellBuilder: (_, a) => Text(a.remaining.toString()),
        ),
      ],
    );
  }
}
