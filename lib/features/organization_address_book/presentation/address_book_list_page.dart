import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:algo_erp_front/core/auth/permission_gate.dart';
import 'package:algo_erp_front/core/di/injection.dart';
import 'package:algo_erp_front/core/error/failure.dart';
import 'package:algo_erp_front/core/network/dio_client.dart';
import 'package:algo_erp_front/core/responsive/adaptive_layout.dart';
import 'package:algo_erp_front/core/widgets/dialogs/confirm_dialog.dart';
import 'package:algo_erp_front/core/widgets/fields/app_text_field.dart';
import 'package:algo_erp_front/core/widgets/states/empty_state.dart';
import 'package:algo_erp_front/core/widgets/states/error_state.dart';
import 'package:algo_erp_front/core/widgets/states/loading_state.dart';
import 'package:algo_erp_front/features/organization_address_book/address_book_di.dart';
import 'package:algo_erp_front/features/organization_address_book/address_book_manifest.dart';
import 'package:algo_erp_front/features/organization_address_book/bloc/address_book_list_bloc.dart';
import 'package:algo_erp_front/features/organization_address_book/bloc/address_book_list_event.dart';
import 'package:algo_erp_front/features/organization_address_book/bloc/address_book_list_state.dart';
import 'package:algo_erp_front/features/organization_address_book/domain/address_book.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AddressBookListPage extends StatelessWidget {
  const AddressBookListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dio = getIt<DioClient>();
    return BlocProvider<AddressBookListBloc>(
      create: (_) =>
          AddressBookListBloc(repository: createAddressBookRepository(dio))
            ..add(const AddressBookListFetchRequested()),
      child: BlocListener<AddressBookListBloc, AddressBookListState>(
        listenWhen: (prev, curr) => prev.actionMessage != curr.actionMessage,
        listener: (context, state) {
          if (state.actionMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.actionMessage!)));
          }
        },
        child: const _AddressBookListView(),
      ),
    );
  }
}

class _AddressBookListView extends StatelessWidget {
  const _AddressBookListView();

  Future<void> _delete(BuildContext context, AddressBook item) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete ${item.name}?',
      message: 'This will deactivate the contact record.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (ok && context.mounted) {
      context.read<AddressBookListBloc>().add(AddressBookItemDeleted(item.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      child: BlocBuilder<AddressBookListBloc, AddressBookListState>(
        builder: (context, state) {
          final bloc = context.read<AddressBookListBloc>();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      addressBookManifest.label,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  PermissionGate(
                    module: addressBookManifest.rbacModule,
                    action: PermissionAction.create,
                    child: FilledButton.icon(
                      onPressed: () =>
                          context.push('/organization/contacts/new'),
                      icon: const Icon(Icons.add),
                      label: const Text('New Contact'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 300,
                child: AppTextField(
                  label: 'Search Contacts',
                  value: state.search,
                  onChanged: (v) => bloc.add(AddressBookListSearchChanged(v)),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildListContent(context, state, bloc)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildListContent(
    BuildContext context,
    AddressBookListState state,
    AddressBookListBloc bloc,
  ) {
    if (state.isLoading) {
      return const LoadingState();
    }
    if (state.isFailure) {
      return ErrorState(
        failure:
            state.failure ?? const Failure.unknown('Failed to load contacts'),
        onRetry: () => bloc.add(const AddressBookListFetchRequested()),
      );
    }
    if (state.items.isEmpty) {
      return EmptyState(
        message: 'No contacts found',
        actionLabel: 'New Contact',
        onAction: () => context.push('/organization/contacts/new'),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => bloc.add(const AddressBookListRefreshed()),
      child: ListView.separated(
        itemCount: state.items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final item = state.items[i];
          return ListTile(
            title: Text(item.name),
            subtitle: Text(
              [
                'Type: ${item.contactType}',
                if (item.companyName != null && item.companyName!.isNotEmpty)
                  item.companyName!,
                if (item.email != null && item.email!.isNotEmpty) item.email!,
                if (item.mobileNumber != null && item.mobileNumber!.isNotEmpty)
                  item.mobileNumber!,
              ].join(' · '),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () =>
                      context.push('/organization/contacts/${item.id}'),
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(context, item),
                ),
              ],
            ),
            onTap: () => context.push('/organization/contacts/${item.id}'),
          );
        },
      ),
    );
  }
}
