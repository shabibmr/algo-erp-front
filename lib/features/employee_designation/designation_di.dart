import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/data/remote_repository.dart';
import 'package:algo_erp_front/core/di/repo_binding.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/employee_designation/data/designation_dto.dart';
import 'package:algo_erp_front/features/employee_designation/data/designation_mapper.dart';
import 'package:algo_erp_front/features/employee_designation/designation_manifest.dart';
import 'package:algo_erp_front/features/employee_designation/domain/designation.dart';

/// Plain factory functions, matching Brand's precedent — see `brand_di.dart`.
/// Designation's manifest additionally needs a `Department` repository for
/// its `FieldType.fk` field — see `designation_manifest.dart`.
const _designationMapper = DesignationMapper();

RemoteRepository<Designation, int> createDesignationRepository(
  DioClient client,
) {
  return buildRepository<Designation, int>(
    client: client,
    resourcePath: designationManifest.resourcePath,
    decode: (json) =>
        _designationMapper.toEntity(DesignationDto.fromJson(json)),
    encode: (d) => _designationMapper.toDto(d).toJson(),
    idOf: (d) => d.id,
  );
}

CrudBloc<Designation, int, void> createDesignationCrudBloc(
  DioClient client,
) {
  return CrudBloc<Designation, int, void>(
    repository: createDesignationRepository(client),
    idOf: (d) => d.id,
  );
}
