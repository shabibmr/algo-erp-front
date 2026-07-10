import 'package:equatable/equatable.dart';

/// Sort direction for a list query.
enum SortDirection { asc, desc }

/// A single column sort request: `sortBy=<field>&sortDir=<asc|desc>`.
class SortSpec extends Equatable {
  const SortSpec(this.field, [this.direction = SortDirection.asc]);

  final String field;
  final SortDirection direction;

  @override
  List<Object?> get props => [field, direction];
}

/// The one query shape every list endpoint speaks: pagination plus optional
/// search, per-field filters, and a sort.
///
/// Kept as a pure, immutable value object — it does **not** know how to turn
/// itself into HTTP query parameters (that belongs to the data-source layer).
/// This keeps the domain free of transport concerns and lets an offline layer
/// reuse the exact same query shape later.
///
/// NOTE: the backend today honours only [page]/[limit] (see
/// `docs/backend-suggestions.md` BE-002/003/004). [search]/[filters]/[sort]
/// are carried now so features are written once; server support becomes a
/// one-line change in the data source, with no bloc/UI edits.
class PageQuery extends Equatable {
  const PageQuery({
    this.page = 1,
    this.limit = 20,
    this.search,
    this.filters = const {},
    this.sort,
  });

  final int page;
  final int limit;

  /// Free-text search term, matched server-side against the entity's natural
  /// display field(s) once BE-002 lands.
  final String? search;

  /// Whitelisted field → value filters (e.g. `{'status': 'posted'}`).
  final Map<String, Object?> filters;

  final SortSpec? sort;

  PageQuery copyWith({
    int? page,
    int? limit,
    String? search,
    Map<String, Object?>? filters,
    SortSpec? sort,
  }) {
    return PageQuery(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      search: search ?? this.search,
      filters: filters ?? this.filters,
      sort: sort ?? this.sort,
    );
  }

  /// The same query pointing at the next page — used by load-more.
  PageQuery nextPage() => copyWith(page: page + 1);

  /// Reset to the first page, keeping search/filters/sort — used when a filter
  /// or search term changes.
  PageQuery firstPage() => copyWith(page: 1);

  @override
  List<Object?> get props => [page, limit, search, filters, sort];
}
