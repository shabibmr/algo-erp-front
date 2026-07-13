import 'package:equatable/equatable.dart';

sealed class CategoryListEvent extends Equatable {
  const CategoryListEvent();

  @override
  List<Object?> get props => [];
}

final class CategoryListFetchRequested extends CategoryListEvent {
  const CategoryListFetchRequested();
}

final class CategoryListRefreshed extends CategoryListEvent {
  const CategoryListRefreshed();
}

final class CategoryListSearchChanged extends CategoryListEvent {
  const CategoryListSearchChanged(this.search);

  final String search;

  @override
  List<Object?> get props => [search];
}

final class CategoryItemDeleted extends CategoryListEvent {
  const CategoryItemDeleted(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}
