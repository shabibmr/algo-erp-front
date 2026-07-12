import 'package:algo_erp_front/core/bloc/crud_contract.dart';
import 'package:algo_erp_front/core/bloc/detail_bloc.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_form_surface.dart';
import 'package:algo_erp_front/features/organization_address_book/address_book_di.dart';
import 'package:algo_erp_front/features/organization_address_book/address_book_manifest.dart';
import 'package:algo_erp_front/features/organization_address_book/domain/address_book.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AddressBookFormPage extends StatelessWidget {
  const AddressBookFormPage({required this.mode, super.key, this.entityId});

  final FormMode mode;
  final int? entityId;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<Repository<AddressBook, int>>(
      create: (_) => createAddressBookRepository(getIt<DioClient>()),
      child: Builder(
        builder: (context) {
          // The surface has already persisted through the repository by the
          // time these fire, so the shared list bloc is told to refetch —
          // never CrudItemCreated/Updated/Deleted, which would write again.
          void refreshListAndReturn() {
            addressBookCrudBloc(context).add(const CrudRefreshRequested());
            context.go(addressBookManifest.resourcePath);
          }

          final surface = MasterFormSurface<AddressBook, int>(
            manifest: addressBookManifest,
            mode: mode,
            idOf: (contact) => contact.id,
            onSaved: (_) => refreshListAndReturn(),
            onDeleted: refreshListAndReturn,
          );
          return AdaptiveLayout(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mode == FormMode.create
                      ? 'New ${addressBookManifest.label}'
                      : addressBookManifest.supportsUpdate
                      ? 'Edit ${addressBookManifest.label}'
                      : 'View ${addressBookManifest.label}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                if (mode == FormMode.edit)
                  BlocProvider<DetailBloc<AddressBook, int>>(
                    create: (ctx) => DetailBloc<AddressBook, int>(
                      repository: ctx.read<Repository<AddressBook, int>>(),
                      id: entityId!,
                    )..add(const DetailLoadRequested()),
                    child: surface,
                  )
                else
                  surface,
              ],
            ),
          );
        },
      ),
    );
  }
}
