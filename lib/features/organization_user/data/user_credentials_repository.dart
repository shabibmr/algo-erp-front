import 'package:algo_erp_front/core/data/remote_data_source.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/safe_call.dart';
import 'package:algo_erp_front/core/network/api_response.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/network/paginated.dart';
import 'package:algo_erp_front/features/organization_user/data/user_credentials_dto.dart';
import 'package:algo_erp_front/features/organization_user/data/user_credentials_mapper.dart';
import 'package:algo_erp_front/features/organization_user/domain/user_credentials.dart';
import 'package:fpdart/fpdart.dart';

/// Users use different create vs update bodies; delete is soft-deactivate.
class UserCredentialsRepository implements Repository<UserCredentials, int> {
  UserCredentialsRepository(this._client, {UserCredentialsMapper? mapper})
    : _mapper = mapper ?? const UserCredentialsMapper();

  final DioClient _client;
  final UserCredentialsMapper _mapper;

  static const _path = '/organization/users';

  @override
  Future<Result<Paginated<UserCredentials>>> list(PageQuery query) {
    return safeCall(() async {
      final res = await _client.dio.get<Object?>(
        _path,
        queryParameters: {
          'page': query.page,
          'limit': query.limit,
          if (query.search != null && query.search!.isNotEmpty)
            'search': query.search,
        },
      );
      final envelope = decodeApiResponse<JsonMap>(
        res.data,
        (j) => j! as JsonMap,
      );
      final data = envelope.data;
      if (data == null) {
        throw const FormatException('Expected users page');
      }
      final page = Paginated<JsonMap>.fromJson(data, (j) => j! as JsonMap);
      return Paginated<UserCredentials>(
        items: page.items
            .map((j) => _mapper.toEntity(UserCredentialsDto.fromJson(j)))
            .toList(growable: false),
        meta: page.meta,
      );
    });
  }

  @override
  Future<Result<UserCredentials>> getById(int id) {
    return safeCall(() async {
      final res = await _client.dio.get<Object?>('$_path/$id');
      final envelope = decodeApiResponse<JsonMap>(
        res.data,
        (j) => j! as JsonMap,
      );
      final data = envelope.data;
      if (data == null) {
        throw const FormatException('Expected user');
      }
      return _mapper.toEntity(UserCredentialsDto.fromJson(data));
    });
  }

  @override
  Future<Result<UserCredentials>> create(UserCredentials entity) {
    return safeCall(() async {
      final res = await _client.dio.post<Object?>(
        _path,
        data: _mapper.toDto(entity).toCreateJson(),
      );
      final envelope = decodeApiResponse<JsonMap>(
        res.data,
        (j) => j! as JsonMap,
      );
      final data = envelope.data;
      if (data == null) {
        throw const FormatException('Expected created user');
      }
      return _mapper.toEntity(UserCredentialsDto.fromJson(data));
    });
  }

  @override
  Future<Result<UserCredentials>> update(int id, UserCredentials entity) {
    return safeCall(() async {
      final res = await _client.dio.put<Object?>(
        '$_path/$id',
        data: _mapper.toDto(entity).toUpdateJson(),
      );
      final envelope = decodeApiResponse<JsonMap>(
        res.data,
        (j) => j! as JsonMap,
      );
      final data = envelope.data;
      if (data == null) {
        throw const FormatException('Expected updated user');
      }
      return _mapper.toEntity(UserCredentialsDto.fromJson(data));
    });
  }

  @override
  Future<Result<Unit>> delete(int id) {
    return safeCall(() async {
      await _client.dio.delete<Object?>('$_path/$id');
      return unit;
    });
  }
}
