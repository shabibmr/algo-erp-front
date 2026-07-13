import 'package:equatable/equatable.dart';

sealed class SkuMasterListEvent extends Equatable {
  const SkuMasterListEvent();

  @override
  List<Object?> get props => [];
}

final class SkuMasterListFetchRequested extends SkuMasterListEvent {
  const SkuMasterListFetchRequested();
}

final class SkuMasterListRefreshed extends SkuMasterListEvent {
  const SkuMasterListRefreshed();
}

final class SkuMasterListSearchChanged extends SkuMasterListEvent {
  const SkuMasterListSearchChanged(this.search);

  final String search;

  @override
  List<Object?> get props => [search];
}

final class SkuMasterItemDeleted extends SkuMasterListEvent {
  const SkuMasterItemDeleted(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}
