import 'package:equatable/equatable.dart';

sealed class BrandListEvent extends Equatable {
  const BrandListEvent();

  @override
  List<Object?> get props => [];
}

final class BrandListFetchRequested extends BrandListEvent {
  const BrandListFetchRequested();
}

final class BrandListRefreshed extends BrandListEvent {
  const BrandListRefreshed();
}

final class BrandListSearchChanged extends BrandListEvent {
  const BrandListSearchChanged(this.search);

  final String search;

  @override
  List<Object?> get props => [search];
}

final class BrandItemDeleted extends BrandListEvent {
  const BrandItemDeleted(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}
