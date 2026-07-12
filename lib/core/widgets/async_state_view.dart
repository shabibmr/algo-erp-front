import 'package:algo_erp_front/core/widgets/states/empty_state.dart';
import 'package:algo_erp_front/core/widgets/states/error_state.dart';
import 'package:algo_erp_front/core/widgets/states/loading_state.dart';
import 'package:algo_erp_front/core/widgets/view_state.dart';
import 'package:flutter/material.dart';

/// Renders the right widget for whichever branch of [ViewState] a screen is
/// currently in. This is the one place every list/detail screen defers to
/// for the loading/empty/error/data lifecycle, so that lifecycle only has to
/// be built (and tested) once.
///
/// Deliberately takes a [ViewState] — not a bloc — so it works with any
/// source: a `CrudBloc`/`DetailBloc` via `toViewState()` (see
/// `core/utils/extensions/view_state_x.dart`), a plain `FutureBuilder`, or a
/// dropdown's local state.
///
/// ```dart
/// BlocBuilder<MyBloc, MyState>(
///   builder: (context, state) => AsyncStateView<List<Item>>(
///     state: state.toViewState(),
///     onRetry: () => context.read<MyBloc>().add(const Reload()),
///     builder: (context, items) => ItemList(items: items),
///   ),
/// )
/// ```
class AsyncStateView<T> extends StatelessWidget {
  const AsyncStateView({
    required this.state,
    required this.builder,
    super.key,
    this.onRetry,
    this.emptyMessage,
    this.emptyIcon,
    this.emptyActionLabel,
    this.onEmptyAction,
    this.loadingMessage,
  });

  final ViewState<T> state;

  /// Builds the widget tree for the `ViewData` branch.
  final Widget Function(BuildContext context, T data) builder;

  /// Wired to the retry button in the `ViewError` branch. Leave null to hide
  /// the button (e.g. for a read-only sub-widget with no reload seam).
  final VoidCallback? onRetry;

  final String? emptyMessage;
  final IconData? emptyIcon;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;
  final String? loadingMessage;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      ViewLoading<T>() => LoadingState(message: loadingMessage),
      ViewEmpty<T>() => EmptyState(
        message: emptyMessage,
        icon: emptyIcon ?? Icons.inbox_outlined,
        actionLabel: emptyActionLabel,
        onAction: onEmptyAction,
      ),
      final ViewData<T> s => builder(context, s.data),
      final ViewError<T> s => ErrorState(failure: s.failure, onRetry: onRetry),
    };
  }
}
