import 'package:algo_erp_front/core/data/mapper.dart';
import 'package:algo_erp_front/features/organization_company/data/company_profile_dto.dart';
import 'package:algo_erp_front/features/organization_company/domain/company_profile.dart';

class CompanyProfileMapper
    implements Mapper<CompanyProfileDto, CompanyProfile> {
  const CompanyProfileMapper();

  @override
  CompanyProfile toEntity(CompanyProfileDto dto) => CompanyProfile(
    id: dto.id,
    name: dto.companyName,
    branch: dto.branch,
    trn: dto.trn,
    licenseNumber: dto.licenseNumber,
    fssaiLicense: dto.fssaiLicense,
    email: dto.email,
    phoneNumber: dto.phoneNumber,
    mobileNumber: dto.mobileNumber,
    website: dto.website,
    building: dto.building,
    street: dto.street,
    addressLine: dto.addressLine,
    city: dto.city,
    country: dto.country,
    poBox: dto.poBox,
    location: dto.location,
    currency: dto.currency,
    currencyDecimal: dto.currencyDecimal,
  );

  @override
  CompanyProfileDto toDto(CompanyProfile entity) => CompanyProfileDto(
    id: entity.id,
    companyName: entity.name,
    branch: entity.branch,
    trn: entity.trn,
    licenseNumber: entity.licenseNumber,
    fssaiLicense: entity.fssaiLicense,
    email: entity.email,
    phoneNumber: entity.phoneNumber,
    mobileNumber: entity.mobileNumber,
    website: entity.website,
    building: entity.building,
    street: entity.street,
    addressLine: entity.addressLine,
    city: entity.city,
    country: entity.country,
    poBox: entity.poBox,
    location: entity.location,
    currency: entity.currency,
    currencyDecimal: entity.currencyDecimal,
  );
}
