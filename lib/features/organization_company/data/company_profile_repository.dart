import 'package:algo_erp_front/core/data/remote_data_source.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/error/safe_call.dart';
import 'package:algo_erp_front/core/network/api_response.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/network/paginated.dart';
import 'package:algo_erp_front/features/organization_company/data/company_profile_dto.dart';
import 'package:algo_erp_front/features/organization_company/data/company_profile_mapper.dart';
import 'package:algo_erp_front/features/organization_company/domain/company_profile.dart';
import 'package:fpdart/fpdart.dart';

/// Company list is `/companies` but get/update are `/company/:id` (singular).
/// Create is company-provision (out of scope); delete does not exist.
class CompanyProfileRepository implements Repository<CompanyProfile, int> {
  CompanyProfileRepository(this._client, {CompanyProfileMapper? mapper})
    : _mapper = mapper ?? const CompanyProfileMapper();

  final DioClient _client;
  final CompanyProfileMapper _mapper;

  static const _listPath = '/organization/companies';
  static const _itemPath = '/organization/company';

  @override
  Future<Result<Paginated<CompanyProfile>>> list(PageQuery query) {
    return safeCall(() async {
      final res = await _client.dio.get<Object?>(
        _listPath,
        queryParameters: {
          'page': query.page,
          'limit': query.limit,
          if (query.search != null && query.search!.isNotEmpty)
            'search': query.search,
        },
      );
      final envelope = decodeApiResponse<Object?>(res.data, (j) => j);
      final data = envelope.data;
      List<dynamic> items;
      PaginationMeta meta;
      if (data is Map<String, dynamic> && data['items'] is List) {
        items = data['items'] as List<dynamic>;
        final m = data['meta'] as Map<String, dynamic>?;
        meta = PaginationMeta(
          total: m?['total'] as int? ?? items.length,
          page: m?['page'] as int? ?? 1,
          limit: m?['limit'] as int? ?? items.length,
          totalPages: m?['totalPages'] as int? ?? 1,
        );
      } else if (data is List) {
        items = data;
        meta = PaginationMeta(
          total: items.length,
          page: 1,
          limit: items.length,
          totalPages: 1,
        );
      } else {
        throw const FormatException('Expected company list');
      }
      var companies = [
        for (final raw in items)
          if (raw is Map<String, dynamic>)
            _mapper.toEntity(CompanyProfileDto.fromJson(raw)),
      ];

      // Backend list is a full dump (no search). Filter client-side so FK
      // pickers (e.g. Branch form) return matches as the user types.
      final search = query.search?.trim().toLowerCase();
      if (search != null && search.isNotEmpty) {
        companies = [
          for (final c in companies)
            if (_matchesSearch(c, search)) c,
        ];
        meta = PaginationMeta(
          total: companies.length,
          page: 1,
          limit: companies.isEmpty ? query.limit : companies.length,
          totalPages: 1,
        );
      }

      return Paginated<CompanyProfile>(items: companies, meta: meta);
    });
  }

  static bool _matchesSearch(CompanyProfile c, String needle) {
    bool hit(String? value) =>
        value != null && value.toLowerCase().contains(needle);
    return hit(c.name) ||
        hit(c.branch) ||
        hit(c.trn) ||
        hit(c.city) ||
        c.id.toString() == needle;
  }

  @override
  Future<Result<CompanyProfile>> getById(int id) {
    return safeCall(() async {
      final res = await _client.dio.get<Object?>('$_itemPath/$id');
      final envelope = decodeApiResponse<JsonMap>(
        res.data,
        (j) => j! as JsonMap,
      );
      final data = envelope.data;
      if (data == null) {
        throw const FormatException('Expected company profile');
      }
      return _mapper.toEntity(CompanyProfileDto.fromJson(data));
    });
  }

  @override
  Future<Result<CompanyProfile>> create(CompanyProfile entity) {
    return Future.value(
      const Left(
        Failure.unknown('Use company provision; create not supported'),
      ),
    );
  }

  @override
  Future<Result<CompanyProfile>> update(int id, CompanyProfile entity) {
    return safeCall(() async {
      final res = await _client.dio.put<Object?>(
        '$_itemPath/$id',
        data: _mapper.toDto(entity).toJson(),
      );
      final envelope = decodeApiResponse<JsonMap>(
        res.data,
        (j) => j! as JsonMap,
      );
      final data = envelope.data;
      if (data == null) {
        throw const FormatException('Expected updated company');
      }
      return _mapper.toEntity(CompanyProfileDto.fromJson(data));
    });
  }

  @override
  Future<Result<Unit>> delete(int id) {
    return Future.value(
      const Left(Failure.unknown('Company profile cannot be deleted')),
    );
  }
}
