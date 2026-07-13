import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_form_surface.dart';
import 'package:algo_erp_front/core/widgets/fields/app_text_field.dart';
import 'package:algo_erp_front/core/widgets/states/error_state.dart';
import 'package:algo_erp_front/core/widgets/states/loading_state.dart';
import 'package:algo_erp_front/features/organization_address_book/address_book_di.dart';
import 'package:algo_erp_front/features/organization_address_book/address_book_manifest.dart';
import 'package:algo_erp_front/features/organization_address_book/bloc/address_book_form_bloc.dart';
import 'package:algo_erp_front/features/organization_address_book/bloc/address_book_form_event.dart';
import 'package:algo_erp_front/features/organization_address_book/bloc/address_book_form_state.dart';
import 'package:algo_erp_front/features/organization_address_book/domain/address_book.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AddressBookFormPage extends StatelessWidget {
  const AddressBookFormPage({required this.mode, super.key, this.entityId});

  final FormMode mode;
  final int? entityId;

  @override
  Widget build(BuildContext context) {
    final dio = getIt<DioClient>();
    return BlocProvider<AddressBookFormBloc>(
      create: (_) =>
          AddressBookFormBloc(repository: createAddressBookRepository(dio))
            ..add(AddressBookFormInitialized(entityId: entityId)),
      child: BlocListener<AddressBookFormBloc, AddressBookFormState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: (context, state) {
          if (state.isSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.isEdit
                      ? 'Contact updated successfully'
                      : 'Contact created successfully',
                ),
              ),
            );
            context.go(addressBookManifest.resourcePath);
          }
        },
        child: const _AddressBookFormView(),
      ),
    );
  }
}

class _AddressBookFormView extends StatelessWidget {
  const _AddressBookFormView();

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      child: BlocBuilder<AddressBookFormBloc, AddressBookFormState>(
        builder: (context, state) {
          final bloc = context.read<AddressBookFormBloc>();

          if (state.isLoading) {
            return const LoadingState();
          }
          if (state.status == AddressBookFormStatus.failure) {
            return ErrorState(
              failure:
                  state.failure ??
                  const Failure.unknown('Failed to load contact'),
              onRetry: () => bloc.add(
                AddressBookFormInitialized(entityId: state.entityId),
              ),
            );
          }

          final title = state.isEdit ? 'Edit Contact' : 'New Contact';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () =>
                        context.go(addressBookManifest.resourcePath),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (state.errorMessage != null) ...[
                Text(
                  state.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 12),
              ],
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: state.contactType,
                        decoration: const InputDecoration(
                          labelText: 'Contact Type',
                        ),
                        items: [
                          for (final type in AddressBook.contactTypes)
                            DropdownMenuItem(value: type, child: Text(type)),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            bloc.add(AddressBookFormContactTypeChanged(v));
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Name',
                        value: state.name,
                        onChanged: (v) =>
                            bloc.add(AddressBookFormNameChanged(v)),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Company Name',
                        value: state.companyName,
                        onChanged: (v) =>
                            bloc.add(AddressBookFormCompanyNameChanged(v)),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Email Address',
                        value: state.email,
                        onChanged: (v) =>
                            bloc.add(AddressBookFormEmailChanged(v)),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Phone Number',
                        value: state.phoneNumber,
                        onChanged: (v) =>
                            bloc.add(AddressBookFormPhoneChanged(v)),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Mobile Number',
                        value: state.mobileNumber,
                        onChanged: (v) =>
                            bloc.add(AddressBookFormMobileChanged(v)),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: state.isSubmitting
                                ? null
                                : () => context.go(
                                    addressBookManifest.resourcePath,
                                  ),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: state.isSubmitting
                                ? null
                                : () => bloc.add(
                                    const AddressBookFormSubmitted(),
                                  ),
                            child: state.isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Save'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
