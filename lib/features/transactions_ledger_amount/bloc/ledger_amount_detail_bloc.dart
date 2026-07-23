import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/error/safe_call.dart';
import 'package:algo_erp_front/core/vouchers/ledger_amount/ledger_amount_models.dart';
import 'package:algo_erp_front/core/vouchers/ledger_amount/ledger_amount_repository.dart';
import 'package:algo_erp_front/features/accounts_ledger/domain/ledger.dart';
import 'package:algo_erp_front/features/transactions_ledger_amount/bloc/ledger_amount_detail_event.dart';
import 'package:algo_erp_front/features/transactions_ledger_amount/bloc/ledger_amount_detail_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LedgerAmountDetailBloc
    extends Bloc<LedgerAmountDetailEvent, LedgerAmountDetailState> {
  LedgerAmountDetailBloc({
    required LedgerAmountRepository repository,
    required Repository<Ledger, int> ledgerRepository,
  }) : _repository = repository,
       _ledgerRepo = ledgerRepository,
       super(const LedgerAmountDetailState()) {
    on<LedgerAmountDetailFetchRequested>(_onFetchRequested);
    on<LedgerAmountDetailRefreshed>(_onRefreshed);
    on<LedgerAmountDetailCancelled>(_onCancelled);
    on<LedgerAmountDetailApproved>(_onApproved);
    on<LedgerAmountDetailRejected>(_onRejected);
  }

  final LedgerAmountRepository _repository;
  final Repository<Ledger, int> _ledgerRepo;

  Future<void> _onFetchRequested(
    LedgerAmountDetailFetchRequested event,
    Emitter<LedgerAmountDetailState> emit,
  ) async {
    emit(
      state.copyWith(
        status: LedgerAmountDetailStatus.loading,
        actionMessage: () => null,
      ),
    );

    final result = await _repository.getById(
      event.id,
      resolveLedgerLabel: (ledgerId) async {
        final r = await _ledgerRepo.getById(ledgerId);
        return r.fold((_) => null, (l) {
          final code = l.code;
          return (code == null || code.isEmpty) ? l.name : '$code — ${l.name}';
        });
      },
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: LedgerAmountDetailStatus.failure,
          failure: () => failure,
        ),
      ),
      (detail) => emit(
        state.copyWith(
          status: LedgerAmountDetailStatus.success,
          detail: detail,
        ),
      ),
    );
  }

  Future<void> _onRefreshed(
    LedgerAmountDetailRefreshed event,
    Emitter<LedgerAmountDetailState> emit,
  ) async {
    if (state.detail != null) {
      add(LedgerAmountDetailFetchRequested(state.detail!.id));
    }
  }

  Future<void> _onCancelled(
    LedgerAmountDetailCancelled event,
    Emitter<LedgerAmountDetailState> emit,
  ) => _run(emit, _repository.cancel, 'Cancelled');

  Future<void> _onApproved(
    LedgerAmountDetailApproved event,
    Emitter<LedgerAmountDetailState> emit,
  ) => _run(emit, _repository.approve, 'Approved');

  Future<void> _onRejected(
    LedgerAmountDetailRejected event,
    Emitter<LedgerAmountDetailState> emit,
  ) async {
    if (state.detail == null) return;
    emit(state.copyWith(isBusy: true, actionMessage: () => null));
    final result = await _repository.reject(state.detail!.id, event.reason);
    result.fold(
      (failure) => emit(
        state.copyWith(isBusy: false, actionMessage: () => _messageOf(failure)),
      ),
      (r) {
        emit(
          state.copyWith(
            isBusy: false,
            actionMessage: () => r.message ?? 'Rejected',
          ),
        );
        add(LedgerAmountDetailFetchRequested(state.detail!.id));
      },
    );
  }

  Future<void> _run(
    Emitter<LedgerAmountDetailState> emit,
    Future<Result<LedgerAmountLifecycleResult>> Function(int id) call,
    String fallback,
  ) async {
    if (state.detail == null) return;
    emit(state.copyWith(isBusy: true, actionMessage: () => null));
    final result = await call(state.detail!.id);
    result.fold(
      (failure) => emit(
        state.copyWith(isBusy: false, actionMessage: () => _messageOf(failure)),
      ),
      (r) {
        emit(
          state.copyWith(
            isBusy: false,
            actionMessage: () => r.message ?? fallback,
          ),
        );
        add(LedgerAmountDetailFetchRequested(state.detail!.id));
      },
    );
  }

  String _messageOf(Failure f) => switch (f) {
    NetworkFailure(:final message) => message,
    TimeoutFailure(:final message) => message,
    UnauthorizedFailure(:final message) => message,
    ForbiddenFailure(:final message) => message,
    ValidationFailure(:final message) => message,
    NotFoundFailure(:final message) => message,
    ConflictFailure(:final message) => message,
    ServerFailure(:final message) => message,
    CacheFailure(:final message) => message,
    UnknownFailure(:final message) => message,
  };
}
