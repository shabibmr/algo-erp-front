import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/data/remote_repository.dart';
import 'package:algo_erp_front/core/di/repo_binding.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/organization_voucher_series/data/voucher_series_dto.dart';
import 'package:algo_erp_front/features/organization_voucher_series/data/voucher_series_mapper.dart';
import 'package:algo_erp_front/features/organization_voucher_series/domain/voucher_series.dart';

const _voucherSeriesMapper = VoucherSeriesMapper();

const voucherSeriesResourcePath = '/organization/voucher-series';

RemoteRepository<VoucherSeries, int> createVoucherSeriesRepository(
  DioClient client,
) {
  return buildRepository<VoucherSeries, int>(
    client: client,
    resourcePath: voucherSeriesResourcePath,
    decode: (json) =>
        _voucherSeriesMapper.toEntity(VoucherSeriesDto.fromJson(json)),
    encode: (s) => _voucherSeriesMapper.toDto(s).toJson(),
    idOf: (s) => s.id,
  );
}

CrudBloc<VoucherSeries, int, void> createVoucherSeriesCrudBloc(
  DioClient client,
) {
  return CrudBloc<VoucherSeries, int, void>(
    repository: createVoucherSeriesRepository(client),
    idOf: (s) => s.id,
  );
}
