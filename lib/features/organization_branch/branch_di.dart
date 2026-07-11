import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/data/remote_repository.dart';
import 'package:algo_erp_front/core/di/repo_binding.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/organization_branch/branch_manifest.dart';
import 'package:algo_erp_front/features/organization_branch/data/branch_dto.dart';
import 'package:algo_erp_front/features/organization_branch/data/branch_mapper.dart';
import 'package:algo_erp_front/features/organization_branch/domain/branch.dart';

const _branchMapper = BranchMapper();

RemoteRepository<Branch, int> createBranchRepository(DioClient client) {
  return buildRepository<Branch, int>(
    client: client,
    resourcePath: branchManifest.resourcePath,
    decode: (json) => _branchMapper.toEntity(BranchDto.fromJson(json)),
    encode: (branch) => _branchMapper.toDto(branch).toJson(),
    idOf: (branch) => branch.id,
  );
}

CrudBloc<Branch, int, void> createBranchCrudBloc(DioClient client) {
  return CrudBloc<Branch, int, void>(
    repository: createBranchRepository(client),
    idOf: (branch) => branch.id,
  );
}
