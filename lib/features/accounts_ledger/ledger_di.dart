import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/data/remote_repository.dart';
import 'package:algo_erp_front/core/di/repo_binding.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/accounts_ledger/data/ledger_dto.dart';
import 'package:algo_erp_front/features/accounts_ledger/data/ledger_mapper.dart';
import 'package:algo_erp_front/features/accounts_ledger/domain/ledger.dart';
import 'package:algo_erp_front/features/accounts_ledger/ledger_manifest.dart';

const _ledgerMapper = LedgerMapper();

RemoteRepository<Ledger, int> createLedgerRepository(DioClient client) {
  return buildRepository<Ledger, int>(
    client: client,
    resourcePath: ledgerManifest.resourcePath,
    decode: (json) => _ledgerMapper.toEntity(LedgerDto.fromJson(json)),
    encode: (ledger) => _ledgerMapper.toDto(ledger).toJson(),
    idOf: (ledger) => ledger.id,
  );
}

CrudBloc<Ledger, int, void> createLedgerCrudBloc(DioClient client) {
  return CrudBloc<Ledger, int, void>(
    repository: createLedgerRepository(client),
    idOf: (ledger) => ledger.id,
  );
}
