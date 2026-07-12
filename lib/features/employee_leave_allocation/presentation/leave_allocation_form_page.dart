import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:algo_erp_front/core/auth/permission_gate.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/core/widgets/fields/app_decimal_field.dart';
import 'package:algo_erp_front/core/widgets/fields/app_number_field.dart';
import 'package:algo_erp_front/core/widgets/lookup/fk_lookup_field.dart';
import 'package:algo_erp_front/features/employee_employee/domain/employee.dart';
import 'package:algo_erp_front/features/employee_employee/employee_di.dart';
import 'package:algo_erp_front/features/employee_leave_allocation/domain/leave_allocation.dart';
import 'package:algo_erp_front/features/employee_leave_allocation/leave_allocation_di.dart';
import 'package:algo_erp_front/features/employee_leave_policy/domain/leave_policy.dart';
import 'package:algo_erp_front/features/employee_leave_policy/leave_policy_di.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Create leave allocation for an employee + policy + year.
class LeaveAllocationFormPage extends StatefulWidget {
  const LeaveAllocationFormPage({
    super.key,
    this.initialEmployeeId,
    this.initialYear,
  });

  final int? initialEmployeeId;
  final int? initialYear;

  @override
  State<LeaveAllocationFormPage> createState() =>
      _LeaveAllocationFormPageState();
}

class _LeaveAllocationFormPageState extends State<LeaveAllocationFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _employeeRepo = createEmployeeRepository(getIt<DioClient>());
  final _policyRepo = createLeavePolicyRepository(getIt<DioClient>());
  final _allocationRepo = createLeaveAllocationRepository(getIt<DioClient>());

  Employee? _employee;
  LeavePolicy? _policy;
  late int _year;
  Decimal _allocated = Decimal.zero;
  Decimal _carried = Decimal.zero;
  bool _submitting = false;
  bool _seeding = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _year = widget.initialYear ?? DateTime.now().year;
    final empId = widget.initialEmployeeId;
    if (empId != null) {
      _seeding = true;
      _seedEmployee(empId);
    }
  }

  Future<void> _seedEmployee(int id) async {
    final result = await _employeeRepo.getById(id);
    if (!mounted) return;
    result.fold(
      (_) => setState(() => _seeding = false),
      (e) => setState(() {
        _employee = e;
        _seeding = false;
      }),
    );
  }

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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final emp = _employee;
    final policy = _policy;
    if (emp == null || policy == null) {
      setState(() => _error = 'Employee and leave policy are required');
      return;
    }
    if (_allocated <= Decimal.zero && _carried <= Decimal.zero) {
      setState(() => _error = 'Enter allocated or carried-forward days');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final draft = LeaveAllocation(
      id: 0,
      employeeId: emp.id,
      leavePolicyId: policy.id,
      year: _year,
      allocatedDays: _allocated,
      carriedForward: _carried,
      usedDays: Decimal.zero,
    );

    final result = await _allocationRepo.create(draft);
    if (!mounted) return;
    result.fold(
      (f) => setState(() {
        _submitting = false;
        _error = switch (f) {
          NetworkFailure(:final message) => message,
          ValidationFailure(:final message) => message,
          ServerFailure(:final message) => message,
          ConflictFailure(:final message) => message,
          UnknownFailure(:final message) => message,
          _ => f.toString(),
        };
      }),
      (_) {
        if (context.canPop()) {
          context.pop(true);
        } else {
          context.go('/employee/leave/allocations');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    if (_seeding) {
      return const AdaptiveLayout(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return AdaptiveLayout(
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
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: tokens.brand.inkMuted),
            ),
            SizedBox(height: tokens.spacing.lg),
            if (_error != null) ...[
              Container(
                padding: EdgeInsets.all(tokens.spacing.sm),
                decoration: BoxDecoration(
                  color: tokens.semanticColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(tokens.radii.sm),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: tokens.semanticColors.danger),
                ),
              ),
              SizedBox(height: tokens.spacing.md),
            ],
            FkLookupField<Employee>(
              label: 'Employee',
              value: _employee,
              displayOf: _employeeLabel,
              loader: _searchEmployees,
              enabled: !_submitting,
              validator: (v) => v == null ? 'Required' : null,
              onSelected: (e) => setState(() => _employee = e),
            ),
            SizedBox(height: tokens.spacing.sm),
            FkLookupField<LeavePolicy>(
              label: 'Leave policy',
              value: _policy,
              displayOf: (p) => p.displayName,
              loader: _searchPolicies,
              enabled: !_submitting,
              validator: (v) => v == null ? 'Required' : null,
              onSelected: (p) => setState(() => _policy = p),
            ),
            SizedBox(height: tokens.spacing.sm),
            AppNumberField(
              label: 'Year',
              initialValue: _year,
              enabled: !_submitting,
              validator: (v) {
                if (v == null) return 'Required';
                if (v < 2000 || v > 2100) return 'Enter a valid year';
                return null;
              },
              onChanged: (v) {
                if (v != null) setState(() => _year = v);
              },
            ),
            SizedBox(height: tokens.spacing.sm),
            AppDecimalField(
              label: 'Allocated days',
              initialValue: _allocated,
              enabled: !_submitting,
              onChanged: (v) {
                if (v != null) setState(() => _allocated = v);
              },
            ),
            SizedBox(height: tokens.spacing.sm),
            AppDecimalField(
              label: 'Carried forward',
              initialValue: _carried,
              enabled: !_submitting,
              helperText: 'Days brought forward from prior year',
              onChanged: (v) {
                if (v != null) setState(() => _carried = v);
              },
            ),
            SizedBox(height: tokens.spacing.lg),
            Row(
              children: [
                PermissionGate(
                  module: 'Employee',
                  action: PermissionAction.create,
                  child: FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: Text(_submitting ? 'Saving…' : 'Allocate'),
                  ),
                ),
                SizedBox(width: tokens.spacing.sm),
                TextButton(
                  onPressed: _submitting
                      ? null
                      : () {
                          if (context.canPop()) {
                            context.pop(false);
                          } else {
                            context.go('/employee/leave/allocations');
                          }
                        },
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
