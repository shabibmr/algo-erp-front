import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/error/safe_call.dart';
import 'package:algo_erp_front/core/network/api_response.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/network/paginated.dart';
import 'package:algo_erp_front/features/employee_shift/data/shift_master_dto.dart';
import 'package:algo_erp_front/features/employee_shift/data/shift_master_mapper.dart';
import 'package:algo_erp_front/features/employee_shift/domain/shift_master.dart';
import 'package:fpdart/fpdart.dart';

/// Shifts: `GET/POST /employee/shifts` only.
class ShiftMasterRepository implements Repository<ShiftMaster, int> {
  ShiftMasterRepository(this._client, {ShiftMasterMapper? mapper})
    : _mapper = mapper ?? const ShiftMasterMapper();

  final DioClient _client;
  final ShiftMasterMapper _mapper;

  static const _path = '/employee/shifts';

  @override
  Future<Result<Paginated<ShiftMaster>>> list(PageQuery query) {
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
      final envelope = decodeApiResponse<Object?>(res.data, (j) => j);
      final data = envelope.data;
      List<dynamic> items;
      PaginationMeta meta;
      if (data is Map<String, dynamic> && data['items'] is List) {
        items = data['items'] as List<dynamic>;
        final m = data['meta'] as Map<String, dynamic>?;
        meta = PaginationMeta(
          total: m?['total'] as int? ?? items.length,
          page: m?['page'] as int? ?? query.page,
          limit: m?['limit'] as int? ?? query.limit,
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
        throw const FormatException('Expected shift list');
      }
      return Paginated<ShiftMaster>(
        items: [
          for (final raw in items)
            if (raw is Map<String, dynamic>)
              _mapper.toEntity(ShiftMasterDto.fromJson(raw)),
        ],
        meta: meta,
      );
    });
  }

  @override
  Future<Result<ShiftMaster>> getById(int id) async {
    final listed = await list(const PageQuery(limit: 200));
    return listed.fold(Left.new, (page) {
      for (final s in page.items) {
        if (s.id == id) return Right(s);
      }
      return const Left(Failure.notFound('Shift not found'));
    });
  }

  @override
  Future<Result<ShiftMaster>> create(ShiftMaster entity) {
    return safeCall(() async {
      final res = await _client.dio.post<Object?>(
        _path,
        data: _mapper.toDto(entity).toJson(),
      );
      final envelope = decodeApiResponse<Map<String, dynamic>>(
        res.data,
        (j) => j! as Map<String, dynamic>,
      );
      final data = envelope.data;
      if (data == null) {
        throw const FormatException('Expected shift in response');
      }
      return _mapper.toEntity(ShiftMasterDto.fromJson(data));
    });
  }

  @override
  Future<Result<ShiftMaster>> update(int id, ShiftMaster entity) {
    return Future.value(
      const Left(Failure.unknown('Shifts cannot be updated via API')),
    );
  }

  @override
  Future<Result<Unit>> delete(int id) {
    return Future.value(
      const Left(Failure.unknown('Shifts cannot be deleted via API')),
    );
  }
}
