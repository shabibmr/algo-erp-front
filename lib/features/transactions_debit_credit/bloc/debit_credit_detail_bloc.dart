import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/vouchers/debit_credit/debit_credit_repository.dart';
import 'package:algo_erp_front/features/accounts_ledger/domain/ledger.dart';
import 'package:algo_erp_front/features/transactions_debit_credit/bloc/debit_credit_detail_event.dart';
import 'package:algo_erp_front/features/transactions_debit_credit/bloc/debit_credit_detail_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DebitCreditDetailBloc
    extends Bloc<DebitCreditDetailEvent, DebitCreditDetailState> {
  DebitCreditDetailBloc({
    required DebitCreditRepository repository,
    required Repository<Ledger, int> ledgerRepository,
  }) : _repository = repository,
       _ledgerRepo = ledgerRepository,
       super(const DebitCreditDetailState()) {
    on<DebitCreditDetailFetchRequested>(_onFetchRequested);
    on<DebitCreditDetailRefreshed>(_onRefreshed);
    on<DebitCreditDetailCancelled>(_onCancelled);
  }

  final DebitCreditRepository _repository;
  final Repository<Ledger, int> _ledgerRepo;

  Future<void> _onFetchRequested(
    DebitCreditDetailFetchRequested event,
    Emitter<DebitCreditDetailState> emit,
  ) async {
    emit(
      state.copyWith(
        status: DebitCreditDetailStatus.loading,
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
          status: DebitCreditDetailStatus.failure,
          failure: () => failure,
        ),
      ),
      (detail) => emit(
        state.copyWith(status: DebitCreditDetailStatus.success, detail: detail),
      ),
    );
  }

  Future<void> _onRefreshed(
    DebitCreditDetailRefreshed event,
    Emitter<DebitCreditDetailState> emit,
  ) async {
    if (state.detail != null) {
      add(DebitCreditDetailFetchRequested(state.detail!.id));
    }
  }

  Future<void> _onCancelled(
    DebitCreditDetailCancelled event,
    Emitter<DebitCreditDetailState> emit,
  ) async {
    if (state.detail == null) return;
    emit(state.copyWith(isBusy: true, actionMessage: () => null));

    final result = await _repository.cancel(state.detail!.id);
    result.fold(
      (failure) => emit(
        state.copyWith(isBusy: false, actionMessage: () => _messageOf(failure)),
      ),
      (_) {
        emit(state.copyWith(isBusy: false, actionMessage: () => 'Cancelled'));
        add(DebitCreditDetailFetchRequested(state.detail!.id));
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
