import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/safe_call.dart';

/// Loader builders for `FkLookupField.loader` — collapse the `Result → list`
/// fold every picker otherwise hand-rolls.
///
/// A `FkLookupField<T>` wants a `Future<List<T>> Function(String query)`. Both
/// of the app's search shapes fold a `Result` down to a plain list, returning
/// an empty list on `Failure` (the picker shows "no matches" rather than
/// surfacing a transport error mid-typeahead). These two helpers name that
/// pattern once instead of repeating it at ~60 call sites.

/// Loader backed by a paginated list endpoint — the `Repository.list` contract
/// every master implements. Passes the search string as `PageQuery.search`.
///
/// ```dart
/// FkLookupField<Ledger>(loader: pagedLookup(_ledgerRepo), ...)
/// ```
Future<List<E>> Function(String) pagedLookup<E, ID>(Repository<E, ID> repo) =>
    (q) async => (await repo.list(
      PageQuery(search: q),
    )).fold((_) => const [], (page) => page.items);

/// Loader backed by a lightweight search returning `Result<List<T>>` (e.g. the
/// `searchProjects` / `searchEmployees` helpers on feature repositories).
///
/// ```dart
/// FkLookupField<ProjectLite>(loader: searchLookup(repo.searchProjects), ...)
/// ```
Future<List<T>> Function(String) searchLookup<T>(
  Future<Result<List<T>>> Function(String) search,
) =>
    (q) async => (await search(q)).fold((_) => const [], (list) => list);
