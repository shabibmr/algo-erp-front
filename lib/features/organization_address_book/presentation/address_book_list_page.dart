import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/bloc/crud_contract.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_list_surface.dart';
import 'package:algo_erp_front/features/organization_address_book/address_book_di.dart';
import 'package:algo_erp_front/features/organization_address_book/address_book_manifest.dart';
import 'package:algo_erp_front/features/organization_address_book/domain/address_book.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AddressBookListPage extends StatelessWidget {
  const AddressBookListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CrudBloc<AddressBook, int, void>>(
      create: (_) => createAddressBookCrudBloc(getIt<DioClient>())
        ..add(const CrudLoadRequested()),
      child: AdaptiveLayout(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              addressBookManifest.label,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: MasterListSurface<AddressBook>(
                manifest: addressBookManifest,
                idOf: (contact) => contact.id,
                onCreate: () => context.push('/organization/contacts/new'),
                onTap: (contact) =>
                    context.push('/organization/contacts/${contact.id}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
