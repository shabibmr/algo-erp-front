// Private fields fed by public named params cannot use initializing formals.
// ignore_for_file: prefer_initializing_formals

import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

/// Sealed state for a single-entity detail view.
sealed class DetailState<E> extends Equatable {
  const DetailState();

  @override
  List<Object?> get props => [];
}

final class DetailInitial<E> extends DetailState<E> {
  const DetailInitial();
}

final class DetailLoading<E> extends DetailState<E> {
  const DetailLoading();
}

final class DetailLoaded<E> extends DetailState<E> {
  const DetailLoaded(this.entity);

  final E entity;

  @override
  List<Object?> get props => [entity];
}

/// Emitted after a successful delete so the page can pop / navigate away.
final class DetailDeleted<E> extends DetailState<E> {
  const DetailDeleted();
}

final class DetailError<E> extends DetailState<E> {
  const DetailError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

sealed class DetailEvent extends Equatable {
  const DetailEvent();

  @override
  List<Object?> get props => [];
}

final class DetailLoadRequested extends DetailEvent {
  const DetailLoadRequested();
}

final class DetailRefreshRequested extends DetailEvent {
  const DetailRefreshRequested();
}

final class DetailDeleteRequested extends DetailEvent {
  const DetailDeleteRequested();
}

/// Generic single-entity loader/deleter. Bound to one `id` at construction;
/// reused for every detail screen with zero per-entity code.
class DetailBloc<E, ID> extends Bloc<DetailEvent, DetailState<E>> {
  DetailBloc({required Repository<E, ID> repository, required ID id})
      : _repo = repository,
        _id = id,
        super(const DetailInitial()) {
    on<DetailLoadRequested>(_onLoad);
    on<DetailRefreshRequested>(_onLoad);
    on<DetailDeleteRequested>(_onDelete);
  }

  final Repository<E, ID> _repo;
  final ID _id;

  Future<void> _onLoad(DetailEvent event, Emitter<DetailState<E>> emit) async {
    emit(DetailLoading<E>());
    final result = await _repo.getById(_id);
    result.fold(
      (failure) => emit(DetailError<E>(failure)),
      (entity) => emit(DetailLoaded<E>(entity)),
    );
  }

  Future<void> _onDelete(
    DetailDeleteRequested event,
    Emitter<DetailState<E>> emit,
  ) async {
    final result = await _repo.delete(_id);
    result.fold(
      (failure) => emit(DetailError<E>(failure)),
      (_) => emit(DetailDeleted<E>()),
    );
  }
}
