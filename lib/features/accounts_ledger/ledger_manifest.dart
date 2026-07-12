import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/domain/page_query.dart';
import 'package:algo_erp_front/core/manifest/entity_manifest.dart';
import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:algo_erp_front/core/manifest/form_field_spec.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/features/accounts_account_group/account_group_di.dart';
import 'package:algo_erp_front/features/accounts_account_group/domain/account_group.dart';
import 'package:algo_erp_front/features/accounts_ledger/domain/ledger.dart';
import 'package:algo_erp_front/features/organization_address_book/address_book_di.dart';
import 'package:algo_erp_front/features/organization_address_book/domain/address_book.dart';
import 'package:decimal/decimal.dart';

/// Lazy FK targets — same pattern as Designation → Department.
final _accountGroupRepository =
    createAccountGroupRepository(getIt<DioClient>());
final _addressBookRepository =
    createAddressBookRepository(getIt<DioClient>());

/// Ledger master. RBAC is coarse `'Accounts'`.
///
/// List uses this manifest. Create/edit uses the tabbed ledger form page:
/// Core (these fields) + Bank / Credit / Tax extension field lists in
/// `ledger_extension_fields.dart`, nested into one save payload.
final ledgerManifest = EntityManifest<Ledger>(
  id: 'ledger',
  label: 'Ledger',
  rbacModule: 'Accounts',
  resourcePath: '/accounts/ledgers',
  listColumns: [
    FieldSpec<Ledger>(
      key: 'code',
      label: 'Code',
      type: FieldType.text,
      cellValue: (l) => l.code ?? '—',
    ),
    FieldSpec<Ledger>(
      key: 'name',
      label: 'Name',
      type: FieldType.text,
      required: true,
      cellValue: (l) => l.name,
    ),
    FieldSpec<Ledger>(
      key: 'ledgerType',
      label: 'Type',
      type: FieldType.text,
      cellValue: (l) => l.ledgerType,
    ),
    FieldSpec<Ledger>(
      key: 'currencyCode',
      label: 'Currency',
      type: FieldType.text,
      cellValue: (l) => l.currencyCode,
    ),
    FieldSpec<Ledger>(
      key: 'isActive',
      label: 'Active',
      type: FieldType.bool,
      cellValue: (l) => l.isActive ? 'Yes' : 'No',
    ),
  ],
  searchFields: const [
    'Ledger_Name',
    'Ledger_Type',
    'ledger_code',
    'currency_code',
  ],
  formFields: [
    FormFieldSpec<Ledger>(
      key: 'code',
      wireKey: 'ledger_code',
      label: 'Code',
      type: FieldType.text,
      getValue: (l) => l.code,
      setValue: (l, v) => l.copyWith(code: v as String?),
    ),
    FormFieldSpec<Ledger>(
      key: 'name',
      wireKey: 'Ledger_Name',
      label: 'Name',
      type: FieldType.text,
      required: true,
      getValue: (l) => l.name,
      setValue: (l, v) => l.copyWith(name: v as String?),
    ),
    FormFieldSpec<Ledger>(
      key: 'ledgerType',
      wireKey: 'Ledger_Type',
      label: 'Type',
      type: FieldType.text,
      required: true,
      helperText: Ledger.ledgerTypes.join(', '),
      hintText: 'e.g. SundryDebtor',
      getValue: (l) => l.ledgerType,
      setValue: (l, v) => l.copyWith(ledgerType: v as String?),
      validator: (v) {
        final s = v as String?;
        if (s == null || s.isEmpty) return 'Type is required';
        if (!Ledger.ledgerTypes.contains(s)) {
          return 'Must be one of: ${Ledger.ledgerTypes.join(', ')}';
        }
        return null;
      },
    ),
    FormFieldSpec<Ledger>(
      key: 'accountGroupId',
      wireKey: 'account_group_id',
      label: 'Account group',
      type: FieldType.fk,
      getValue: (l) => l.accountGroupId,
      setValue: (l, v) => l.copyWith(
        accountGroupId: v == null ? null : (v as AccountGroup).id,
      ),
      fkSearch: (query) async {
        final result =
            await _accountGroupRepository.list(PageQuery(search: query));
        return result.fold((_) => const [], (page) => page.items);
      },
      fkDisplayOf: (item) {
        final g = item as AccountGroup;
        final code = g.code;
        return (code == null || code.isEmpty) ? g.name : '$code — ${g.name}';
      },
      fkResolveById: (id) async {
        final result = await _accountGroupRepository.getById(id as int);
        return result.fold((_) => null, (g) => g);
      },
    ),
    FormFieldSpec<Ledger>(
      key: 'contactId',
      wireKey: 'contact_id',
      label: 'Contact',
      type: FieldType.fk,
      getValue: (l) => l.contactId,
      setValue: (l, v) => l.copyWith(
        contactId: v == null ? null : (v as AddressBook).id,
      ),
      fkSearch: (query) async {
        final result =
            await _addressBookRepository.list(PageQuery(search: query));
        return result.fold((_) => const [], (page) => page.items);
      },
      fkDisplayOf: (item) => (item as AddressBook).name,
      fkResolveById: (id) async {
        final result = await _addressBookRepository.getById(id as int);
        return result.fold((_) => null, (c) => c);
      },
    ),
    FormFieldSpec<Ledger>(
      key: 'currencyCode',
      wireKey: 'currency_code',
      label: 'Currency',
      type: FieldType.text,
      required: true,
      hintText: 'AED',
      getValue: (l) => l.currencyCode,
      setValue: (l, v) => l.copyWith(currencyCode: v as String?),
      validator: (v) {
        final s = v as String?;
        if (s == null || s.isEmpty) return 'Currency is required';
        if (s.length != 3) return 'Must be a 3-letter ISO code';
        return null;
      },
    ),
    FormFieldSpec<Ledger>(
      key: 'openingBalance',
      wireKey: 'Opening_Balance',
      label: 'Opening balance',
      type: FieldType.decimal,
      required: true,
      getValue: (l) => l.openingBalance,
      setValue: (l, v) => l.copyWith(
        openingBalance: (v as Decimal?) ?? Decimal.zero,
      ),
    ),
    FormFieldSpec<Ledger>(
      key: 'openingBalanceDate',
      wireKey: 'Opening_Balance_Date',
      label: 'Opening balance date',
      type: FieldType.dateTime,
      getValue: (l) => l.openingBalanceDate,
      setValue: (l, v) => l.copyWith(openingBalanceDate: v as DateTime?),
    ),
    FormFieldSpec<Ledger>(
      key: 'isSystemDefined',
      wireKey: 'is_system_defined',
      label: 'System defined',
      type: FieldType.bool,
      getValue: (l) => l.isSystemDefined,
      setValue: (l, v) => l.copyWith(isSystemDefined: v as bool?),
    ),
  ],
  emptyEntity: () => Ledger(
        id: 0,
        name: '',
        openingBalance: Decimal.zero,
      ),
);
