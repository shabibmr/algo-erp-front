import 'package:algo_erp_front/core/error/safe_call.dart';
import 'package:algo_erp_front/features/auth/domain/entities/auth_user.dart';
import 'package:fpdart/fpdart.dart';

/// The authentication surface the app programs against.
///
/// Implementations persist the token pair through `TokenStorage` on a
/// successful [login] and clear it on [logout], so callers only ever deal with
/// `Result<T>` — never tokens, never raw exceptions.
abstract interface class AuthRepository {
  /// Authenticates and persists the returned tokens.
  Future<Result<AuthUser>> login({
    required String username,
    required String password,
  });

  /// Validates the stored session against `/auth/me`, returning the profile.
  Future<Result<AuthUser>> me();

  /// Changes the current user's password (session-preserving server-side).
  Future<Result<Unit>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Logs out (audit-only server-side) and clears the local token pair.
  Future<Result<Unit>> logout();
}
