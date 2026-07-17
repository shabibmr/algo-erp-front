// Private fields fed by public named params cannot use initializing formals.
// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:algo_erp_front/core/bloc/crud_contract.dart';
import 'package:algo_erp_front/core/bloc/mixins/pagination.dart';
import 'package:algo_erp_front/core/bloc/mixins/search_debounce.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:bloc/bloc.dart';

/// Turns any `F` filter object into the `PageQuery.filters` map.
typedef FilterBuilder<F> = Map<String, Object?> Function(F? filter);

/// The generic list engine reused by **every** list screen in the app.
///
/// One class handles load / refresh / infinite-scroll / debounced search /
/// filter / create / update / delete against any [Repository]. Features add
/// **no** bloc code — they instantiate `CrudBloc<Brand, int, void>` (or wrap it
/// for DI) and supply an `idOf` selector. That is the "one generic where you'd
/// write forty" principle in the flesh.
///
/// Reads drive the sealed [CrudState]. Mutations update the loaded list **in
/// place** (insert/replace/remove) with no redundant reload, and report any
/// failure on [mutationFailures] — a side-effect stream — so the list state is
/// never blown away by a failed row action.
///
/// - [E]  entity · [ID] id type · [F] filter type (use `void` if none).
class CrudBloc<E, ID, F> extends Bloc<CrudEvent<E, F>, CrudState<E>> {
  CrudBloc({
    required Repository<E, ID> repository,
    required ID Function(E entity) idOf,
    int pageSize = 20,
    Duration searchDebounce = kSearchDebounce,
    FilterBuilder<F>? filterBuilder,
  }) : _repo = repository,
       _idOf = idOf,
       _filterBuilder = filterBuilder,
       super(const CrudInitial()) {
    _query = PageQuery(limit: pageSize);
    on<CrudLoadRequested<E, F>>(_onLoad);
    on<CrudRefreshRequested<E, F>>(_onRefresh);
    on<CrudLoadMoreRequested<E, F>>(_onLoadMore);
    on<CrudSearchChanged<E, F>>(
      _onSearch,
      transformer: debounceRestartable(searchDebounce),
    );
    on<CrudFilterChanged<E, F>>(_onFilter);
    on<CrudItemCreated<E, F>>(_onCreate);
    on<CrudItemUpdated<E, F>>(_onUpdate);
    on<CrudItemDeleted<E, F>>(_onDelete);
  }

  final Repository<E, ID> _repo;
  final ID Function(E entity) _idOf;

  /// The repository this bloc reads through. Exposed so export can walk the
  /// same source with the same [query] without a second binding being wired up
  /// alongside the one the list already owns.
  Repository<E, ID> get repository => _repo;
  final FilterBuilder<F>? _filterBuilder;

  late PageQuery _query;

  /// The search, filters and sort currently narrowing the list.
  ///
  /// Exposed read-only for export, which has to re-run *this* query against the
  /// server to gather every matching row — the state carries only the pages
  /// scrolled into view, and a file built from those is a silently partial one.
  PageQuery get query => _query;

  final _failures = StreamController<Failure>.broadcast();

  /// Failures from create/update/delete surface here (e.g. for a snackbar),
  /// leaving the visible list intact.
  Stream<Failure> get mutationFailures => _failures.stream;

  // ── Reads ──────────────────────────────────────────────────────────

  Future<void> _onLoad(
    CrudLoadRequested<E, F> event,
    Emitter<CrudState<E>> emit,
  ) => _fetchFirstPage(emit);

  Future<void> _onRefresh(
    CrudRefreshRequested<E, F> event,
    Emitter<CrudState<E>> emit,
  ) => _fetchFirstPage(emit, refreshing: true);

  Future<void> _onSearch(
    CrudSearchChanged<E, F> event,
    Emitter<CrudState<E>> emit,
  ) {
    _query = _query.copyWith(search: event.query).firstPage();
    return _fetchFirstPage(emit);
  }

  Future<void> _onFilter(
    CrudFilterChanged<E, F> event,
    Emitter<CrudState<E>> emit,
  ) {
    final filters = _filterBuilder?.call(event.filter) ?? const {};
    _query = _query.copyWith(filters: filters).firstPage();
    return _fetchFirstPage(emit);
  }

  Future<void> _fetchFirstPage(
    Emitter<CrudState<E>> emit, {
    bool refreshing = false,
  }) async {
    _query = _query.firstPage();
    final current = state;
    if (refreshing && current is CrudLoaded<E>) {
      emit(current.copyWith(isRefreshing: true));
    } else {
      emit(CrudLoading<E>());
    }
    final result = await _repo.list(_query);
    result.fold(
      (failure) => emit(CrudError<E>(failure)),
      (page) => emit(CrudLoaded<E>(items: page.items, meta: page.meta)),
    );
  }

  Future<void> _onLoadMore(
    CrudLoadMoreRequested<E, F> event,
    Emitter<CrudState<E>> emit,
  ) async {
    final current = state;
    if (current is! CrudLoaded<E> ||
        !current.hasMore ||
        current.isLoadingMore) {
      return;
    }
    emit(current.copyWith(isLoadingMore: true));
    _query = _query.nextPage();
    final result = await _repo.list(_query);
    result.fold(
      (failure) {
        _failures.add(failure);
        _query = _query.copyWith(page: current.meta.page);
        emit(current.copyWith(isLoadingMore: false));
      },
      (page) => emit(
        CrudLoaded<E>(
          items: [...current.items, ...page.items],
          meta: page.meta,
        ),
      ),
    );
  }

  // ── Mutations (optimistic, list-preserving) ────────────────────────

  Future<void> _onCreate(
    CrudItemCreated<E, F> event,
    Emitter<CrudState<E>> emit,
  ) async {
    final result = await _repo.create(event.item);
    result.fold(_failures.add, (created) {
      final current = state;
      if (current is CrudLoaded<E>) {
        emit(
          current.copyWith(
            items: [created, ...current.items],
            meta: current.meta.withOneMore(),
          ),
        );
      } else {
        add(const CrudLoadRequested());
      }
    });
  }

  Future<void> _onUpdate(
    CrudItemUpdated<E, F> event,
    Emitter<CrudState<E>> emit,
  ) async {
    final result = await _repo.update(_idOf(event.item), event.item);
    result.fold(_failures.add, (updated) {
      final current = state;
      if (current is CrudLoaded<E>) {
        final items = current.items
            .map((e) => _idOf(e) == _idOf(updated) ? updated : e)
            .toList(growable: false);
        emit(current.copyWith(items: items));
      }
    });
  }

  Future<void> _onDelete(
    CrudItemDeleted<E, F> event,
    Emitter<CrudState<E>> emit,
  ) async {
    final current = state;
    // Optimistically remove so the row disappears instantly.
    if (current is CrudLoaded<E>) {
      final remaining = current.items
          .where((e) => _idOf(e) != _idOf(event.item))
          .toList(growable: false);
      emit(
        current.copyWith(items: remaining, meta: current.meta.withOneFewer()),
      );
    }
    final result = await _repo.delete(_idOf(event.item));
    result.fold((failure) {
      _failures.add(failure);
      // Roll back to server truth.
      if (state is CrudLoaded<E>) add(const CrudRefreshRequested());
    }, (_) {});
  }

  @override
  Future<void> close() {
    _failures.close();
    return super.close();
  }
}
