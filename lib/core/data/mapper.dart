/// Translates between a wire **DTO** and a clean **domain entity**.
///
/// The DTO ([D]) mirrors the backend payload exactly — inconsistent casing and
/// all (`Brand_Name`, `is_active`, `role_id`) — and owns JSON (de)serialization
/// via `freezed`/`json_serializable`. The entity ([E]) is what the rest of the
/// app sees: clean names, `Decimal` for money, real enums.
///
/// Keeping this boundary in one place (R6, single source of truth) means a
/// backend field rename or type quirk is absorbed here, never leaking into
/// blocs or widgets.
abstract interface class Mapper<D, E> {
  /// Wire DTO → domain entity (the read path).
  E toEntity(D dto);

  /// Domain entity → wire DTO (the write path: create/update bodies).
  D toDto(E entity);
}
