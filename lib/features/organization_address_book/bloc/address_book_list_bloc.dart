import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/organization_address_book/bloc/address_book_list_event.dart';
import 'package:algo_erp_front/features/organization_address_book/bloc/address_book_list_state.dart';
import 'package:algo_erp_front/features/organization_address_book/domain/address_book.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddressBookListBloc
    extends Bloc<AddressBookListEvent, AddressBookListState> {
  AddressBookListBloc({required Repository<AddressBook, int> repository})
    : _repository = repository,
      super(const AddressBookListState()) {
    on<AddressBookListFetchRequested>(_onFetchRequested);
    on<AddressBookListRefreshed>(_onRefreshed);
    on<AddressBookListSearchChanged>(_onSearchChanged);
    on<AddressBookItemDeleted>(_onItemDeleted);
  }

  final Repository<AddressBook, int> _repository;

  Future<void> _onFetchRequested(
    AddressBookListFetchRequested event,
    Emitter<AddressBookListState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AddressBookListStatus.loading,
        actionMessage: () => null,
      ),
    );
    await _loadData(emit);
  }

  Future<void> _onRefreshed(
    AddressBookListRefreshed event,
    Emitter<AddressBookListState> emit,
  ) async {
    await _loadData(emit);
  }

  Future<void> _onSearchChanged(
    AddressBookListSearchChanged event,
    Emitter<AddressBookListState> emit,
  ) async {
    emit(
      state.copyWith(
        search: event.search,
        status: AddressBookListStatus.loading,
      ),
    );
    await _loadData(emit);
  }

  Future<void> _onItemDeleted(
    AddressBookItemDeleted event,
    Emitter<AddressBookListState> emit,
  ) async {
    final result = await _repository.delete(event.id);
    result.fold(
      (failure) =>
          emit(state.copyWith(actionMessage: () => _messageOf(failure))),
      (_) {
        emit(
          state.copyWith(actionMessage: () => 'Contact deleted successfully'),
        );
        add(const AddressBookListFetchRequested());
      },
    );
  }

  Future<void> _loadData(Emitter<AddressBookListState> emit) async {
    final result = await _repository.list(state.query);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AddressBookListStatus.failure,
          failure: () => failure,
        ),
      ),
      (page) => emit(
        state.copyWith(
          status: AddressBookListStatus.success,
          items: page.items,
        ),
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
