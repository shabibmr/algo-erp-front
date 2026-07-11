import 'package:equatable/equatable.dart';

const _unset = Object();

/// The AddressBook (contact) master entity — soft-deleted
/// (`AddressBookRepository` sets `softDeleteField: 'isActive'`; note the camel
/// case, which is the actual column name, unlike every other table's
/// `is_active`).
///
/// [contactType] is a 5-value backend enum, but is modeled as a plain `String`
/// with a manifest-level validator rather than a `FieldType.enum`: this is only
/// the second entity to want one (after UOMConversion's numeric-string field
/// reused `FieldType.text` the same way), and two occurrences isn't yet enough
/// pressure to justify a new field type and picker widget. A third should be.
class AddressBook extends Equatable {
  const AddressBook({
    required this.id,
    required this.contactType,
    required this.addressId,
    required this.name,
    this.designation,
    this.companyName,
    this.email,
    this.phoneNumber,
    this.mobileNumber,
    this.building,
    this.street,
    this.city,
    this.country,
    this.isActive = true,
  });

  /// The values `addressBookSchema`'s `z.enum([...])` accepts.
  static const contactTypes = [
    'INDIVIDUAL',
    'COMPANY',
    'VENDOR',
    'EMPLOYEE',
    'OTHER',
  ];

  final int id;
  final String contactType;
  final String addressId;
  final String name;
  final String? designation;
  final String? companyName;
  final String? email;
  final String? phoneNumber;
  final String? mobileNumber;
  final String? building;
  final String? street;
  final String? city;
  final String? country;
  final bool isActive;

  AddressBook copyWith({
    int? id,
    String? contactType,
    String? addressId,
    String? name,
    Object? designation = _unset,
    Object? companyName = _unset,
    Object? email = _unset,
    Object? phoneNumber = _unset,
    Object? mobileNumber = _unset,
    Object? building = _unset,
    Object? street = _unset,
    Object? city = _unset,
    Object? country = _unset,
    bool? isActive,
  }) =>
      AddressBook(
        id: id ?? this.id,
        contactType: contactType ?? this.contactType,
        addressId: addressId ?? this.addressId,
        name: name ?? this.name,
        designation: identical(designation, _unset)
            ? this.designation
            : designation as String?,
        companyName: identical(companyName, _unset)
            ? this.companyName
            : companyName as String?,
        email: identical(email, _unset) ? this.email : email as String?,
        phoneNumber: identical(phoneNumber, _unset)
            ? this.phoneNumber
            : phoneNumber as String?,
        mobileNumber: identical(mobileNumber, _unset)
            ? this.mobileNumber
            : mobileNumber as String?,
        building:
            identical(building, _unset) ? this.building : building as String?,
        street: identical(street, _unset) ? this.street : street as String?,
        city: identical(city, _unset) ? this.city : city as String?,
        country: identical(country, _unset) ? this.country : country as String?,
        isActive: isActive ?? this.isActive,
      );

  @override
  List<Object?> get props => [
        id,
        contactType,
        addressId,
        name,
        designation,
        companyName,
        email,
        phoneNumber,
        mobileNumber,
        building,
        street,
        city,
        country,
        isActive,
      ];
}
