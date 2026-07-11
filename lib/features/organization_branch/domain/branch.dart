import 'package:equatable/equatable.dart';

const _unset = Object();

/// The Branch master entity — soft-deleted (`BranchRepository` sets
/// `softDeleteField: 'is_active'`).
///
/// [companyId] is a required FK into CompanyProfile, but is modeled as a plain
/// int rather than `FieldType.fk`: CompanyProfile is deferred (binary `Logo`
/// column, no DELETE route — see `docs/manifest-exceptions.md`), so there is no
/// registered entity for an FK picker to search against. Revisit when
/// CompanyProfile lands.
class Branch extends Equatable {
  const Branch({
    required this.id,
    required this.code,
    required this.name,
    required this.companyId,
    this.address,
    this.isActive = true,
  });

  final int id;
  final String code;
  final String name;
  final int companyId;
  final String? address;
  final bool isActive;

  Branch copyWith({
    int? id,
    String? code,
    String? name,
    int? companyId,
    Object? address = _unset,
    bool? isActive,
  }) =>
      Branch(
        id: id ?? this.id,
        code: code ?? this.code,
        name: name ?? this.name,
        companyId: companyId ?? this.companyId,
        address:
            identical(address, _unset) ? this.address : address as String?,
        isActive: isActive ?? this.isActive,
      );

  @override
  List<Object?> get props => [id, code, name, companyId, address, isActive];
}
