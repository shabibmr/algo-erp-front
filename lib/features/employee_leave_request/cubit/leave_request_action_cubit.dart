import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/employee_leave_request/data/leave_request_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final class LeaveRequestActionState extends Equatable {
  const LeaveRequestActionState({
    this.busy = false,
    this.error,
    this.done = false,
  });

  final bool busy;
  final String? error;
  final bool done;

  LeaveRequestActionState copyWith({
    bool? busy,
    String? Function()? error,
    bool? done,
  }) {
    return LeaveRequestActionState(
      busy: busy ?? this.busy,
      error: error != null ? error() : this.error,
      done: done ?? this.done,
    );
  }

  @override
  List<Object?> get props => [busy, error, done];
}

class LeaveRequestActionCubit extends Cubit<LeaveRequestActionState> {
  LeaveRequestActionCubit({
    required LeaveRequestRepository repository,
    required this.entityId,
  }) : _repo = repository,
       super(const LeaveRequestActionState());

  final LeaveRequestRepository _repo;
  final int entityId;

  Future<void> setStatus(String status, {String? reason}) async {
    emit(state.copyWith(busy: true, error: () => null, done: false));
    final result = await _repo.updateStatus(entityId, status, reason: reason);
    if (isClosed) return;
    result.fold(
      (f) => emit(state.copyWith(busy: false, error: () => _messageOf(f))),
      (_) => emit(state.copyWith(busy: false, done: true)),
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
