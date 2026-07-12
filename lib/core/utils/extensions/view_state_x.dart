import 'package:algo_erp_front/core/bloc/crud_contract.dart';
import 'package:algo_erp_front/core/bloc/detail_bloc.dart';
import 'package:algo_erp_front/core/widgets/view_state.dart';

/// Bridges bloc states to the bloc-agnostic [ViewState] that `AsyncStateView`
/// renders — so the same skeleton/empty/error UI serves list and detail screens
/// alike. The `switch`es are exhaustive over the sealed states (R3): add a new
/// state and these stop compiling until handled.
extension CrudStateViewX<E> on CrudState<E> {
  ViewState<List<E>> toViewState() => switch (this) {
    CrudInitial<E>() || CrudLoading<E>() => ViewLoading<List<E>>(),
    final CrudLoaded<E> s =>
      s.items.isEmpty ? ViewEmpty<List<E>>() : ViewData(s.items),
    final CrudError<E> s => ViewError<List<E>>(s.failure),
  };
}

extension DetailStateViewX<E> on DetailState<E> {
  ViewState<E> toViewState() => switch (this) {
    DetailInitial<E>() ||
    DetailLoading<E>() ||
    DetailDeleted<E>() => ViewLoading<E>(),
    final DetailLoaded<E> s => ViewData(s.entity),
    final DetailError<E> s => ViewError<E>(s.failure),
  };
}
