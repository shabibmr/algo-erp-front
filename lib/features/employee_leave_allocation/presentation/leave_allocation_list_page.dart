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
import 'package:algo_erp_front/core/widgets/states/empty_state.dart';
import 'package:algo_erp_front/core/widgets/states/error_state.dart';
import 'package:algo_erp_front/core/widgets/states/loading_state.dart';
import 'package:algo_erp_front/features/employee_employee/domain/employee.dart';
import 'package:algo_erp_front/features/employee_employee/employee_di.dart';
import 'package:algo_erp_front/features/employee_leave_allocation/domain/leave_allocation.dart';
import 'package:algo_erp_front/features/employee_leave_allocation/leave_allocation_di.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Per-employee leave balances for a year (no global list API).
class LeaveAllocationListPage extends StatefulWidget {
  const LeaveAllocationListPage({super.key});

  @override
  State<LeaveAllocationListPage> createState() =>
      _LeaveAllocationListPageState();
}

class _LeaveAllocationListPageState extends State<LeaveAllocationListPage> {
  final _employeeRepo = createEmployeeRepository(getIt<DioClient>());
  final _allocationRepo = createLeaveAllocationRepository(getIt<DioClient>());

  Employee? _employee;
  late int _year;
  List<LeaveAllocation>? _items;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _year = DateTime.now().year;
  }

  Future<List<Employee>> _searchEmployees(String query) async {
    final result = await _employeeRepo.list(PageQuery(search: query));
    return result.fold((_) => const [], (page) => page.items);
  }

  Future<void> _load() async {
    final emp = _employee;
    if (emp == null) {
      setState(() {
        _items = null;
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _allocationRepo.listForEmployee(
      employeeId: emp.id,
      year: _year,
    );
    if (!mounted) return;
    result.fold(
      (f) => setState(() {
        _loading = false;
        _error = _messageOf(f);
        _items = null;
      }),
      (rows) => setState(() {
        _loading = false;
        _items = rows;
      }),
    );
  }

  String _messageOf(Failure f) => switch (f) {
    NetworkFailure(:final message) => message,
    ValidationFailure(:final message) => message,
    ServerFailure(:final message) => message,
    UnknownFailure(:final message) => message,
    _ => f.toString(),
  };

  String _employeeLabel(Employee e) {
    final code = e.code;
    return (code == null || code.isEmpty) ? e.name : '$code — ${e.name}';
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final items = _items;

    return AdaptiveLayout(
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
                  onPressed: () async {
                    final created = await context.push<bool>(
                      '/employee/leave/allocations/new',
                      extra: {'employeeId': _employee?.id, 'year': _year},
                    );
                    if ((created ?? false) && mounted) await _load();
                  },
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
                  value: _employee,
                  displayOf: _employeeLabel,
                  loader: _searchEmployees,
                  onSelected: (e) {
                    setState(() => _employee = e);
                    _load();
                  },
                ),
              ),
              SizedBox(width: tokens.spacing.md),
              Expanded(
                child: AppNumberField(
                  label: 'Year',
                  initialValue: _year,
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _year = v);
                    _load();
                  },
                ),
              ),
              SizedBox(width: tokens.spacing.sm),
              Padding(
                padding: EdgeInsets.only(top: tokens.spacing.lg),
                child: OutlinedButton(
                  onPressed: _employee == null || _loading ? null : _load,
                  child: const Text('Refresh'),
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.spacing.lg),
          Expanded(child: _body(context)),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_employee == null) {
      return const EmptyState(
        message: 'Choose an employee — allocations are listed per year.',
      );
    }
    if (_loading) {
      return const LoadingState();
    }
    if (_error != null) {
      return ErrorState(failure: Failure.unknown(_error!), onRetry: _load);
    }
    final items = _items ?? const <LeaveAllocation>[];
    if (items.isEmpty) {
      return EmptyState(
        message: 'No allocations for $_year. Allocate a leave policy.',
        actionLabel: 'Allocate',
        onAction: () => context.push(
          '/employee/leave/allocations/new',
          extra: {'employeeId': _employee?.id, 'year': _year},
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
