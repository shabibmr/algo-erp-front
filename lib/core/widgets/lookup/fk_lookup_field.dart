import 'dart:async';

import 'package:algo_erp_front/core/utils/extensions/build_context_x.dart';
import 'package:algo_erp_front/core/widgets/states/empty_state.dart';
import 'package:algo_erp_front/core/widgets/states/loading_state.dart';
import 'package:flutter/material.dart';

/// Default idle time before a keystroke triggers [FkLookupField.loader].
const kFkLookupDebounce = Duration(milliseconds: 350);

/// A foreign-key picker: a read-only field that opens a searchable dialog
/// backed by an async [loader] (typically a repository's `list` call with a
/// `PageQuery.search` term). Generic over the looked-up entity `T` so one
/// widget serves every FK relationship in the app (brand picker, account
/// picker, employee picker, ...).
///
/// The query is debounced with a simple [Timer] (no bloc involved here —
/// this is a self-contained widget, not a screen), so fast typing issues one
/// request instead of one per keystroke.
///
/// ```dart
/// FkLookupField<Brand>(
///   label: 'Brand',
///   value: selectedBrand,
///   displayOf: (b) => b.name,
///   loader: (query) => brandRepository.search(query),
///   onSelected: (b) => setState(() => selectedBrand = b),
/// )
/// ```
class FkLookupField<T> extends StatefulWidget {
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
  });

  final String label;

  /// Renders instead of [label] when set — e.g. a `FieldLabel` carrying the
  /// required marker. The picker dialog still titles itself with [label].
  final Widget? labelWidget;
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

  @override
  State<FkLookupField<T>> createState() => _FkLookupFieldState<T>();
}

class _FkLookupFieldState<T> extends State<FkLookupField<T>> {
  Future<void> _openPicker() async {
    final picked = await showDialog<T>(
      context: context,
      builder: (dialogContext) => _FkLookupDialog<T>(
        title: widget.label,
        displayOf: widget.displayOf,
        loader: widget.loader,
        debounce: widget.debounce,
      ),
    );
    if (picked != null) widget.onSelected(picked);
  }

  @override
  Widget build(BuildContext context) {
    return FormField<T?>(
      initialValue: widget.value,
      validator: widget.validator,
      builder: (state) {
        return InkWell(
          onTap: widget.enabled ? _openPicker : null,
          child: InputDecorator(
            decoration: InputDecoration(
              label: widget.labelWidget,
              labelText: widget.labelWidget == null ? widget.label : null,
              helperText: widget.helperText,
              errorText: state.errorText,
              suffixIcon: const Icon(Icons.search),
              enabled: widget.enabled,
            ),
            child: Text(
              widget.value == null ? '' : widget.displayOf(widget.value as T),
              style: Theme.of(context).textTheme.bodyLarge,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }
}

class _FkLookupDialog<T> extends StatefulWidget {
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
  State<_FkLookupDialog<T>> createState() => _FkLookupDialogState<T>();
}

class _FkLookupDialogState<T> extends State<_FkLookupDialog<T>> {
  Timer? _debounceTimer;
  Future<List<T>>? _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loader('');
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounce, () {
      if (!mounted) return;
      setState(() => _future = widget.loader(query));
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 520),
        child: Padding(
          padding: EdgeInsets.all(tokens.spacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: tokens.spacing.sm),
              TextField(
                autofocus: true,
                onChanged: _onQueryChanged,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
              ),
              SizedBox(height: tokens.spacing.sm),
              Flexible(
                child: FutureBuilder<List<T>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const LoadingState();
                    }
                    if (snapshot.hasError) {
                      return EmptyState(message: snapshot.error.toString());
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
                          title: Text(widget.displayOf(item)),
                          onTap: () => Navigator.of(context).pop(item),
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
  }
}
