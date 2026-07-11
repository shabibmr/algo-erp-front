import 'package:algo_erp_front/core/network/api_response.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/auth/data/dtos/auth_session_dto.dart';
import 'package:algo_erp_front/features/auth/data/dtos/auth_user_dto.dart';
import 'package:algo_erp_front/features/auth/data/dtos/permission_dto.dart';
import 'package:injectable/injectable.dart';

/// Thin transport over the `/auth/*` endpoints. Speaks only DTOs and unwraps
/// the `{success, data, …}` envelope via [decodeApiResponse]; it does no error
/// handling — any `DioException` propagates for the repository to fold into a
/// `Result` through `safeCall`. The [DioClient]'s `AuthInterceptor` already
/// attaches the bearer token and performs 401→refresh→replay transparently, so
/// nothing token-related lives here.
@lazySingleton
class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._client);

  final DioClient _client;

  Future<AuthSessionDto> login({
    required String username,
    required String password,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'username': username, 'password': password},
    );
    return decodeApiResponse(
      response.data,
      (json) => AuthSessionDto.fromJson(json! as Map<String, dynamic>),
    ).data!;
  }

  Future<AuthUserDto> me() async {
    final response = await _client.dio.get<Map<String, dynamic>>('/auth/me');
    return decodeApiResponse(
      response.data,
      (json) => AuthUserDto.fromJson(json! as Map<String, dynamic>),
    ).data!;
  }

  /// `GET /auth/permissions` — the caller's role permission matrix. Needed
  /// after `login`, whose response carries the user but not the matrix;
  /// `/auth/me` already embeds the same rows, so it needs no second call.
  Future<List<PermissionDto>> permissions() async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/auth/permissions',
    );
    final data = decodeApiResponse(
      response.data,
      (json) => json! as Map<String, dynamic>,
    ).data!;
    final rows = data['permissions'] as List? ?? const [];
    return rows
        .map((row) => PermissionDto.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// `POST /auth/change-password` — returns only `{success, message}`, so the
  /// call succeeds or throws; there is no payload to decode.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _client.dio.post<Map<String, dynamic>>(
      '/auth/change-password',
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }

  /// `POST /auth/logout` — audit-only server-side (no token blacklist); the
  /// repository still clears local tokens after this returns.
  Future<void> logout() async {
    await _client.dio.post<Map<String, dynamic>>('/auth/logout');
  }
}
