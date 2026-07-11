import 'package:algo_erp_front/core/data/mapper.dart';
import 'package:algo_erp_front/features/organization_address_book/data/address_book_dto.dart';
import 'package:algo_erp_front/features/organization_address_book/domain/address_book.dart';

class AddressBookMapper implements Mapper<AddressBookDto, AddressBook> {
  const AddressBookMapper();

  @override
  AddressBook toEntity(AddressBookDto dto) => AddressBook(
        id: dto.id,
        contactType: dto.contactType,
        addressId: dto.addressId,
        name: dto.name,
        designation: dto.designation,
        companyName: dto.companyName,
        email: dto.email,
        phoneNumber: dto.phoneNumber,
        mobileNumber: dto.mobileNumber,
        building: dto.building,
        street: dto.street,
        city: dto.city,
        country: dto.country,
        isActive: dto.isActive,
      );

  @override
  AddressBookDto toDto(AddressBook entity) => AddressBookDto(
        id: entity.id,
        contactType: entity.contactType,
        addressId: entity.addressId,
        name: entity.name,
        designation: entity.designation,
        companyName: entity.companyName,
        email: entity.email,
        phoneNumber: entity.phoneNumber,
        mobileNumber: entity.mobileNumber,
        building: entity.building,
        street: entity.street,
        city: entity.city,
        country: entity.country,
        isActive: entity.isActive,
      );
}
