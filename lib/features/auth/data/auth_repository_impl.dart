import 'package:algo_erp_front/core/auth/token_storage.dart';
import 'package:algo_erp_front/core/error/safe_call.dart';
import 'package:algo_erp_front/features/auth/data/auth_remote_data_source.dart';
import 'package:algo_erp_front/features/auth/data/dtos/auth_session_dto.dart';
import 'package:algo_erp_front/features/auth/domain/auth_repository.dart';
import 'package:algo_erp_front/features/auth/domain/entities/auth_user.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

/// Wraps [AuthRemoteDataSource] in `safeCall` and owns the local token
/// lifecycle: persist on login, clear on logout. Everything above this layer
/// sees `Result<AuthUser>`/`Result<Unit>` and is oblivious to tokens.
@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remote, this._tokenStorage);

  final AuthRemoteDataSource _remote;
  final TokenStorage _tokenStorage;

  @override
  Future<Result<AuthUser>> login({
    required String username,
    required String password,
  }) async {
    final result = await safeCall(
      () => _remote.login(username: username, password: password),
    );
    // Persist tokens only on the happy path, then hand back the clean entity.
    return switch (result) {
      Left(value: final failure) => Left(failure),
      Right(value: final session) => await _persistSession(session),
    };
  }

  Future<Result<AuthUser>> _persistSession(AuthSessionDto session) async {
    await _tokenStorage.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    return Right(session.user.toEntity());
  }

  @override
  Future<Result<AuthUser>> me() async {
    final result = await safeCall(_remote.me);
    return result.map((dto) => dto.toEntity());
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
    // tokens — even if the audit call failed — to reach a clean signed-out
    // state. (The interceptor stops attaching a bearer once storage is empty.)
    await _tokenStorage.clear();
    return result;
  }
}
