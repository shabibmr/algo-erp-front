import 'package:algo_erp_front/features/organization_address_book/data/address_book_dto.dart';
import 'package:algo_erp_front/features/organization_address_book/data/address_book_mapper.dart';
import 'package:algo_erp_front/features/organization_address_book/domain/address_book.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = AddressBookMapper();

  test("AddressBookDto.fromJson reads the backend's exact wire casing", () {
    final dto = AddressBookDto.fromJson(const {
      'id': 1,
      'contact_type': 'VENDOR',
      'Address_Id': 'A-001',
      'Name': 'Acme Supplies',
      'Designation': 'Manager',
      'Company_Name': 'Acme Corp',
      'Email': 'acme@example.com',
      'Phone_Number': '0123456789',
      'Mobile_Number': '9876543210',
      'Building': 'Tower 1',
      'Street': 'Main St',
      'City': 'Metropolis',
      'Country': 'Wonderland',
      'isActive': false,
    });

    expect(dto.id, 1);
    expect(dto.contactType, 'VENDOR');
    expect(dto.addressId, 'A-001');
    expect(dto.name, 'Acme Supplies');
    expect(dto.designation, 'Manager');
    expect(dto.companyName, 'Acme Corp');
    expect(dto.email, 'acme@example.com');
    expect(dto.phoneNumber, '0123456789');
    expect(dto.mobileNumber, '9876543210');
    expect(dto.building, 'Tower 1');
    expect(dto.street, 'Main St');
    expect(dto.city, 'Metropolis');
    expect(dto.country, 'Wonderland');
    expect(dto.isActive, false);
  });

  test('AddressBookDto.fromJson defaults isActive to true when absent', () {
    final dto = AddressBookDto.fromJson(const {
      'id': 1,
      'contact_type': 'INDIVIDUAL',
      'Address_Id': 'A-002',
      'Name': 'Jane Doe',
    });

    expect(dto.isActive, true);
    expect(dto.designation, isNull);
    expect(dto.email, isNull);
  });

  test('AddressBookMapper.toEntity maps dto fields to entity fields', () {
    const dto = AddressBookDto(
      id: 1,
      contactType: 'VENDOR',
      addressId: 'A-001',
      name: 'Acme Supplies',
      designation: 'Manager',
      companyName: 'Acme Corp',
      email: 'acme@example.com',
      phoneNumber: '0123456789',
      mobileNumber: '9876543210',
      building: 'Tower 1',
      street: 'Main St',
      city: 'Metropolis',
      country: 'Wonderland',
      isActive: false,
    );

    expect(
      mapper.toEntity(dto),
      const AddressBook(
        id: 1,
        contactType: 'VENDOR',
        addressId: 'A-001',
        name: 'Acme Supplies',
        designation: 'Manager',
        companyName: 'Acme Corp',
        email: 'acme@example.com',
        phoneNumber: '0123456789',
        mobileNumber: '9876543210',
        building: 'Tower 1',
        street: 'Main St',
        city: 'Metropolis',
        country: 'Wonderland',
        isActive: false,
      ),
    );
  });

  test('AddressBookMapper.toDto round-trips back to the wire shape '
      '(omitting isActive)', () {
    const contact = AddressBook(
      id: 1,
      contactType: 'INDIVIDUAL',
      addressId: 'A-002',
      name: 'Jane Doe',
      email: 'jane@example.com',
    );

    expect(mapper.toDto(contact).toJson(), {
      'contact_type': 'INDIVIDUAL',
      'Address_Id': 'A-002',
      'Name': 'Jane Doe',
      'Designation': null,
      'Company_Name': null,
      'Email': 'jane@example.com',
      'Phone_Number': null,
      'Mobile_Number': null,
      'Building': null,
      'Street': null,
      'City': null,
      'Country': null,
    });
  });

  test('round-trip toEntity(toDto(x)) is identity', () {
    const contact = AddressBook(
      id: 5,
      contactType: 'COMPANY',
      addressId: 'A-003',
      name: 'Beta Traders',
      city: 'Gotham',
      isActive: false,
    );
    expect(mapper.toEntity(mapper.toDto(contact)), contact);
  });
}
