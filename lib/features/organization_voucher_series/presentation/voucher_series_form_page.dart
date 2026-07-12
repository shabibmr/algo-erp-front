import 'package:algo_erp_front/core/bloc/detail_bloc.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_form_surface.dart';
import 'package:algo_erp_front/features/organization_voucher_series/domain/voucher_series.dart';
import 'package:algo_erp_front/features/organization_voucher_series/voucher_series_di.dart';
import 'package:algo_erp_front/features/organization_voucher_series/voucher_series_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class VoucherSeriesFormPage extends StatelessWidget {
  const VoucherSeriesFormPage({required this.mode, super.key, this.entityId});

  final FormMode mode;
  final int? entityId;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<Repository<VoucherSeries, int>>(
      create: (_) => createVoucherSeriesRepository(getIt<DioClient>()),
      child: Builder(
        builder: (context) {
          final surface = MasterFormSurface<VoucherSeries, int>(
            manifest: voucherSeriesManifest,
            mode: mode,
            idOf: (s) => s.id,
            onSaved: (_) => context.go(voucherSeriesManifest.resourcePath),
            onDeleted: () => context.go(voucherSeriesManifest.resourcePath),
          );
          return AdaptiveLayout(
            child: mode == FormMode.edit
                ? BlocProvider<DetailBloc<VoucherSeries, int>>(
                    create: (ctx) => DetailBloc<VoucherSeries, int>(
                      repository: ctx.read<Repository<VoucherSeries, int>>(),
                      id: entityId!,
                    )..add(const DetailLoadRequested()),
                    child: surface,
                  )
                : surface,
          );
        },
      ),
    );
  }
}
