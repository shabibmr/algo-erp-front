import 'package:algo_erp_front/core/manifest/entity_manifest.dart';
import 'package:algo_erp_front/core/manifest/field_spec.dart';
import 'package:algo_erp_front/core/manifest/form_field_spec.dart';
import 'package:algo_erp_front/features/organization_address_book/domain/address_book.dart';

/// AddressBook's manifest. `rbacModule` is `'AddressBook'` — Organization gates
/// per entity (`organization.routes.ts`). Soft delete (via the `isActive`
/// column), so the default `hardDelete: false` stands.
///
/// `contactType` reuses `FieldType.text` plus a validator restricting it to the
/// backend's 5 allowed values — see the entity's doc comment for why this isn't
/// a new `FieldType.enum` yet.
final addressBookManifest = EntityManifest<AddressBook>(
  id: 'address-book',
  label: 'Contact',
  rbacModule: 'AddressBook',
  resourcePath: '/organization/contacts',
  listColumns: [
    FieldSpec<AddressBook>(
      key: 'name',
      label: 'Name',
      type: FieldType.text,
      required: true,
      cellValue: (c) => c.name,
    ),
    FieldSpec<AddressBook>(
      key: 'contactType',
      label: 'Type',
      type: FieldType.text,
      required: true,
      cellValue: (c) => c.contactType,
    ),
    FieldSpec<AddressBook>(
      key: 'companyName',
      label: 'Company',
      type: FieldType.text,
      cellValue: (c) => c.companyName ?? '—',
    ),
    FieldSpec<AddressBook>(
      key: 'email',
      label: 'Email',
      type: FieldType.text,
      cellValue: (c) => c.email ?? '—',
    ),
  ],
  searchFields: const ['name', 'companyName', 'email'],
  formFields: [
    FormFieldSpec<AddressBook>(
      key: 'name',
      wireKey: 'Name',
      label: 'Name',
      type: FieldType.text,
      required: true,
      getValue: (c) => c.name,
      setValue: (c, v) => c.copyWith(name: v as String?),
    ),
    FormFieldSpec<AddressBook>(
      key: 'contactType',
      wireKey: 'contact_type',
      label: 'Type',
      type: FieldType.text,
      required: true,
      hintText: 'INDIVIDUAL',
      helperText: 'One of: ${AddressBook.contactTypes.join(', ')}',
      getValue: (c) => c.contactType,
      setValue: (c, v) => c.copyWith(contactType: v as String?),
      validator: (v) {
        final text = v as String?;
        if (text == null || text.isEmpty) return null;
        return AddressBook.contactTypes.contains(text)
            ? null
            : 'Must be one of: ${AddressBook.contactTypes.join(', ')}';
      },
    ),
    FormFieldSpec<AddressBook>(
      key: 'designation',
      wireKey: 'Designation',
      label: 'Designation',
      type: FieldType.text,
      getValue: (c) => c.designation,
      setValue: (c, v) => c.copyWith(designation: v),
    ),
    FormFieldSpec<AddressBook>(
      key: 'companyName',
      wireKey: 'Company_Name',
      label: 'Company',
      type: FieldType.text,
      getValue: (c) => c.companyName,
      setValue: (c, v) => c.copyWith(companyName: v),
    ),
    FormFieldSpec<AddressBook>(
      key: 'email',
      wireKey: 'Email',
      label: 'Email',
      type: FieldType.text,
      getValue: (c) => c.email,
      setValue: (c, v) => c.copyWith(email: v),
      // addressBookSchema: z.string().email().optional().or(z.literal(''))
      validator: (v) {
        final text = v as String?;
        if (text == null || text.isEmpty) return null;
        final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text);
        return valid ? null : 'Enter a valid email';
      },
    ),
    FormFieldSpec<AddressBook>(
      key: 'phoneNumber',
      wireKey: 'Phone_Number',
      label: 'Phone',
      type: FieldType.text,
      getValue: (c) => c.phoneNumber,
      setValue: (c, v) => c.copyWith(phoneNumber: v),
    ),
    FormFieldSpec<AddressBook>(
      key: 'mobileNumber',
      wireKey: 'Mobile_Number',
      label: 'Mobile',
      type: FieldType.text,
      getValue: (c) => c.mobileNumber,
      setValue: (c, v) => c.copyWith(mobileNumber: v),
    ),
    FormFieldSpec<AddressBook>(
      key: 'building',
      wireKey: 'Building',
      label: 'Building',
      type: FieldType.text,
      getValue: (c) => c.building,
      setValue: (c, v) => c.copyWith(building: v),
    ),
    FormFieldSpec<AddressBook>(
      key: 'street',
      wireKey: 'Street',
      label: 'Street',
      type: FieldType.text,
      getValue: (c) => c.street,
      setValue: (c, v) => c.copyWith(street: v),
    ),
    FormFieldSpec<AddressBook>(
      key: 'city',
      wireKey: 'City',
      label: 'City',
      type: FieldType.text,
      getValue: (c) => c.city,
      setValue: (c, v) => c.copyWith(city: v),
    ),
    FormFieldSpec<AddressBook>(
      key: 'country',
      wireKey: 'Country',
      label: 'Country',
      type: FieldType.text,
      getValue: (c) => c.country,
      setValue: (c, v) => c.copyWith(country: v),
    ),
  ],
  emptyEntity: () => const AddressBook(
    id: 0,
    contactType: 'INDIVIDUAL',
    addressId: '',
    name: '',
  ),
);
