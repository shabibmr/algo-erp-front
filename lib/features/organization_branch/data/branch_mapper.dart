import 'package:algo_erp_front/core/data/mapper.dart';
import 'package:algo_erp_front/features/organization_branch/data/branch_dto.dart';
import 'package:algo_erp_front/features/organization_branch/domain/branch.dart';

class BranchMapper implements Mapper<BranchDto, Branch> {
  const BranchMapper();

  @override
  Branch toEntity(BranchDto dto) => Branch(
    id: dto.id,
    code: dto.branchCode,
    name: dto.branchName,
    companyId: dto.companyId,
    address: dto.address,
    isActive: dto.isActive,
  );

  @override
  BranchDto toDto(Branch entity) => BranchDto(
    id: entity.id,
    branchCode: entity.code,
    branchName: entity.name,
    companyId: entity.companyId,
    address: entity.address,
    isActive: entity.isActive,
  );
}
