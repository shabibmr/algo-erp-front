import 'package:algo_erp_front/core/data/remote_data_source.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/safe_call.dart';
import 'package:algo_erp_front/core/network/paginated.dart';
import 'package:fpdart/fpdart.dart';

// Private fields fed by public named params cannot use initializing formals.
// ignore_for_file: prefer_initializing_formals

/// The online implementation of [Repository] — written **once**, reused by
/// every entity.
///
/// It composes three feature-supplied closures over the generic
/// [RemoteDataSource], so it stays entity-agnostic and needs no DTO type
/// parameter:
/// - `decode` : `JsonMap → E` (usually `Dto.fromJson` then `mapper.toEntity`)
/// - `encode` : `E → JsonMap` (usually `mapper.toDto` then `dto.toJson`)
/// - `idOf`   : `E → ID` (extract the primary key for get/update/delete)
///
/// Every method funnels its network call through `safeCall`, so callers get a
/// `Result<T>` and never see a raw exception. When an offline layer arrives,
/// it implements the same [Repository] interface — this class is not touched.
class RemoteRepository<E, ID> implements Repository<E, ID> {
  RemoteRepository({
    required RemoteDataSource dataSource,
    required E Function(JsonMap json) decode,
    required JsonMap Function(E entity) encode,
    required ID Function(E entity) idOf,
  }) : _dataSource = dataSource,
       _decode = decode,
       _encode = encode,
       _idOf = idOf;

  final RemoteDataSource _dataSource;
  final E Function(JsonMap json) _decode;
  final JsonMap Function(E entity) _encode;
  final ID Function(E entity) _idOf;

  @override
  Future<Result<Paginated<E>>> list(PageQuery query) {
    return safeCall(() async {
      final page = await _dataSource.list(query);
      return Paginated<E>(
        items: page.items.map(_decode).toList(growable: false),
        meta: page.meta,
      );
    });
  }

  @override
  Future<Result<E>> getById(ID id) {
    return safeCall(() async {
      final json = await _dataSource.getById(id as Object);
      return _decode(json);
    });
  }

  @override
  Future<Result<E>> create(E entity) {
    return safeCall(() async {
      final json = await _dataSource.create(_encode(entity));
      return _decode(json);
    });
  }

  @override
  Future<Result<E>> update(ID id, E entity) {
    return safeCall(() async {
      final json = await _dataSource.update(id as Object, _encode(entity));
      return _decode(json);
    });
  }

  @override
  Future<Result<Unit>> delete(ID id) {
    return safeCall(() async {
      await _dataSource.delete(id as Object);
      return unit;
    });
  }

  /// The primary key of [entity] — handy for callers that hold an entity but
  /// need its id (e.g. a `CrudBloc` deleting the selected row).
  ID idOf(E entity) => _idOf(entity);
}
