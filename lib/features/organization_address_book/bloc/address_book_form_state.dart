import 'package:algo_erp_front/core/error/failure.dart';
import 'package:equatable/equatable.dart';

enum AddressBookFormStatus {
  initial,
  loading,
  ready,
  submitting,
  success,
  failure,
}

final class AddressBookFormState extends Equatable {
  const AddressBookFormState({
    this.status = AddressBookFormStatus.initial,
    this.entityId,
    this.isEdit = false,
    this.contactType = 'INDIVIDUAL',
    this.addressId = '',
    this.name = '',
    this.email = '',
    this.phoneNumber = '',
    this.mobileNumber = '',
    this.companyName = '',
    this.errorMessage,
    this.failure,
  });

  final AddressBookFormStatus status;
  final int? entityId;
  final bool isEdit;
  final String contactType;
  final String addressId;
  final String name;
  final String email;
  final String phoneNumber;
  final String mobileNumber;
  final String companyName;
  final String? errorMessage;
  final Failure? failure;

  bool get isLoading => status == AddressBookFormStatus.loading;
  bool get isSubmitting => status == AddressBookFormStatus.submitting;
  bool get isSuccess => status == AddressBookFormStatus.success;

  AddressBookFormState copyWith({
    AddressBookFormStatus? status,
    int? entityId,
    bool? isEdit,
    String? contactType,
    String? addressId,
    String? name,
    String? email,
    String? phoneNumber,
    String? mobileNumber,
    String? companyName,
    String? Function()? errorMessage,
    Failure? Function()? failure,
  }) {
    return AddressBookFormState(
      status: status ?? this.status,
      entityId: entityId ?? this.entityId,
      isEdit: isEdit ?? this.isEdit,
      contactType: contactType ?? this.contactType,
      addressId: addressId ?? this.addressId,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      companyName: companyName ?? this.companyName,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      failure: failure != null ? failure() : this.failure,
    );
  }

  @override
  List<Object?> get props => [
    status,
    entityId,
    isEdit,
    contactType,
    addressId,
    name,
    email,
    phoneNumber,
    mobileNumber,
    companyName,
    errorMessage,
    failure,
  ];
}
