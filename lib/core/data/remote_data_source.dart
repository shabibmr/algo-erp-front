import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/network/paginated.dart';

/// A decoded JSON object as it arrives from / departs to the API.
typedef JsonMap = Map<String, dynamic>;

/// Transport-level CRUD over a single REST resource, speaking **raw JSON**.
///
/// Deliberately dumb: it does HTTP + envelope unwrapping + pagination decoding
/// and nothing else. It knows nothing about DTOs, entities, or `Failure` — it
/// simply throws on error (a `DioException`), and the repository wraps those
/// calls in `safeCall` to produce `Result`s.
///
/// Because it works in [JsonMap]s rather than typed models, the generic base
/// implementation (Track A) is written exactly **once** and reused by all 86
/// entities: a feature supplies only a resource path plus the DTO's
/// `fromJson`/`toJson`, never a new data-source class.
abstract interface class RemoteDataSource {
  /// The resource path this source is bound to, e.g. `/inventory/brand`.
  String get resourcePath;

  /// GET a page. Serializes [query] to query parameters (today: `page`/`limit`;
  /// `search`/`filters`/`sort` are added when the backend supports them —
  /// see `docs/backend-suggestions.md`).
  Future<Paginated<JsonMap>> list(PageQuery query);

  /// GET one record by id.
  Future<JsonMap> getById(Object id);

  /// POST a new record; returns the created record's JSON.
  Future<JsonMap> create(JsonMap body);

  /// PUT an update to the record with [id]; returns the updated JSON.
  Future<JsonMap> update(Object id, JsonMap body);

  /// DELETE the record with [id].
  Future<void> delete(Object id);
}
