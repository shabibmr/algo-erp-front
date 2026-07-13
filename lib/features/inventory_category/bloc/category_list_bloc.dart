import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/inventory_category/bloc/category_list_event.dart';
import 'package:algo_erp_front/features/inventory_category/bloc/category_list_state.dart';
import 'package:algo_erp_front/features/inventory_category/domain/category.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoryListBloc extends Bloc<CategoryListEvent, CategoryListState> {
  CategoryListBloc({required Repository<Category, int> repository})
    : _repository = repository,
      super(const CategoryListState()) {
    on<CategoryListFetchRequested>(_onFetchRequested);
    on<CategoryListRefreshed>(_onRefreshed);
    on<CategoryListSearchChanged>(_onSearchChanged);
    on<CategoryItemDeleted>(_onItemDeleted);
  }

  final Repository<Category, int> _repository;

  Future<void> _onFetchRequested(
    CategoryListFetchRequested event,
    Emitter<CategoryListState> emit,
  ) async {
    emit(
      state.copyWith(
        status: CategoryListStatus.loading,
        actionMessage: () => null,
      ),
    );
    await _loadData(emit);
  }

  Future<void> _onRefreshed(
    CategoryListRefreshed event,
    Emitter<CategoryListState> emit,
  ) async {
    await _loadData(emit);
  }

  Future<void> _onSearchChanged(
    CategoryListSearchChanged event,
    Emitter<CategoryListState> emit,
  ) async {
    emit(
      state.copyWith(search: event.search, status: CategoryListStatus.loading),
    );
    await _loadData(emit);
  }

  Future<void> _onItemDeleted(
    CategoryItemDeleted event,
    Emitter<CategoryListState> emit,
  ) async {
    final result = await _repository.delete(event.id);
    result.fold(
      (failure) =>
          emit(state.copyWith(actionMessage: () => _messageOf(failure))),
      (_) {
        emit(
          state.copyWith(actionMessage: () => 'Category deleted successfully'),
        );
        add(const CategoryListFetchRequested());
      },
    );
  }

  Future<void> _loadData(Emitter<CategoryListState> emit) async {
    final result = await _repository.list(state.query);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: CategoryListStatus.failure,
          failure: () => failure,
        ),
      ),
      (page) => emit(
        state.copyWith(status: CategoryListStatus.success, items: page.items),
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
