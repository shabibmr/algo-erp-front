import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/core/widgets/lookup/fk_lookup_cubit.dart';
import 'package:algo_erp_front/core/widgets/states/empty_state.dart';
import 'package:algo_erp_front/core/widgets/states/loading_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Default idle time before a keystroke triggers [FkLookupField.loader].
const kFkLookupDebounce = Duration(milliseconds: 350);

/// A foreign-key picker: a read-only field that opens a searchable dialog
/// backed by an async [loader] (typically a repository's `list` call with a
/// `PageQuery.search` term). Generic over the looked-up entity `T` so one
/// widget serves every FK relationship in the app (brand picker, account
/// picker, employee picker, ...).
///
/// The query is debounced via [FkLookupCubit], so fast typing issues one
/// request instead of one per keystroke.
///
/// ```dart
/// FkLookupField<Brand>(
///   label: 'Brand',
///   value: selectedBrand,
///   displayOf: (b) => b.name,
///   loader: (query) => brandRepository.search(query),
///   onSelected: (b) => context.read<MyCubit>().setBrand(b),
/// )
/// ```
class FkLookupField<T> extends StatelessWidget {
  const FkLookupField({
    required this.label,
    required this.displayOf,
    required this.loader,
    required this.onSelected,
    super.key,
    this.value,
    this.helperText,
    this.validator,
    this.enabled = true,
    this.debounce = kFkLookupDebounce,
    this.labelWidget,
    this.hideLabel = false,
    this.isBorderless = false,
    this.textAlign,
  });

  final String label;

  /// Renders instead of [label] when set — e.g. a `FieldLabel` carrying the
  /// required marker. The picker dialog still titles itself with [label].
  final Widget? labelWidget;
  final bool hideLabel;
  final bool isBorderless;
  final TextAlign? textAlign;
  final T? value;
  final String Function(T item) displayOf;

  /// Called with the current search text (empty string on first open) to
  /// fetch matching options.
  final Future<List<T>> Function(String query) loader;
  final ValueChanged<T?> onSelected;
  final String? helperText;
  final FormFieldValidator<T?>? validator;
  final bool enabled;
  final Duration debounce;

  Future<void> _openPicker(BuildContext context) async {
    final picked = await showDialog<T>(
      context: context,
      builder: (dialogContext) => _FkLookupDialog<T>(
        title: label,
        displayOf: displayOf,
        loader: loader,
        debounce: debounce,
      ),
    );
    if (picked != null) onSelected(picked);
  }

  @override
  Widget build(BuildContext context) {
    return FormField<T?>(
      initialValue: value,
      validator: validator,
      builder: (state) {
        return InkWell(
          onTap: enabled ? () => _openPicker(context) : null,
          child: InputDecorator(
            decoration: InputDecoration(
              label: hideLabel ? null : labelWidget,
              labelText: hideLabel
                  ? null
                  : (labelWidget == null ? label : null),
              helperText: helperText,
              errorText: state.errorText,
              suffixIcon: const Icon(Icons.search),
              enabled: enabled,
              filled: !isBorderless,
              border: isBorderless ? InputBorder.none : null,
              enabledBorder: isBorderless ? InputBorder.none : null,
              focusedBorder: isBorderless
                  ? UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    )
                  : null,
            ),
            child: Text(
              value == null ? '' : displayOf(value as T),
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
              textAlign: textAlign,
            ),
          ),
        );
      },
    );
  }
}

class _FkLookupDialog<T> extends StatelessWidget {
  const _FkLookupDialog({
    required this.title,
    required this.displayOf,
    required this.loader,
    required this.debounce,
  });

  final String title;
  final String Function(T item) displayOf;
  final Future<List<T>> Function(String query) loader;
  final Duration debounce;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return BlocProvider(
      create: (_) => FkLookupCubit<T>(loader: loader, debounce: debounce),
      child: Builder(
        builder: (context) {
          return Dialog(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480, maxHeight: 520),
              child: Padding(
                padding: EdgeInsets.all(tokens.spacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    SizedBox(height: tokens.spacing.sm),
                    TextField(
                      autofocus: true,
                      onChanged: context.read<FkLookupCubit<T>>().search,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                      ),
                    ),
                    SizedBox(height: tokens.spacing.sm),
                    Flexible(
                      child: BlocBuilder<FkLookupCubit<T>, FkLookupState<T>>(
                        builder: (context, state) {
                          return FutureBuilder<List<T>>(
                            future: state.future,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const LoadingState();
                              }
                              if (snapshot.hasError) {
                                return EmptyState(
                                  message: snapshot.error.toString(),
                                );
                              }
                              final items = snapshot.data ?? const [];
                              if (items.isEmpty) {
                                return const EmptyState();
                              }
                              return ListView.builder(
                                shrinkWrap: true,
                                itemCount: items.length,
                                itemBuilder: (context, index) {
                                  final item = items[index];
                                  return ListTile(
                                    title: Text(displayOf(item)),
                                    onTap: () =>
                                        Navigator.of(context).pop(item),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
