import 'package:equatable/equatable.dart';

sealed class GodownListEvent extends Equatable {
  const GodownListEvent();

  @override
  List<Object?> get props => [];
}

final class GodownListFetchRequested extends GodownListEvent {
  const GodownListFetchRequested();
}

final class GodownListRefreshed extends GodownListEvent {
  const GodownListRefreshed();
}

final class GodownListSearchChanged extends GodownListEvent {
  const GodownListSearchChanged(this.search);
  final String search;

  @override
  List<Object?> get props => [search];
}

final class GodownItemDeleted extends GodownListEvent {
  const GodownItemDeleted(this.id);
  final int id;

  @override
  List<Object?> get props => [id];
}
