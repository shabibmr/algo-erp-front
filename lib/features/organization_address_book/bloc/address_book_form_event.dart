import 'package:equatable/equatable.dart';

sealed class AddressBookFormEvent extends Equatable {
  const AddressBookFormEvent();

  @override
  List<Object?> get props => [];
}

final class AddressBookFormInitialized extends AddressBookFormEvent {
  const AddressBookFormInitialized({this.entityId});
  final int? entityId;

  @override
  List<Object?> get props => [entityId];
}

final class AddressBookFormContactTypeChanged extends AddressBookFormEvent {
  const AddressBookFormContactTypeChanged(this.contactType);
  final String contactType;

  @override
  List<Object?> get props => [contactType];
}

final class AddressBookFormNameChanged extends AddressBookFormEvent {
  const AddressBookFormNameChanged(this.name);
  final String name;

  @override
  List<Object?> get props => [name];
}

final class AddressBookFormEmailChanged extends AddressBookFormEvent {
  const AddressBookFormEmailChanged(this.email);
  final String email;

  @override
  List<Object?> get props => [email];
}

final class AddressBookFormPhoneChanged extends AddressBookFormEvent {
  const AddressBookFormPhoneChanged(this.phone);
  final String phone;

  @override
  List<Object?> get props => [phone];
}

final class AddressBookFormMobileChanged extends AddressBookFormEvent {
  const AddressBookFormMobileChanged(this.mobile);
  final String mobile;

  @override
  List<Object?> get props => [mobile];
}

final class AddressBookFormCompanyNameChanged extends AddressBookFormEvent {
  const AddressBookFormCompanyNameChanged(this.companyName);
  final String companyName;

  @override
  List<Object?> get props => [companyName];
}

final class AddressBookFormSubmitted extends AddressBookFormEvent {
  const AddressBookFormSubmitted();
}
