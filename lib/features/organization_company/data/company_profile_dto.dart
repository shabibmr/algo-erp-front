import 'package:equatable/equatable.dart';

/// Wire shape of companyprofile rows (PascalCase from Prisma) + snake_case
/// write body for `companyProfileSchema`.
class CompanyProfileDto extends Equatable {
  const CompanyProfileDto({
    required this.id,
    this.companyName,
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

  factory CompanyProfileDto.fromJson(Map<String, dynamic> json) =>
      CompanyProfileDto(
        id: _asInt(json['id']) ?? 0,
        companyName: json['Company_Name'] as String?,
        branch: json['Branch'] as String?,
        trn: json['TRN'] as String?,
        licenseNumber: json['License_Number'] as String?,
        fssaiLicense: json['FssaiLicense'] as String?,
        email: json['Email'] as String?,
        phoneNumber: json['Phone_Number'] as String?,
        mobileNumber: json['Mobile_Number'] as String?,
        website: json['WebSite'] as String?,
        building: json['Building'] as String?,
        street: json['Street'] as String?,
        addressLine: json['AddressLine'] as String?,
        city: json['City'] as String?,
        country: json['Country'] as String?,
        poBox: json['POBox'] as String?,
        location: json['Location'] as String?,
        currency: json['Currency'] as String?,
        currencyDecimal: _asInt(json['Currency_Decimal']) ?? 2,
      );

  static int? _asInt(Object? raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString());
  }

  final int id;
  final String? companyName;
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

  /// Matches `companyProfileSchema` (no Logo).
  /// Empty email/website are omitted so Zod `.email()` / `.url()` don't 400.
  Map<String, dynamic> toJson() => {
    if (companyName != null) 'company_name': companyName,
    if (branch != null) 'branch': branch,
    if (trn != null) 'trn': trn,
    if (licenseNumber != null) 'license_number': licenseNumber,
    if (fssaiLicense != null) 'fssai_license': fssaiLicense,
    if (email != null && email!.isNotEmpty) 'email': email,
    if (phoneNumber != null) 'phone_number': phoneNumber,
    if (mobileNumber != null) 'mobile_number': mobileNumber,
    if (website != null && website!.isNotEmpty) 'website': website,
    if (building != null) 'building': building,
    if (street != null) 'street': street,
    if (addressLine != null) 'address_line': addressLine,
    if (city != null) 'city': city,
    if (country != null) 'country': country,
    if (poBox != null) 'po_box': poBox,
    if (location != null) 'location': location,
    if (currency != null) 'currency': currency,
    'currency_decimal': currencyDecimal,
  };

  @override
  List<Object?> get props => [id, companyName, branch, trn, email];
}
