import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/surfaces/master_form_surface.dart';
import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/core/widgets/fields/app_text_field.dart';
import 'package:algo_erp_front/core/widgets/layout/field_widths.dart';
import 'package:algo_erp_front/core/widgets/layout/form_field_layout.dart';
import 'package:algo_erp_front/core/widgets/layout/page_header.dart';
import 'package:algo_erp_front/core/widgets/layout/work_sheet.dart';
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
    final tokens = context.tokens;
    final gap = SizedBox(height: tokens.spacing.md);

    return AdaptiveLayout(
      maxContentWidth: FieldWidths.formContent,
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                eyebrow: addressBookManifest.eyebrowText,
                title: title,
                actions: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () =>
                        context.go(addressBookManifest.resourcePath),
                    icon: const Icon(Icons.arrow_back),
                  ),
                ],
              ),
              SizedBox(height: tokens.spacing.md),
              if (state.errorMessage != null) ...[
                Text(
                  state.errorMessage!,
                  style: TextStyle(color: tokens.semanticColors.danger),
                ),
                gap,
              ],
              WorkSheet(
                fill: false,
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.spacing.md,
                  vertical: tokens.spacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    constrainFormField(
                      DropdownButtonFormField<String>(
                        initialValue: state.contactType,
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
                      maxWidth: FieldWidths.dropdown,
                    ),
                    gap,
                    AppTextField(
                      label: 'Name',
                      value: state.name,
                      onChanged: (v) =>
                          bloc.add(AddressBookFormNameChanged(v)),
                    ),
                    gap,
                    AppTextField(
                      label: 'Company Name',
                      value: state.companyName,
                      onChanged: (v) =>
                          bloc.add(AddressBookFormCompanyNameChanged(v)),
                    ),
                    gap,
                    AppTextField(
                      label: 'Email Address',
                      value: state.email,
                      onChanged: (v) =>
                          bloc.add(AddressBookFormEmailChanged(v)),
                    ),
                    gap,
                    constrainFormField(
                      AppTextField(
                        label: 'Phone Number',
                        value: state.phoneNumber,
                        onChanged: (v) =>
                            bloc.add(AddressBookFormPhoneChanged(v)),
                      ),
                      maxWidth: FieldWidths.textShort,
                    ),
                    gap,
                    constrainFormField(
                      AppTextField(
                        label: 'Mobile Number',
                        value: state.mobileNumber,
                        onChanged: (v) =>
                            bloc.add(AddressBookFormMobileChanged(v)),
                      ),
                      maxWidth: FieldWidths.textShort,
                    ),
                    SizedBox(height: tokens.spacing.lg),
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
                        SizedBox(width: tokens.spacing.sm),
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
            ],
          );
        },
      ),
    );
  }
}
