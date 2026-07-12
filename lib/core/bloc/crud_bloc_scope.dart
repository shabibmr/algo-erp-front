import 'package:algo_erp_front/core/bloc/crud_bloc.dart';
import 'package:algo_erp_front/core/bloc/crud_contract.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Owns one [CrudBloc] per manifest, above the routes that use it.
///
/// A master's list (`/inventory/brand`) and form (`/inventory/brand/new`) are
/// *sibling* routes, so a `BlocProvider` created inside either one is
/// unreachable from the other. That is why a freshly created row never showed
/// up in the list: the form persisted it, then navigated back to a list whose
/// bloc had never heard of it.
///
/// Mounted once in `AppShell` — the common ancestor of every shell route —
/// this scope hands both routes the *same* bloc instance, so the form can tell
/// the list its rows changed.
///
/// Note the surrounding contract: `MasterFormSurface` persists through the
/// repository itself (that is what lets it bind per-field validation errors to
/// widgets). So a form must notify this bloc with [CrudRefreshRequested] —
/// **not** [CrudItemCreated]/[CrudItemUpdated]/[CrudItemDeleted], which perform
/// the write themselves and would save the entity a second time.
class CrudBlocScope extends StatefulWidget {
  const CrudBlocScope({required this.child, super.key});

  final Widget child;

  /// The shared bloc for [manifestId], built with [create] on first use and
  /// kept alive until the shell is torn down.
  ///
  /// Callers must pass the same type arguments and an equivalent factory for a
  /// given [manifestId]; the first caller wins and the rest get that instance.
  /// The initial [CrudLoadRequested] is dispatched here, on creation, so a list
  /// page no longer has to fire it (and no longer re-fires it on every visit).
  static CrudBloc<E, ID, F> of<E, ID, F>(
    BuildContext context,
    String manifestId,
    CrudBloc<E, ID, F> Function() create,
  ) {
    final marker = context
        .getInheritedWidgetOfExactType<_CrudBlocScopeMarker>();
    assert(marker != null, 'No CrudBlocScope above this context.');
    return marker!.state._resolve<E, ID, F>(manifestId, create);
  }

  @override
  State<CrudBlocScope> createState() => _CrudBlocScopeState();
}

class _CrudBlocScopeState extends State<CrudBlocScope> {
  final Map<String, Object> _blocs = {};

  CrudBloc<E, ID, F> _resolve<E, ID, F>(
    String manifestId,
    CrudBloc<E, ID, F> Function() create,
  ) {
    final existing = _blocs[manifestId];
    if (existing is CrudBloc<E, ID, F>) return existing;
    final bloc = create()..add(CrudLoadRequested<E, F>());
    _blocs[manifestId] = bloc;
    return bloc;
  }

  @override
  void dispose() {
    for (final bloc in _blocs.values) {
      (bloc as BlocBase<dynamic>).close();
    }
    _blocs.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _CrudBlocScopeMarker(state: this, child: widget.child);
}

class _CrudBlocScopeMarker extends InheritedWidget {
  const _CrudBlocScopeMarker({required this.state, required super.child});

  final _CrudBlocScopeState state;

  @override
  bool updateShouldNotify(_CrudBlocScopeMarker oldWidget) => false;
}
