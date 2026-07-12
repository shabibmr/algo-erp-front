import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/bloc/crud_contract.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_list_surface.dart';
import 'package:algo_erp_front/features/organization_voucher_series/domain/voucher_series.dart';
import 'package:algo_erp_front/features/organization_voucher_series/voucher_series_di.dart';
import 'package:algo_erp_front/features/organization_voucher_series/voucher_series_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class VoucherSeriesListPage extends StatelessWidget {
  const VoucherSeriesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CrudBloc<VoucherSeries, int, void>>(
      create: (_) =>
          createVoucherSeriesCrudBloc(getIt<DioClient>())
            ..add(const CrudLoadRequested()),
      child: AdaptiveLayout(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              voucherSeriesManifest.label,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: MasterListSurface<VoucherSeries>(
                manifest: voucherSeriesManifest,
                idOf: (s) => s.id,
                onCreate: () =>
                    context.push('/organization/voucher-series/new'),
                onTap: (s) =>
                    context.push('/organization/voucher-series/${s.id}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
