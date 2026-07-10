import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/error/safe_call.dart';
import 'package:algo_erp_front/core/network/paginated.dart';
import 'package:fpdart/fpdart.dart';

/// The canonical CRUD contract every feature depends on — and the single most
/// important interface in the app.
///
/// Features (blocs, use cases) know only this type. The current online
/// implementation (`RemoteRepository`, Track A) talks straight to the API; a
/// future offline/cached implementation is just a different class behind the
/// *same* interface. Nothing that consumes a `Repository` has to change when
/// that swap happens — that is the whole point of shipping online-first
/// without painting ourselves into a corner.
///
/// - [E]  the domain entity (clean, UI-friendly — never a wire DTO).
/// - [ID] the identifier type (`int` for this backend's integer PKs).
///
/// Every method returns `Result<T>` (`Either<Failure, T>`) and never throws;
/// transport errors are already mapped to `Failure` by the implementation.
abstract interface class Repository<E, ID> {
  /// A page of entities matching [query].
  Future<Result<Paginated<E>>> list(PageQuery query);

  /// A single entity by id, or a `Failure.notFound` on the left.
  Future<Result<E>> getById(ID id);

  /// Creates [entity]; returns the server's canonical version (with its id).
  Future<Result<E>> create(E entity);

  /// Updates the entity identified by [id]; returns the server's version.
  Future<Result<E>> update(ID id, E entity);

  /// Deletes (soft- or hard-, per the entity) the record identified by [id].
  Future<Result<Unit>> delete(ID id);
}
