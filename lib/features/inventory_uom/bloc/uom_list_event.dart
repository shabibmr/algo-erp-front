import 'package:equatable/equatable.dart';

sealed class UomListEvent extends Equatable {
  const UomListEvent();

  @override
  List<Object?> get props => [];
}

final class UomListFetchRequested extends UomListEvent {
  const UomListFetchRequested();
}

final class UomListRefreshed extends UomListEvent {
  const UomListRefreshed();
}

final class UomListSearchChanged extends UomListEvent {
  const UomListSearchChanged(this.search);
  final String search;

  @override
  List<Object?> get props => [search];
}

final class UomItemDeleted extends UomListEvent {
  const UomItemDeleted(this.id);
  final int id;

  @override
  List<Object?> get props => [id];
}
