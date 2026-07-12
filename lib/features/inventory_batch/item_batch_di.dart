import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/data/remote_repository.dart';
import 'package:algo_erp_front/core/di/repo_binding.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/inventory_batch/data/item_batch_dto.dart';
import 'package:algo_erp_front/features/inventory_batch/data/item_batch_mapper.dart';
import 'package:algo_erp_front/features/inventory_batch/domain/item_batch.dart';
import 'package:algo_erp_front/features/inventory_batch/item_batch_manifest.dart';

const _itemBatchMapper = ItemBatchMapper();

RemoteRepository<ItemBatch, int> createItemBatchRepository(DioClient client) {
  return buildRepository<ItemBatch, int>(
    client: client,
    resourcePath: itemBatchManifest.resourcePath,
    decode: (json) =>
        _itemBatchMapper.toEntity(ItemBatchDto.fromJson(json)),
    encode: (batch) => _itemBatchMapper.toDto(batch).toJson(),
    idOf: (batch) => batch.id,
  );
}

CrudBloc<ItemBatch, int, void> createItemBatchCrudBloc(DioClient client) {
  return CrudBloc<ItemBatch, int, void>(
    repository: createItemBatchRepository(client),
    idOf: (batch) => batch.id,
  );
}
