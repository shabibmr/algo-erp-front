import 'package:equatable/equatable.dart';

/// Wire shape of `/organization/contacts`, matching the backend `address_book`
/// table. Nearly every column is PascalCase (`Name`, `Company_Name`, …) while
/// `contact_type` is snake_case and the soft-delete flag is `isActive` — the
/// casing is preserved verbatim rather than normalised, per
/// `feature-contract.md`.
class AddressBookDto extends Equatable {
  const AddressBookDto({
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

  factory AddressBookDto.fromJson(Map<String, dynamic> json) => AddressBookDto(
        id: json['id'] as int,
        contactType: json['contact_type'] as String,
        addressId: json['Address_Id'] as String,
        name: json['Name'] as String,
        designation: json['Designation'] as String?,
        companyName: json['Company_Name'] as String?,
        email: json['Email'] as String?,
        phoneNumber: json['Phone_Number'] as String?,
        mobileNumber: json['Mobile_Number'] as String?,
        building: json['Building'] as String?,
        street: json['Street'] as String?,
        city: json['City'] as String?,
        country: json['Country'] as String?,
        isActive: json['isActive'] as bool? ?? true,
      );

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

  /// `id`/timestamps are server-generated and never sent on write; `isActive`
  /// is the soft-delete flag, owned by `DELETE`. `addressBookSchema` accepts
  /// only the keys below.
  Map<String, dynamic> toJson() => {
        'contact_type': contactType,
        'Address_Id': addressId,
        'Name': name,
        'Designation': designation,
        'Company_Name': companyName,
        'Email': email,
        'Phone_Number': phoneNumber,
        'Mobile_Number': mobileNumber,
        'Building': building,
        'Street': street,
        'City': city,
        'Country': country,
      };

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
