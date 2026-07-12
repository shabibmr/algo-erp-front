import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/bloc/crud_bloc_scope.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/employee_shift/data/shift_master_repository.dart';
import 'package:algo_erp_front/features/employee_shift/domain/shift_master.dart';
import 'package:algo_erp_front/features/employee_shift/shift_master_manifest.dart';
import 'package:flutter/widgets.dart';

Repository<ShiftMaster, int> createShiftMasterRepository(DioClient client) {
  return ShiftMasterRepository(client);
}

CrudBloc<ShiftMaster, int, void> createShiftMasterCrudBloc(DioClient client) {
  return CrudBloc<ShiftMaster, int, void>(
    repository: createShiftMasterRepository(client),
    idOf: (s) => s.id,
  );
}

CrudBloc<ShiftMaster, int, void> shiftMasterCrudBloc(BuildContext context) {
  return CrudBlocScope.of<ShiftMaster, int, void>(
    context,
    shiftMasterManifest.id,
    () => createShiftMasterCrudBloc(getIt<DioClient>()),
  );
}
