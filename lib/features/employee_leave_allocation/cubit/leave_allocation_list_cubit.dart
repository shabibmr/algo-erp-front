import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/employee_employee/domain/employee.dart';
import 'package:algo_erp_front/features/employee_leave_allocation/data/leave_allocation_repository.dart';
import 'package:algo_erp_front/features/employee_leave_allocation/domain/leave_allocation.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final class LeaveAllocationListState extends Equatable {
  const LeaveAllocationListState({
    required this.year,
    this.employee,
    this.items,
    this.loading = false,
    this.error,
  });

  final Employee? employee;
  final int year;
  final List<LeaveAllocation>? items;
  final bool loading;
  final String? error;

  LeaveAllocationListState copyWith({
    Employee? Function()? employee,
    int? year,
    List<LeaveAllocation>? Function()? items,
    bool? loading,
    String? Function()? error,
  }) {
    return LeaveAllocationListState(
      employee: employee != null ? employee() : this.employee,
      year: year ?? this.year,
      items: items != null ? items() : this.items,
      loading: loading ?? this.loading,
      error: error != null ? error() : this.error,
    );
  }

  @override
  List<Object?> get props => [employee, year, items, loading, error];
}

class LeaveAllocationListCubit extends Cubit<LeaveAllocationListState> {
  LeaveAllocationListCubit({
    required LeaveAllocationRepository allocationRepository,
  }) : _allocationRepo = allocationRepository,
       super(LeaveAllocationListState(year: DateTime.now().year));

  final LeaveAllocationRepository _allocationRepo;

  void setEmployee(Employee? e) {
    emit(
      state.copyWith(employee: () => e, items: () => null, error: () => null),
    );
    load();
  }

  void setYear(int year) {
    emit(state.copyWith(year: year));
    load();
  }

  Future<void> load() async {
    final emp = state.employee;
    if (emp == null) {
      emit(
        state.copyWith(items: () => null, error: () => null, loading: false),
      );
      return;
    }
    emit(state.copyWith(loading: true, error: () => null));
    final result = await _allocationRepo.listForEmployee(
      employeeId: emp.id,
      year: state.year,
    );
    if (isClosed) return;
    result.fold(
      (f) => emit(
        state.copyWith(
          loading: false,
          error: () => _messageOf(f),
          items: () => null,
        ),
      ),
      (rows) => emit(
        state.copyWith(loading: false, items: () => rows, error: () => null),
      ),
    );
  }

  String _messageOf(Failure f) => switch (f) {
    NetworkFailure(:final message) => message,
    ValidationFailure(:final message) => message,
    ServerFailure(:final message) => message,
    UnknownFailure(:final message) => message,
    _ => f.toString(),
  };
}
