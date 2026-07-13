import 'package:algo_erp_front/core/vouchers/ledger_amount/ledger_amount_kind.dart';
import 'package:algo_erp_front/core/vouchers/ledger_amount/ledger_amount_repository.dart';
import 'package:algo_erp_front/features/transactions_ledger_amount/bloc/ledger_amount_list_event.dart';
import 'package:algo_erp_front/features/transactions_ledger_amount/bloc/ledger_amount_list_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LedgerAmountListBloc
    extends Bloc<LedgerAmountListEvent, LedgerAmountListState> {
  LedgerAmountListBloc({
    required LedgerAmountRepository repository,
    required LedgerAmountVoucherKind kind,
  }) : _repository = repository,
       super(LedgerAmountListState(kind: kind)) {
    on<LedgerAmountListFetchRequested>(_onFetchRequested);
    on<LedgerAmountListRefreshed>(_onRefreshed);
    on<LedgerAmountListFilterToggled>(_onFilterToggled);
    on<LedgerAmountListStartDateChanged>(_onStartDateChanged);
    on<LedgerAmountListEndDateChanged>(_onEndDateChanged);
    on<LedgerAmountListStatusChanged>(_onStatusChanged);
    on<LedgerAmountListPrefixChanged>(_onPrefixChanged);
    on<LedgerAmountListSearchChanged>(_onSearchChanged);
    on<LedgerAmountListFiltersCleared>(_onFiltersCleared);
  }

  final LedgerAmountRepository _repository;

  Future<void> _onFetchRequested(
    LedgerAmountListFetchRequested event,
    Emitter<LedgerAmountListState> emit,
  ) async {
    emit(state.copyWith(status: LedgerAmountListStatus.loading));
    await _loadData(emit);
  }

  Future<void> _onRefreshed(
    LedgerAmountListRefreshed event,
    Emitter<LedgerAmountListState> emit,
  ) async {
    await _loadData(emit);
  }

  void _onFilterToggled(
    LedgerAmountListFilterToggled event,
    Emitter<LedgerAmountListState> emit,
  ) {
    emit(state.copyWith(filtersExpanded: !state.filtersExpanded));
  }

  Future<void> _onStartDateChanged(
    LedgerAmountListStartDateChanged event,
    Emitter<LedgerAmountListState> emit,
  ) async {
    emit(
      state.copyWith(
        startDate: () => event.startDate,
        status: LedgerAmountListStatus.loading,
      ),
    );
    await _loadData(emit);
  }

  Future<void> _onEndDateChanged(
    LedgerAmountListEndDateChanged event,
    Emitter<LedgerAmountListState> emit,
  ) async {
    emit(
      state.copyWith(
        endDate: () => event.endDate,
        status: LedgerAmountListStatus.loading,
      ),
    );
    await _loadData(emit);
  }

  Future<void> _onStatusChanged(
    LedgerAmountListStatusChanged event,
    Emitter<LedgerAmountListState> emit,
  ) async {
    emit(
      state.copyWith(
        selectedStatus: () => event.status,
        status: LedgerAmountListStatus.loading,
      ),
    );
    await _loadData(emit);
  }

  Future<void> _onPrefixChanged(
    LedgerAmountListPrefixChanged event,
    Emitter<LedgerAmountListState> emit,
  ) async {
    emit(
      state.copyWith(
        prefix: event.prefix,
        status: LedgerAmountListStatus.loading,
      ),
    );
    await _loadData(emit);
  }

  Future<void> _onSearchChanged(
    LedgerAmountListSearchChanged event,
    Emitter<LedgerAmountListState> emit,
  ) async {
    emit(
      state.copyWith(
        search: event.search,
        status: LedgerAmountListStatus.loading,
      ),
    );
    await _loadData(emit);
  }

  Future<void> _onFiltersCleared(
    LedgerAmountListFiltersCleared event,
    Emitter<LedgerAmountListState> emit,
  ) async {
    emit(
      state.copyWith(
        startDate: () => null,
        endDate: () => null,
        selectedStatus: () => null,
        prefix: '',
        search: '',
        status: LedgerAmountListStatus.loading,
      ),
    );
    await _loadData(emit);
  }

  Future<void> _loadData(Emitter<LedgerAmountListState> emit) async {
    final result = await _repository.list(state.query);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: LedgerAmountListStatus.failure,
          failure: failure,
        ),
      ),
      (page) => emit(
        state.copyWith(
          status: LedgerAmountListStatus.success,
          items: page.items,
        ),
      ),
    );
  }
}
