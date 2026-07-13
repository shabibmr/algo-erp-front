import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/inventory_brand/bloc/brand_list_event.dart';
import 'package:algo_erp_front/features/inventory_brand/bloc/brand_list_state.dart';
import 'package:algo_erp_front/features/inventory_brand/domain/brand.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BrandListBloc extends Bloc<BrandListEvent, BrandListState> {
  BrandListBloc({required Repository<Brand, int> repository})
    : _repository = repository,
      super(const BrandListState()) {
    on<BrandListFetchRequested>(_onFetchRequested);
    on<BrandListRefreshed>(_onRefreshed);
    on<BrandListSearchChanged>(_onSearchChanged);
    on<BrandItemDeleted>(_onItemDeleted);
  }

  final Repository<Brand, int> _repository;

  Future<void> _onFetchRequested(
    BrandListFetchRequested event,
    Emitter<BrandListState> emit,
  ) async {
    emit(
      state.copyWith(
        status: BrandListStatus.loading,
        actionMessage: () => null,
      ),
    );
    await _loadData(emit);
  }

  Future<void> _onRefreshed(
    BrandListRefreshed event,
    Emitter<BrandListState> emit,
  ) async {
    await _loadData(emit);
  }

  Future<void> _onSearchChanged(
    BrandListSearchChanged event,
    Emitter<BrandListState> emit,
  ) async {
    emit(state.copyWith(search: event.search, status: BrandListStatus.loading));
    await _loadData(emit);
  }

  Future<void> _onItemDeleted(
    BrandItemDeleted event,
    Emitter<BrandListState> emit,
  ) async {
    final result = await _repository.delete(event.id);
    result.fold(
      (failure) =>
          emit(state.copyWith(actionMessage: () => _messageOf(failure))),
      (_) {
        emit(state.copyWith(actionMessage: () => 'Brand deleted successfully'));
        add(const BrandListFetchRequested());
      },
    );
  }

  Future<void> _loadData(Emitter<BrandListState> emit) async {
    final result = await _repository.list(state.query);
    result.fold(
      (failure) => emit(
        state.copyWith(status: BrandListStatus.failure, failure: () => failure),
      ),
      (page) => emit(
        state.copyWith(status: BrandListStatus.success, items: page.items),
      ),
    );
  }

  String _messageOf(Failure f) => switch (f) {
    NetworkFailure(:final message) => message,
    ValidationFailure(:final message) => message,
    ForbiddenFailure(:final message) => message,
    ServerFailure(:final message) => message,
    _ => f.toString(),
  };
}
