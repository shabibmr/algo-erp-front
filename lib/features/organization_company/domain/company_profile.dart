import 'package:equatable/equatable.dart';

const _unset = Object();

/// Company profile (org hard case). Logo is binary server-side and is
/// intentionally out-of-band on this form — text fields only.
class CompanyProfile extends Equatable {
  const CompanyProfile({
    required this.id,
    this.name,
    this.branch,
    this.trn,
    this.licenseNumber,
    this.fssaiLicense,
    this.email,
    this.phoneNumber,
    this.mobileNumber,
    this.website,
    this.building,
    this.street,
    this.addressLine,
    this.city,
    this.country,
    this.poBox,
    this.location,
    this.currency,
    this.currencyDecimal = 2,
  });

  final int id;
  final String? name;
  final String? branch;
  final String? trn;
  final String? licenseNumber;
  final String? fssaiLicense;
  final String? email;
  final String? phoneNumber;
  final String? mobileNumber;
  final String? website;
  final String? building;
  final String? street;
  final String? addressLine;
  final String? city;
  final String? country;
  final String? poBox;
  final String? location;
  final String? currency;
  final int currencyDecimal;

  CompanyProfile copyWith({
    int? id,
    Object? name = _unset,
    Object? branch = _unset,
    Object? trn = _unset,
    Object? licenseNumber = _unset,
    Object? fssaiLicense = _unset,
    Object? email = _unset,
    Object? phoneNumber = _unset,
    Object? mobileNumber = _unset,
    Object? website = _unset,
    Object? building = _unset,
    Object? street = _unset,
    Object? addressLine = _unset,
    Object? city = _unset,
    Object? country = _unset,
    Object? poBox = _unset,
    Object? location = _unset,
    Object? currency = _unset,
    int? currencyDecimal,
  }) => CompanyProfile(
    id: id ?? this.id,
    name: identical(name, _unset) ? this.name : name as String?,
    branch: identical(branch, _unset) ? this.branch : branch as String?,
    trn: identical(trn, _unset) ? this.trn : trn as String?,
    licenseNumber: identical(licenseNumber, _unset)
        ? this.licenseNumber
        : licenseNumber as String?,
    fssaiLicense: identical(fssaiLicense, _unset)
        ? this.fssaiLicense
        : fssaiLicense as String?,
    email: identical(email, _unset) ? this.email : email as String?,
    phoneNumber: identical(phoneNumber, _unset)
        ? this.phoneNumber
        : phoneNumber as String?,
    mobileNumber: identical(mobileNumber, _unset)
        ? this.mobileNumber
        : mobileNumber as String?,
    website: identical(website, _unset) ? this.website : website as String?,
    building: identical(building, _unset) ? this.building : building as String?,
    street: identical(street, _unset) ? this.street : street as String?,
    addressLine: identical(addressLine, _unset)
        ? this.addressLine
        : addressLine as String?,
    city: identical(city, _unset) ? this.city : city as String?,
    country: identical(country, _unset) ? this.country : country as String?,
    poBox: identical(poBox, _unset) ? this.poBox : poBox as String?,
    location: identical(location, _unset) ? this.location : location as String?,
    currency: identical(currency, _unset) ? this.currency : currency as String?,
    currencyDecimal: currencyDecimal ?? this.currencyDecimal,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    branch,
    trn,
    licenseNumber,
    fssaiLicense,
    email,
    phoneNumber,
    mobileNumber,
    website,
    building,
    street,
    addressLine,
    city,
    country,
    poBox,
    location,
    currency,
    currencyDecimal,
  ];
}
