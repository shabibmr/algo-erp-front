import 'package:algo_erp_front/core/navigation/navigation_registry.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final class CommandPaletteState extends Equatable {
  const CommandPaletteState({this.results = const [], this.highlight = 0});

  final List<NavDestination> results;
  final int highlight;

  CommandPaletteState copyWith({
    List<NavDestination>? results,
    int? highlight,
  }) {
    return CommandPaletteState(
      results: results ?? this.results,
      highlight: highlight ?? this.highlight,
    );
  }

  @override
  List<Object?> get props => [results, highlight];
}

class CommandPaletteCubit extends Cubit<CommandPaletteState> {
  CommandPaletteCubit()
    : super(CommandPaletteState(results: NavigationRegistry.search('')));

  void search(String query) {
    emit(CommandPaletteState(results: NavigationRegistry.search(query)));
  }

  void highlightNext() {
    if (state.results.isEmpty) return;
    emit(
      state.copyWith(highlight: (state.highlight + 1) % state.results.length),
    );
  }

  void highlightPrevious() {
    if (state.results.isEmpty) return;
    emit(
      state.copyWith(
        highlight:
            (state.highlight - 1 + state.results.length) % state.results.length,
      ),
    );
  }
}
