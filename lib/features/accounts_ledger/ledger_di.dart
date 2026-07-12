import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/bloc/crud_bloc_scope.dart';
import 'package:algo_erp_front/core/data/remote_repository.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/di/repo_binding.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/accounts_ledger/data/ledger_dto.dart';
import 'package:algo_erp_front/features/accounts_ledger/data/ledger_mapper.dart';
import 'package:algo_erp_front/features/accounts_ledger/domain/ledger.dart';
import 'package:algo_erp_front/features/accounts_ledger/ledger_manifest.dart';
import 'package:flutter/widgets.dart';

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

/// The one Ledger [CrudBloc], shared by the list and form routes via the
/// [CrudBlocScope] in `AppShell`. Both pages must go through this — resolving
/// the bloc any other way gives the form a private instance the list never
/// sees, which is how created rows went missing.
CrudBloc<Ledger, int, void> ledgerCrudBloc(BuildContext context) {
  return CrudBlocScope.of<Ledger, int, void>(
    context,
    ledgerManifest.id,
    () => createLedgerCrudBloc(getIt<DioClient>()),
  );
}
