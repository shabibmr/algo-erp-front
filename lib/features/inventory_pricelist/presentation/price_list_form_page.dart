import 'package:algo_erp_front/core/bloc/crud_contract.dart';
import 'package:algo_erp_front/core/bloc/detail_bloc.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_form_surface.dart';
import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/features/inventory_pricelist/domain/price_list.dart';
import 'package:algo_erp_front/features/inventory_pricelist/domain/price_list_entry.dart';
import 'package:algo_erp_front/features/inventory_pricelist/presentation/price_list_entries_panel.dart';
import 'package:algo_erp_front/features/inventory_pricelist/price_list_di.dart';
import 'package:algo_erp_front/features/inventory_pricelist/price_list_manifest.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class PriceListFormPage extends StatelessWidget {
  const PriceListFormPage({required this.mode, super.key, this.entityId});

  final FormMode mode;
  final int? entityId;

  @override
  Widget build(BuildContext context) {
    final dio = getIt<DioClient>();
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<Repository<PriceList, int>>(
          create: (_) => createPriceListRepository(dio),
        ),
        RepositoryProvider<Repository<PriceListEntry, int>>(
          create: (_) => createPriceListEntryRepository(dio),
        ),
      ],
      child: Builder(
        builder: (context) {
          // The surface has already persisted through the repository by the
          // time these fire, so the shared list bloc is told to refetch —
          // never CrudItemCreated/Updated/Deleted, which would write again.
          void refreshListAndReturn() {
            priceListCrudBloc(context).add(const CrudRefreshRequested());
            context.go(priceListManifest.resourcePath);
          }

          final surface = MasterFormSurface<PriceList, int>(
            manifest: priceListManifest,
            mode: mode,
            idOf: (p) => p.id,
            onSaved: (_) => refreshListAndReturn(),
            onDeleted: refreshListAndReturn,
            onCancel: () => context.go(priceListManifest.resourcePath),
          );

          // Edit mode stacks the nested entries panel under the header form.
          // Both need a bounded height from AdaptiveLayout.
          final body = mode == FormMode.edit && entityId != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: surface),
                    Flexible(
                      flex: 0,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 360),
                        child: SingleChildScrollView(
                          child: Builder(
                            builder: (context) {
                              final s = context.tokens.spacing;
                              return Padding(
                                padding: EdgeInsets.fromLTRB(
                                  s.md,
                                  0,
                                  s.md,
                                  s.md,
                                ),
                                child: PriceListEntriesPanel(
                                  priceListId: entityId!,
                                  repository: context
                                      .read<Repository<PriceListEntry, int>>(),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : surface;

          return AdaptiveLayout(
            child: mode == FormMode.edit
                ? BlocProvider<DetailBloc<PriceList, int>>(
                    create: (ctx) => DetailBloc<PriceList, int>(
                      repository: ctx.read<Repository<PriceList, int>>(),
                      id: entityId!,
                    )..add(const DetailLoadRequested()),
                    child: body,
                  )
                : body,
          );
        },
      ),
    );
  }
}
