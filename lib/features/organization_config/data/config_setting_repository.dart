import 'package:algo_erp_front/core/data/remote_data_source.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/error/safe_call.dart';
import 'package:algo_erp_front/core/network/api_response.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/network/paginated.dart';
import 'package:algo_erp_front/features/organization_config/data/config_setting_dto.dart';
import 'package:algo_erp_front/features/organization_config/data/config_setting_mapper.dart';
import 'package:algo_erp_front/features/organization_config/domain/config_setting.dart';
import 'package:fpdart/fpdart.dart';

/// List is a full array; get/update are keyed by [ConfigSetting.key], not id.
class ConfigSettingRepository implements Repository<ConfigSetting, int> {
  ConfigSettingRepository(this._client, {ConfigSettingMapper? mapper})
    : _mapper = mapper ?? const ConfigSettingMapper();

  final DioClient _client;
  final ConfigSettingMapper _mapper;

  static const _path = '/organization/config';

  @override
  Future<Result<Paginated<ConfigSetting>>> list(PageQuery query) {
    return safeCall(() async {
      final items = await _loadAll();
      final search = query.search?.trim().toLowerCase();
      final filtered = (search == null || search.isEmpty)
          ? items
          : items
                .where(
                  (s) =>
                      s.key.toLowerCase().contains(search) ||
                      s.value.toLowerCase().contains(search) ||
                      (s.displayText?.toLowerCase().contains(search) ?? false),
                )
                .toList(growable: false);
      return Paginated<ConfigSetting>(
        items: filtered,
        meta: PaginationMeta(
          total: filtered.length,
          page: 1,
          limit: filtered.isEmpty ? query.limit : filtered.length,
          totalPages: 1,
        ),
      );
    });
  }

  @override
  Future<Result<ConfigSetting>> getById(int id) {
    return safeCall(() async {
      final items = await _loadAll();
      for (final s in items) {
        if (s.id == id) return s;
      }
      throw StateError('Config setting $id not found');
    });
  }

  @override
  Future<Result<ConfigSetting>> create(ConfigSetting entity) {
    return Future.value(
      const Left(
        Failure.unknown('Config settings are not created from the UI'),
      ),
    );
  }

  @override
  Future<Result<ConfigSetting>> update(int id, ConfigSetting entity) {
    return safeCall(() async {
      final key = entity.key;
      if (key.isEmpty) {
        throw const FormatException('Config key is required');
      }
      final res = await _client.dio.put<Object?>(
        '$_path/$key',
        data: _mapper.toDto(entity).toUpdateJson(),
      );
      final envelope = decodeApiResponse<JsonMap>(
        res.data,
        (j) => j! as JsonMap,
      );
      final data = envelope.data;
      if (data == null) {
        throw const FormatException('Expected updated config');
      }
      return _mapper.toEntity(ConfigSettingDto.fromJson(data));
    });
  }

  @override
  Future<Result<Unit>> delete(int id) {
    return Future.value(
      const Left(Failure.unknown('Config settings cannot be deleted')),
    );
  }

  Future<List<ConfigSetting>> _loadAll() async {
    final res = await _client.dio.get<Object?>(_path);
    final envelope = decodeApiResponse<Object?>(res.data, (j) => j);
    final data = envelope.data;
    if (data is! List) {
      throw const FormatException('Expected config settings array');
    }
    return [
      for (final raw in data)
        if (raw is Map<String, dynamic>)
          _mapper.toEntity(ConfigSettingDto.fromJson(raw)),
    ];
  }
}
