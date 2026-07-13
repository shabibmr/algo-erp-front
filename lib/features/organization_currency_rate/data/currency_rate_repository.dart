import 'package:algo_erp_front/core/data/remote_data_source.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/error/safe_call.dart';
import 'package:algo_erp_front/core/network/api_response.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/network/paginated.dart';
import 'package:algo_erp_front/features/organization_currency_rate/data/currency_rate_dto.dart';
import 'package:algo_erp_front/features/organization_currency_rate/data/currency_rate_mapper.dart';
import 'package:algo_erp_front/features/organization_currency_rate/domain/currency_rate.dart';
import 'package:fpdart/fpdart.dart';

/// List lives at `/rates/history`; create/get at `/rates` / `/rates/:id`.
/// Lookup `GET /rates?currencyId&date` is not used by this master.
class CurrencyRateRepository implements Repository<CurrencyRate, int> {
  CurrencyRateRepository(this._client, {CurrencyRateMapper? mapper})
    : _mapper = mapper ?? const CurrencyRateMapper();

  final DioClient _client;
  final CurrencyRateMapper _mapper;

  static const _listPath = '/organization/rates/history';
  static const _itemPath = '/organization/rates';

  @override
  Future<Result<Paginated<CurrencyRate>>> list(PageQuery query) {
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
      if (data is! Map<String, dynamic>) {
        throw const FormatException('Expected paginated rates payload');
      }
      final page = Paginated<JsonMap>.fromJson(data, (j) => j! as JsonMap);
      return Paginated<CurrencyRate>(
        items: [
          for (final raw in page.items)
            _mapper.toEntity(CurrencyRateDto.fromJson(raw)),
        ],
        meta: page.meta,
      );
    });
  }

  @override
  Future<Result<CurrencyRate>> getById(int id) {
    return safeCall(() async {
      final res = await _client.dio.get<Object?>('$_itemPath/$id');
      final envelope = decodeApiResponse<JsonMap>(
        res.data,
        (j) => j! as JsonMap,
      );
      final data = envelope.data;
      if (data == null) {
        throw const FormatException('Expected exchange rate');
      }
      return _mapper.toEntity(CurrencyRateDto.fromJson(data));
    });
  }

  @override
  Future<Result<CurrencyRate>> create(CurrencyRate entity) {
    return safeCall(() async {
      final res = await _client.dio.post<Object?>(
        _itemPath,
        data: _mapper.toDto(entity).toJson(),
      );
      final envelope = decodeApiResponse<JsonMap>(
        res.data,
        (j) => j! as JsonMap,
      );
      final data = envelope.data;
      if (data == null) {
        throw const FormatException('Expected created rate');
      }
      return _mapper.toEntity(CurrencyRateDto.fromJson(data));
    });
  }

  @override
  Future<Result<CurrencyRate>> update(int id, CurrencyRate entity) {
    return Future.value(
      const Left(Failure.unknown('Exchange rates are append-only')),
    );
  }

  @override
  Future<Result<Unit>> delete(int id) {
    return Future.value(
      const Left(Failure.unknown('Exchange rates cannot be deleted')),
    );
  }
}
