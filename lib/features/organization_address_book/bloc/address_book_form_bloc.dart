import 'package:algo_erp_front/core/domain/repository.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/features/organization_address_book/bloc/address_book_form_event.dart';
import 'package:algo_erp_front/features/organization_address_book/bloc/address_book_form_state.dart';
import 'package:algo_erp_front/features/organization_address_book/domain/address_book.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddressBookFormBloc
    extends Bloc<AddressBookFormEvent, AddressBookFormState> {
  AddressBookFormBloc({required Repository<AddressBook, int> repository})
    : _repository = repository,
      super(const AddressBookFormState()) {
    on<AddressBookFormInitialized>(_onInitialized);
    on<AddressBookFormContactTypeChanged>(_onContactTypeChanged);
    on<AddressBookFormNameChanged>(_onNameChanged);
    on<AddressBookFormEmailChanged>(_onEmailChanged);
    on<AddressBookFormPhoneChanged>(_onPhoneChanged);
    on<AddressBookFormMobileChanged>(_onMobileChanged);
    on<AddressBookFormCompanyNameChanged>(_onCompanyNameChanged);
    on<AddressBookFormSubmitted>(_onSubmitted);
  }

  final Repository<AddressBook, int> _repository;

  Future<void> _onInitialized(
    AddressBookFormInitialized event,
    Emitter<AddressBookFormState> emit,
  ) async {
    if (event.entityId == null) {
      emit(state.copyWith(status: AddressBookFormStatus.ready, isEdit: false));
      return;
    }

    emit(
      state.copyWith(
        status: AddressBookFormStatus.loading,
        entityId: event.entityId,
        isEdit: true,
      ),
    );

    final result = await _repository.getById(event.entityId!);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AddressBookFormStatus.failure,
          failure: () => failure,
        ),
      ),
      (contact) => emit(
        state.copyWith(
          status: AddressBookFormStatus.ready,
          contactType: contact.contactType,
          addressId: contact.addressId,
          name: contact.name,
          email: contact.email ?? '',
          phoneNumber: contact.phoneNumber ?? '',
          mobileNumber: contact.mobileNumber ?? '',
          companyName: contact.companyName ?? '',
        ),
      ),
    );
  }

  void _onContactTypeChanged(
    AddressBookFormContactTypeChanged event,
    Emitter<AddressBookFormState> emit,
  ) {
    emit(state.copyWith(contactType: event.contactType));
  }

  void _onNameChanged(
    AddressBookFormNameChanged event,
    Emitter<AddressBookFormState> emit,
  ) {
    emit(state.copyWith(name: event.name));
  }

  void _onEmailChanged(
    AddressBookFormEmailChanged event,
    Emitter<AddressBookFormState> emit,
  ) {
    emit(state.copyWith(email: event.email));
  }

  void _onPhoneChanged(
    AddressBookFormPhoneChanged event,
    Emitter<AddressBookFormState> emit,
  ) {
    emit(state.copyWith(phoneNumber: event.phone));
  }

  void _onMobileChanged(
    AddressBookFormMobileChanged event,
    Emitter<AddressBookFormState> emit,
  ) {
    emit(state.copyWith(mobileNumber: event.mobile));
  }

  void _onCompanyNameChanged(
    AddressBookFormCompanyNameChanged event,
    Emitter<AddressBookFormState> emit,
  ) {
    emit(state.copyWith(companyName: event.companyName));
  }

  Future<void> _onSubmitted(
    AddressBookFormSubmitted event,
    Emitter<AddressBookFormState> emit,
  ) async {
    if (state.name.trim().isEmpty) {
      emit(state.copyWith(errorMessage: () => 'Name is required'));
      return;
    }

    emit(
      state.copyWith(
        status: AddressBookFormStatus.submitting,
        errorMessage: () => null,
      ),
    );

    final contact = AddressBook(
      id: state.entityId ?? 0,
      contactType: state.contactType,
      addressId: state.addressId.isEmpty ? 'ADDR-01' : state.addressId,
      name: state.name.trim(),
      email: state.email.trim().isEmpty ? null : state.email.trim(),
      phoneNumber: state.phoneNumber.trim().isEmpty
          ? null
          : state.phoneNumber.trim(),
      mobileNumber: state.mobileNumber.trim().isEmpty
          ? null
          : state.mobileNumber.trim(),
      companyName: state.companyName.trim().isEmpty
          ? null
          : state.companyName.trim(),
    );

    if (state.isEdit) {
      final result = await _repository.update(state.entityId!, contact);
      result.fold(
        (failure) => emit(
          state.copyWith(
            status: AddressBookFormStatus.ready,
            errorMessage: () => _messageOf(failure),
          ),
        ),
        (_) => emit(state.copyWith(status: AddressBookFormStatus.success)),
      );
      return;
    }

    final result = await _repository.create(contact);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AddressBookFormStatus.ready,
          errorMessage: () => _messageOf(failure),
        ),
      ),
      (_) => emit(state.copyWith(status: AddressBookFormStatus.success)),
    );
  }

  String _messageOf(Failure f) => switch (f) {
    NetworkFailure(:final message) => message,
    ValidationFailure(:final message) => message,
    ForbiddenFailure(:final message) => message,
    ServerFailure(:final message) => message,
    _ => f.toString(),
  };
}
