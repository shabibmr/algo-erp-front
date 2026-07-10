import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// One pending mutation queued for the sync engine (Step 6). [id] doubles as
/// the idempotency key sent to the server (see CR-004) — regenerating it on
/// retry would defeat the point, so it's a client-generated UUID set once
/// at insert time, not a server id.
class OutboxEntries extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  TextColumn get entityName => text()();
  TextColumn get op => text()(); // create | update | delete
  TextColumn get localId => text()();
  TextColumn get payload => text()(); // JSON-encoded request body
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
