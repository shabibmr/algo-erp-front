import 'package:algo_erp_front/core/vouchers/stock/stock_voucher_kind.dart';
import 'package:algo_erp_front/core/vouchers/stock/stock_voucher_repository.dart';
import 'package:algo_erp_front/features/transactions_stock/bloc/stock_voucher_list_event.dart';
import 'package:algo_erp_front/features/transactions_stock/bloc/stock_voucher_list_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StockVoucherListBloc
    extends Bloc<StockVoucherListEvent, StockVoucherListState> {
  StockVoucherListBloc({
    required StockVoucherRepository repository,
    required StockVoucherKind kind,
  }) : _repository = repository,
       super(StockVoucherListState(kind: kind)) {
    on<StockVoucherListFetchRequested>(_onFetchRequested);
    on<StockVoucherListRefreshed>(_onRefreshed);
    on<StockVoucherListFilterToggled>(_onFilterToggled);
    on<StockVoucherListStartDateChanged>(_onStartDateChanged);
    on<StockVoucherListEndDateChanged>(_onEndDateChanged);
    on<StockVoucherListStatusChanged>(_onStatusChanged);
    on<StockVoucherListPrefixChanged>(_onPrefixChanged);
    on<StockVoucherListSearchChanged>(_onSearchChanged);
    on<StockVoucherListFiltersCleared>(_onFiltersCleared);
  }

  final StockVoucherRepository _repository;

  Future<void> _onFetchRequested(
    StockVoucherListFetchRequested event,
    Emitter<StockVoucherListState> emit,
  ) async {
    emit(state.copyWith(status: StockVoucherListStatus.loading));
    await _loadData(emit);
  }

  Future<void> _onRefreshed(
    StockVoucherListRefreshed event,
    Emitter<StockVoucherListState> emit,
  ) async {
    await _loadData(emit);
  }

  void _onFilterToggled(
    StockVoucherListFilterToggled event,
    Emitter<StockVoucherListState> emit,
  ) {
    emit(state.copyWith(filtersExpanded: !state.filtersExpanded));
  }

  Future<void> _onStartDateChanged(
    StockVoucherListStartDateChanged event,
    Emitter<StockVoucherListState> emit,
  ) async {
    emit(
      state.copyWith(
        startDate: () => event.startDate,
        status: StockVoucherListStatus.loading,
      ),
    );
    await _loadData(emit);
  }

  Future<void> _onEndDateChanged(
    StockVoucherListEndDateChanged event,
    Emitter<StockVoucherListState> emit,
  ) async {
    emit(
      state.copyWith(
        endDate: () => event.endDate,
        status: StockVoucherListStatus.loading,
      ),
    );
    await _loadData(emit);
  }

  Future<void> _onStatusChanged(
    StockVoucherListStatusChanged event,
    Emitter<StockVoucherListState> emit,
  ) async {
    emit(
      state.copyWith(
        selectedStatus: () => event.status,
        status: StockVoucherListStatus.loading,
      ),
    );
    await _loadData(emit);
  }

  Future<void> _onPrefixChanged(
    StockVoucherListPrefixChanged event,
    Emitter<StockVoucherListState> emit,
  ) async {
    emit(
      state.copyWith(
        prefix: event.prefix,
        status: StockVoucherListStatus.loading,
      ),
    );
    await _loadData(emit);
  }

  Future<void> _onSearchChanged(
    StockVoucherListSearchChanged event,
    Emitter<StockVoucherListState> emit,
  ) async {
    emit(
      state.copyWith(
        search: event.search,
        status: StockVoucherListStatus.loading,
      ),
    );
    await _loadData(emit);
  }

  Future<void> _onFiltersCleared(
    StockVoucherListFiltersCleared event,
    Emitter<StockVoucherListState> emit,
  ) async {
    emit(
      state.copyWith(
        startDate: () => null,
        endDate: () => null,
        selectedStatus: () => null,
        prefix: '',
        search: '',
        status: StockVoucherListStatus.loading,
      ),
    );
    await _loadData(emit);
  }

  Future<void> _loadData(Emitter<StockVoucherListState> emit) async {
    final result = await _repository.list(state.query);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: StockVoucherListStatus.failure,
          failure: failure,
        ),
      ),
      (page) => emit(
        state.copyWith(
          status: StockVoucherListStatus.success,
          items: page.items,
        ),
      ),
    );
  }
}
