import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/bloc/crud_bloc_scope.dart';
import 'package:algo_erp_front/core/data/remote_repository.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/di/repo_binding.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/organization_address_book/address_book_manifest.dart';
import 'package:algo_erp_front/features/organization_address_book/data/address_book_dto.dart';
import 'package:algo_erp_front/features/organization_address_book/data/address_book_mapper.dart';
import 'package:algo_erp_front/features/organization_address_book/domain/address_book.dart';
import 'package:flutter/widgets.dart';

const _addressBookMapper = AddressBookMapper();

RemoteRepository<AddressBook, int> createAddressBookRepository(
  DioClient client,
) {
  return buildRepository<AddressBook, int>(
    client: client,
    resourcePath: addressBookManifest.resourcePath,
    decode: (json) =>
        _addressBookMapper.toEntity(AddressBookDto.fromJson(json)),
    encode: (contact) => _addressBookMapper.toDto(contact).toJson(),
    idOf: (contact) => contact.id,
  );
}

CrudBloc<AddressBook, int, void> createAddressBookCrudBloc(DioClient client) {
  return CrudBloc<AddressBook, int, void>(
    repository: createAddressBookRepository(client),
    idOf: (contact) => contact.id,
  );
}

/// The one AddressBook [CrudBloc], shared by the list and form routes via the
/// [CrudBlocScope] in `AppShell`. Both pages must go through this —
/// resolving the bloc any other way gives the form a private instance the
/// list never sees, which is how created rows went missing.
CrudBloc<AddressBook, int, void> addressBookCrudBloc(BuildContext context) {
  return CrudBlocScope.of<AddressBook, int, void>(
    context,
    addressBookManifest.id,
    () => createAddressBookCrudBloc(getIt<DioClient>()),
  );
}
