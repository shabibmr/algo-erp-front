import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Columns every offline-syncable entity table must have. Mix this into a
/// table with `class Brands extends Table with SyncColumns { ... }` — see
/// `docs/templates/*` (Step 10+) for the full per-entity convention this
/// backs. `localId` is always the primary key: rows are created locally
/// before a server id exists, so the server's own integer id can never be
/// the identity column.
mixin SyncColumns on Table {
  TextColumn get localId => text().clientDefault(() => _uuid.v4())();

  /// Null until the row has round-tripped to the server at least once.
  IntColumn get serverId => integer().nullable()();

  /// One of [SyncStatus].name — kept as text (not textEnum) so the enum can
  /// gain members without a schema migration.
  TextColumn get syncStatus =>
      text().withDefault(const Constant('synced'))();

  /// The server's own `updated_at` (or equivalent), null for rows never
  /// synced or for entities without one (see CR-002).
  DateTimeColumn get updatedAtServer => dateTime().nullable()();

  DateTimeColumn get updatedAtLocal =>
      dateTime().withDefault(currentDateAndTime)();

  /// Local soft-delete flag. Independent of whether the *server* entity is
  /// soft- or hard-deletable (see docs/api-contract.md) — locally we always
  /// want a tombstone period so a pending-delete row can still be shown
  /// with a "deleting…" badge until the outbox confirms it.
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// JSON array of field names changed locally since the last successful
  /// sync — lets the outbox processor send a partial update instead of the
  /// full row where the API supports it.
  TextColumn get dirtyFields => text().withDefault(const Constant('[]'))();

  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {localId};
}
