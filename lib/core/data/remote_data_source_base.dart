import 'package:algo_erp_front/core/data/remote_data_source.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/network/api_response.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/network/paginated.dart';

/// The **one** HTTP data source for the whole app.
///
/// Bound to a single REST resource by [resourcePath], it does exactly four
/// things: build query params, call Dio, unwrap the backend envelope, and
/// decode pagination — all in raw [JsonMap]s. It never knows about a specific
/// entity, so it is instantiated (not subclassed) once per resource:
/// ```dart
/// RemoteDataSourceBase(dioClient, '/inventory/brand')
/// ```
/// It throws on failure (a `DioException`); the repository wraps calls in
/// `safeCall` to turn those into `Failure`s.
class RemoteDataSourceBase implements RemoteDataSource {
  RemoteDataSourceBase(this._client, this.resourcePath);

  final DioClient _client;

  @override
  final String resourcePath;

  @override
  Future<Paginated<JsonMap>> list(PageQuery query) async {
    final res = await _client.dio.get<Object?>(
      resourcePath,
      queryParameters: _queryParameters(query),
    );
    final envelope = decodeApiResponse<JsonMap>(res.data, _asJsonMap);
    final data = envelope.data;
    if (data == null) {
      throw const FormatException('Expected a paginated data payload');
    }
    return Paginated<JsonMap>.fromJson(data, _asJsonMap);
  }

  @override
  Future<JsonMap> getById(Object id) async {
    final res = await _client.dio.get<Object?>('$resourcePath/$id');
    return _single(res.data);
  }

  @override
  Future<JsonMap> create(JsonMap body) async {
    final res = await _client.dio.post<Object?>(resourcePath, data: body);
    return _single(res.data);
  }

  @override
  Future<JsonMap> update(Object id, JsonMap body) async {
    final res = await _client.dio.put<Object?>('$resourcePath/$id', data: body);
    return _single(res.data);
  }

  @override
  Future<void> delete(Object id) async {
    await _client.dio.delete<Object?>('$resourcePath/$id');
  }

  /// Unwraps the `{success, data, ...}` envelope and asserts a single object.
  JsonMap _single(Object? raw) {
    final envelope = decodeApiResponse<JsonMap>(raw, _asJsonMap);
    final data = envelope.data;
    if (data == null) {
      throw const FormatException('Expected a data object in the envelope');
    }
    return data;
  }

  /// Serializes [query] to query parameters. Today the backend honours only
  /// `page`/`limit`; the rest are forwarded (and currently ignored) so search,
  /// sort and filters activate with a backend change alone — see
  /// `docs/backend-suggestions.md` (BE-002/003/004).
  Map<String, dynamic> _queryParameters(PageQuery query) {
    final params = <String, dynamic>{'page': query.page, 'limit': query.limit};
    final search = query.search;
    if (search != null && search.isNotEmpty) {
      params['search'] = search;
    }
    final sort = query.sort;
    if (sort != null) {
      params['sortBy'] = sort.field;
      params['sortDir'] = sort.direction.name;
    }
    query.filters.forEach((key, value) {
      if (value != null) params[key] = value;
    });
    return params;
  }

  static JsonMap _asJsonMap(Object? json) => json! as JsonMap;
}
