import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/employee_employee/domain/employee.dart';
import 'package:algo_erp_front/features/employee_leave_allocation/data/leave_allocation_repository.dart';
import 'package:algo_erp_front/features/employee_leave_allocation/domain/leave_allocation.dart';
import 'package:algo_erp_front/features/employee_leave_policy/domain/leave_policy.dart';
import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final class LeaveAllocationFormState extends Equatable {
  LeaveAllocationFormState({
    required this.year,
    this.employee,
    this.policy,
    Decimal? allocated,
    Decimal? carried,
    this.submitting = false,
    this.seeding = false,
    this.error,
    this.created = false,
  }) : allocated = allocated ?? Decimal.zero,
       carried = carried ?? Decimal.zero;

  final Employee? employee;
  final LeavePolicy? policy;
  final int year;
  final Decimal allocated;
  final Decimal carried;
  final bool submitting;
  final bool seeding;
  final String? error;
  final bool created;

  LeaveAllocationFormState copyWith({
    Employee? Function()? employee,
    LeavePolicy? Function()? policy,
    int? year,
    Decimal? allocated,
    Decimal? carried,
    bool? submitting,
    bool? seeding,
    String? Function()? error,
    bool? created,
  }) {
    return LeaveAllocationFormState(
      employee: employee != null ? employee() : this.employee,
      policy: policy != null ? policy() : this.policy,
      year: year ?? this.year,
      allocated: allocated ?? this.allocated,
      carried: carried ?? this.carried,
      submitting: submitting ?? this.submitting,
      seeding: seeding ?? this.seeding,
      error: error != null ? error() : this.error,
      created: created ?? this.created,
    );
  }

  @override
  List<Object?> get props => [
    employee,
    policy,
    year,
    allocated,
    carried,
    submitting,
    seeding,
    error,
    created,
  ];
}

class LeaveAllocationFormCubit extends Cubit<LeaveAllocationFormState> {
  LeaveAllocationFormCubit({
    required LeaveAllocationRepository allocationRepository,
    required Repository<Employee, int> employeeRepository,
    int? initialEmployeeId,
    int? initialYear,
  }) : _allocationRepo = allocationRepository,
       _employeeRepo = employeeRepository,
       super(
         LeaveAllocationFormState(
           year: initialYear ?? DateTime.now().year,
           allocated: Decimal.zero,
           carried: Decimal.zero,
           seeding: initialEmployeeId != null,
         ),
       ) {
    if (initialEmployeeId != null) {
      seedEmployee(initialEmployeeId);
    }
  }

  final LeaveAllocationRepository _allocationRepo;
  final Repository<Employee, int> _employeeRepo;

  Future<void> seedEmployee(int id) async {
    final result = await _employeeRepo.getById(id);
    if (isClosed) return;
    result.fold(
      (_) => emit(state.copyWith(seeding: false)),
      (e) => emit(state.copyWith(employee: () => e, seeding: false)),
    );
  }

  void setEmployee(Employee? e) =>
      emit(state.copyWith(employee: () => e, error: () => null));

  void setPolicy(LeavePolicy? p) =>
      emit(state.copyWith(policy: () => p, error: () => null));

  void setYear(int year) => emit(state.copyWith(year: year));

  void setAllocated(Decimal v) => emit(state.copyWith(allocated: v));

  void setCarried(Decimal v) => emit(state.copyWith(carried: v));

  Future<void> submit({required bool Function() formIsValid}) async {
    if (!formIsValid()) return;
    final emp = state.employee;
    final policy = state.policy;
    if (emp == null || policy == null) {
      emit(
        state.copyWith(error: () => 'Employee and leave policy are required'),
      );
      return;
    }
    if (state.allocated <= Decimal.zero && state.carried <= Decimal.zero) {
      emit(
        state.copyWith(error: () => 'Enter allocated or carried-forward days'),
      );
      return;
    }

    emit(state.copyWith(submitting: true, error: () => null, created: false));

    final draft = LeaveAllocation(
      id: 0,
      employeeId: emp.id,
      leavePolicyId: policy.id,
      year: state.year,
      allocatedDays: state.allocated,
      carriedForward: state.carried,
      usedDays: Decimal.zero,
    );

    final result = await _allocationRepo.create(draft);
    if (isClosed) return;
    result.fold(
      (f) =>
          emit(state.copyWith(submitting: false, error: () => _messageOf(f))),
      (_) => emit(state.copyWith(submitting: false, created: true)),
    );
  }

  String _messageOf(Failure f) => switch (f) {
    NetworkFailure(:final message) => message,
    ValidationFailure(:final message) => message,
    ServerFailure(:final message) => message,
    ConflictFailure(:final message) => message,
    UnknownFailure(:final message) => message,
    _ => f.toString(),
  };
}
