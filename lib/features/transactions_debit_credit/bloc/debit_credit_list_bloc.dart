import 'package:algo_erp_front/core/vouchers/debit_credit/debit_credit_kind.dart';
import 'package:algo_erp_front/core/vouchers/debit_credit/debit_credit_repository.dart';
import 'package:algo_erp_front/features/transactions_debit_credit/bloc/debit_credit_list_event.dart';
import 'package:algo_erp_front/features/transactions_debit_credit/bloc/debit_credit_list_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DebitCreditListBloc
    extends Bloc<DebitCreditListEvent, DebitCreditListState> {
  DebitCreditListBloc({
    required DebitCreditRepository repository,
    required DebitCreditVoucherKind kind,
  }) : _repository = repository,
       super(DebitCreditListState(kind: kind)) {
    on<DebitCreditListFetchRequested>(_onFetchRequested);
    on<DebitCreditListRefreshed>(_onRefreshed);
    on<DebitCreditListFilterToggled>(_onFilterToggled);
    on<DebitCreditListStartDateChanged>(_onStartDateChanged);
    on<DebitCreditListEndDateChanged>(_onEndDateChanged);
    on<DebitCreditListStatusChanged>(_onStatusChanged);
    on<DebitCreditListPrefixChanged>(_onPrefixChanged);
    on<DebitCreditListSearchChanged>(_onSearchChanged);
    on<DebitCreditListFiltersCleared>(_onFiltersCleared);
  }

  final DebitCreditRepository _repository;

  Future<void> _onFetchRequested(
    DebitCreditListFetchRequested event,
    Emitter<DebitCreditListState> emit,
  ) async {
    emit(state.copyWith(status: DebitCreditListStatus.loading));
    await _loadData(emit);
  }

  Future<void> _onRefreshed(
    DebitCreditListRefreshed event,
    Emitter<DebitCreditListState> emit,
  ) async {
    await _loadData(emit);
  }

  void _onFilterToggled(
    DebitCreditListFilterToggled event,
    Emitter<DebitCreditListState> emit,
  ) {
    emit(state.copyWith(filtersExpanded: !state.filtersExpanded));
  }

  Future<void> _onStartDateChanged(
    DebitCreditListStartDateChanged event,
    Emitter<DebitCreditListState> emit,
  ) async {
    emit(
      state.copyWith(
        startDate: () => event.startDate,
        status: DebitCreditListStatus.loading,
      ),
    );
    await _loadData(emit);
  }

  Future<void> _onEndDateChanged(
    DebitCreditListEndDateChanged event,
    Emitter<DebitCreditListState> emit,
  ) async {
    emit(
      state.copyWith(
        endDate: () => event.endDate,
        status: DebitCreditListStatus.loading,
      ),
    );
    await _loadData(emit);
  }

  Future<void> _onStatusChanged(
    DebitCreditListStatusChanged event,
    Emitter<DebitCreditListState> emit,
  ) async {
    emit(
      state.copyWith(
        selectedStatus: () => event.status,
        status: DebitCreditListStatus.loading,
      ),
    );
    await _loadData(emit);
  }

  Future<void> _onPrefixChanged(
    DebitCreditListPrefixChanged event,
    Emitter<DebitCreditListState> emit,
  ) async {
    emit(
      state.copyWith(
        prefix: event.prefix,
        status: DebitCreditListStatus.loading,
      ),
    );
    await _loadData(emit);
  }

  Future<void> _onSearchChanged(
    DebitCreditListSearchChanged event,
    Emitter<DebitCreditListState> emit,
  ) async {
    emit(
      state.copyWith(
        search: event.search,
        status: DebitCreditListStatus.loading,
      ),
    );
    await _loadData(emit);
  }

  Future<void> _onFiltersCleared(
    DebitCreditListFiltersCleared event,
    Emitter<DebitCreditListState> emit,
  ) async {
    emit(
      state.copyWith(
        startDate: () => null,
        endDate: () => null,
        selectedStatus: () => null,
        prefix: '',
        search: '',
        status: DebitCreditListStatus.loading,
      ),
    );
    await _loadData(emit);
  }

  Future<void> _loadData(Emitter<DebitCreditListState> emit) async {
    final result = await _repository.list(state.query);
    result.fold(
      (failure) => emit(
        state.copyWith(status: DebitCreditListStatus.failure, failure: failure),
      ),
      (page) => emit(
        state.copyWith(
          status: DebitCreditListStatus.success,
          items: page.items,
        ),
      ),
    );
  }
}
