import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
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
    // `.value`, not `create:` — the bloc is owned by the CrudBlocScope
    // in AppShell so the form route shares it. See addressBookCrudBloc.
    return BlocProvider<CrudBloc<AddressBook, int, void>>.value(
      value: addressBookCrudBloc(context),
      child: AdaptiveLayout(
        child: MasterListSurface<AddressBook>(
          manifest: addressBookManifest,
          idOf: (contact) => contact.id,
          onCreate: () => context.push('/organization/contacts/new'),
          onTap: (contact) =>
              context.push('/organization/contacts/${contact.id}'),
        ),
      ),
    );
  }
}
