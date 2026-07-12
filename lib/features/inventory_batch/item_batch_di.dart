import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/bloc/crud_bloc_scope.dart';
import 'package:algo_erp_front/core/data/remote_repository.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/di/repo_binding.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/inventory_batch/data/item_batch_dto.dart';
import 'package:algo_erp_front/features/inventory_batch/data/item_batch_mapper.dart';
import 'package:algo_erp_front/features/inventory_batch/domain/item_batch.dart';
import 'package:algo_erp_front/features/inventory_batch/item_batch_manifest.dart';
import 'package:flutter/widgets.dart';

const _itemBatchMapper = ItemBatchMapper();

RemoteRepository<ItemBatch, int> createItemBatchRepository(DioClient client) {
  return buildRepository<ItemBatch, int>(
    client: client,
    resourcePath: itemBatchManifest.resourcePath,
    decode: (json) => _itemBatchMapper.toEntity(ItemBatchDto.fromJson(json)),
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

/// The one ItemBatch [CrudBloc], shared by the list and form routes via the
/// [CrudBlocScope] in `AppShell`. Both pages must go through this —
/// resolving the bloc any other way gives the form a private instance the
/// list never sees, which is how created rows went missing.
CrudBloc<ItemBatch, int, void> itemBatchCrudBloc(BuildContext context) {
  return CrudBlocScope.of<ItemBatch, int, void>(
    context,
    itemBatchManifest.id,
    () => createItemBatchCrudBloc(getIt<DioClient>()),
  );
}
