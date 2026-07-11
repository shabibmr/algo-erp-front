import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:algo_erp_front/core/auth/token_storage.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/error/safe_call.dart';
import 'package:algo_erp_front/features/auth/data/auth_remote_data_source.dart';
import 'package:algo_erp_front/features/auth/data/dtos/permission_dto.dart';
import 'package:algo_erp_front/features/auth/domain/auth_repository.dart';
import 'package:algo_erp_front/features/auth/domain/entities/auth_user.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

/// Wraps [AuthRemoteDataSource] in `safeCall` and owns the two things a session
/// consists of: the local token pair, and the role's permission matrix. Both
/// are established on login/`me` and dropped on logout, so everything above
/// this layer sees `Result<AuthUser>`/`Result<Unit>` and is oblivious to
/// tokens and to how RBAC got loaded.
@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remote, this._tokenStorage, this._permissions);

  final AuthRemoteDataSource _remote;
  final TokenStorage _tokenStorage;
  final PermissionMatrixSink _permissions;

  @override
  Future<Result<AuthUser>> login({
    required String username,
    required String password,
  }) async {
    final result = await safeCall(() async {
      final session = await _remote.login(
        username: username,
        password: password,
      );
      // The matrix fetch below goes through the authenticated interceptor, so
      // the tokens have to be in storage before it runs.
      await _tokenStorage.saveTokens(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
      // `login` returns the user but not the matrix, so read it separately.
      // Treating a failure here as a login failure is deliberate: a session
      // without a matrix denies everything (the service fails closed), and an
      // app that silently renders empty is worse than one that says why.
      final permissions = await _remote.permissions();
      return (session.user.toEntity(), permissions);
    });

    return switch (result) {
      // Any step past the token save could have left tokens behind for a
      // session we're about to report as failed — drop them.
      Left(value: final failure) => await _abandonSession(failure),
      Right(value: (final user, final permissions)) => _adopt(
        user,
        permissions,
      ),
    };
  }

  @override
  Future<Result<AuthUser>> me() async {
    final result = await safeCall(_remote.me);
    return switch (result) {
      Left(value: final failure) => Left(failure),
      // `/auth/me` embeds the matrix, so no second round trip. A `null`
      // `permissions` would mean the server didn't send the array at all; that
      // leaves the matrix empty, which denies — same as the server would.
      Right(value: final dto) => _adopt(
        dto.toEntity(),
        dto.permissions ?? const [],
      ),
    };
  }

  /// Installs the role's permissions for this session and hands back the user.
  Result<AuthUser> _adopt(AuthUser user, List<PermissionDto> permissions) {
    _permissions.load(permissions.map((p) => p.toEntity()));
    return Right(user);
  }

  Future<Result<AuthUser>> _abandonSession(Failure failure) async {
    await _tokenStorage.clear();
    _permissions.clear();
    return Left(failure);
  }

  @override
  Future<Result<Unit>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return safeCall(() async {
      await _remote.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return unit;
    });
  }

  @override
  Future<Result<Unit>> logout() async {
    final result = await safeCall(() async {
      await _remote.logout();
      return unit;
    });
    // Logout is client-side/audit-only on the server, so always drop the local
    // session — even if the audit call failed — to reach a clean signed-out
    // state. (The interceptor stops attaching a bearer once storage is empty.)
    await _tokenStorage.clear();
    _permissions.clear();
    return result;
  }
}
