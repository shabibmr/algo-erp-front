import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/network/paginated.dart';
import 'package:equatable/equatable.dart';

/// ─────────────────────────── STATES ───────────────────────────
///
/// The sealed state of a paginated CRUD list. Because it is `sealed`, a
/// `switch` over it in the UI is exhaustive — the compiler refuses to let a
/// screen forget the loading, empty, or error branch (R3). Every list screen
/// in the app renders one of these four cases and nothing else.
sealed class CrudState<E> extends Equatable {
  const CrudState();

  @override
  List<Object?> get props => [];
}

/// Nothing requested yet.
final class CrudInitial<E> extends CrudState<E> {
  const CrudInitial();
}

/// First load in flight, no data to show yet (render a skeleton).
final class CrudLoading<E> extends CrudState<E> {
  const CrudLoading();
}

/// A page of data is loaded. [isLoadingMore]/[isRefreshing] let the UI show a
/// bottom spinner or pull-to-refresh indicator without leaving this state, so
/// the list never flickers back to a skeleton.
final class CrudLoaded<E> extends CrudState<E> {
  const CrudLoaded({
    required this.items,
    required this.meta,
    this.isLoadingMore = false,
    this.isRefreshing = false,
  });

  final List<E> items;
  final PaginationMeta meta;
  final bool isLoadingMore;
  final bool isRefreshing;

  bool get hasMore => meta.hasMore;
  bool get isEmpty => items.isEmpty;

  CrudLoaded<E> copyWith({
    List<E>? items,
    PaginationMeta? meta,
    bool? isLoadingMore,
    bool? isRefreshing,
  }) {
    return CrudLoaded<E>(
      items: items ?? this.items,
      meta: meta ?? this.meta,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [items, meta, isLoadingMore, isRefreshing];
}

/// The load failed with no data to fall back on. [failure] drives the
/// error view + retry (mapped from the sealed [Failure] hierarchy).
final class CrudError<E> extends CrudState<E> {
  const CrudError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

/// ─────────────────────────── EVENTS ───────────────────────────
///
/// [E] is the entity type; [F] is the feature's filter type (use `void` or a
/// dedicated filter class). Item mutations carry the whole entity so no
/// separate id-typed event is needed — the bloc extracts the id via the
/// feature-supplied id selector.
sealed class CrudEvent<E, F> extends Equatable {
  const CrudEvent();

  @override
  List<Object?> get props => [];
}

/// (Re)load from the first page, discarding any current data.
final class CrudLoadRequested<E, F> extends CrudEvent<E, F> {
  const CrudLoadRequested();
}

/// Pull-to-refresh: reload page one but keep showing current data meanwhile.
final class CrudRefreshRequested<E, F> extends CrudEvent<E, F> {
  const CrudRefreshRequested();
}

/// Append the next page (infinite scroll).
final class CrudLoadMoreRequested<E, F> extends CrudEvent<E, F> {
  const CrudLoadMoreRequested();
}

/// Search term changed; debounced by the bloc, resets to page one.
final class CrudSearchChanged<E, F> extends CrudEvent<E, F> {
  const CrudSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

/// Filter changed; resets to page one.
final class CrudFilterChanged<E, F> extends CrudEvent<E, F> {
  const CrudFilterChanged(this.filter);

  final F? filter;

  @override
  List<Object?> get props => [filter];
}

/// Persist a newly created entity, then reflect it in the list.
final class CrudItemCreated<E, F> extends CrudEvent<E, F> {
  const CrudItemCreated(this.item);

  final E item;

  @override
  List<Object?> get props => [item];
}

/// Persist an update to an existing entity.
final class CrudItemUpdated<E, F> extends CrudEvent<E, F> {
  const CrudItemUpdated(this.item);

  final E item;

  @override
  List<Object?> get props => [item];
}

/// Delete an entity.
final class CrudItemDeleted<E, F> extends CrudEvent<E, F> {
  const CrudItemDeleted(this.item);

  final E item;

  @override
  List<Object?> get props => [item];
}
