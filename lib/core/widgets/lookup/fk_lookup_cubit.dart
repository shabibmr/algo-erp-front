import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final class FkLookupState<T> extends Equatable {
  const FkLookupState({this.future});

  final Future<List<T>>? future;

  @override
  List<Object?> get props => [future];
}

/// Debounced search for [FkLookupField] dialogs.
class FkLookupCubit<T> extends Cubit<FkLookupState<T>> {
  FkLookupCubit({
    required this.loader,
    this.debounce = const Duration(milliseconds: 350),
  }) : super(const FkLookupState()) {
    search('');
  }

  final Future<List<T>> Function(String query) loader;
  final Duration debounce;
  Timer? _timer;

  void search(String query) {
    _timer?.cancel();
    if (query.isEmpty) {
      emit(FkLookupState(future: loader(query)));
      return;
    }
    _timer = Timer(debounce, () {
      if (isClosed) return;
      emit(FkLookupState(future: loader(query)));
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
