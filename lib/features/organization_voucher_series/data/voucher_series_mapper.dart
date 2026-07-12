import 'package:algo_erp_front/core/data/mapper.dart';
import 'package:algo_erp_front/features/organization_voucher_series/data/voucher_series_dto.dart';
import 'package:algo_erp_front/features/organization_voucher_series/domain/voucher_series.dart';

class VoucherSeriesMapper implements Mapper<VoucherSeriesDto, VoucherSeries> {
  const VoucherSeriesMapper();

  @override
  VoucherSeries toEntity(VoucherSeriesDto dto) => VoucherSeries(
    id: dto.id,
    voucherType: dto.voucherType,
    prefix: dto.prefix,
    displayName: dto.displayName,
    companyId: dto.companyId,
    branchId: dto.branchId,
    financialYearId: dto.financialYearId,
    numberLength: dto.numberLength,
    prefixSeparator: dto.prefixSeparator,
    startingNumber: dto.startingNumber,
    isDefault: dto.isDefault,
    requireApproval: dto.requireApproval,
    isActive: dto.isActive,
  );

  @override
  VoucherSeriesDto toDto(VoucherSeries entity) => VoucherSeriesDto(
    id: entity.id,
    voucherType: entity.voucherType,
    prefix: entity.prefix,
    displayName: entity.displayName,
    companyId: entity.companyId,
    branchId: entity.branchId,
    financialYearId: entity.financialYearId,
    numberLength: entity.numberLength,
    prefixSeparator: entity.prefixSeparator,
    startingNumber: entity.startingNumber,
    isDefault: entity.isDefault,
    requireApproval: entity.requireApproval,
    isActive: entity.isActive,
  );
}
