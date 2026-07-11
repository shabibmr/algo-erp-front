import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/data/remote_repository.dart';
import 'package:algo_erp_front/core/di/repo_binding.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/inventory_godown/data/godown_dto.dart';
import 'package:algo_erp_front/features/inventory_godown/data/godown_mapper.dart';
import 'package:algo_erp_front/features/inventory_godown/domain/godown.dart';
import 'package:algo_erp_front/features/inventory_godown/godown_manifest.dart';

const _godownMapper = GodownMapper();

RemoteRepository<Godown, int> createGodownRepository(DioClient client) {
  return buildRepository<Godown, int>(
    client: client,
    resourcePath: godownManifest.resourcePath,
    decode: (json) => _godownMapper.toEntity(GodownDto.fromJson(json)),
    encode: (g) => _godownMapper.toDto(g).toJson(),
    idOf: (g) => g.id,
  );
}

CrudBloc<Godown, int, void> createGodownCrudBloc(DioClient client) {
  return CrudBloc<Godown, int, void>(
    repository: createGodownRepository(client),
    idOf: (g) => g.id,
  );
}
