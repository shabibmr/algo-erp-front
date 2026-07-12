/// Local sync state for a row that mirrors a backend resource.
///
/// `synced` — matches the server, nothing to push.
/// `pendingCreate`/`pendingUpdate`/`pendingDelete` — a mutation is queued in
/// the outbox for this row and hasn't been confirmed by the server yet.
/// `conflict` — the outbox processor got a 409/validation error replaying
/// this row's mutation and needs user or policy resolution (see Step 6).
enum SyncStatus {
  synced,
  pendingCreate,
  pendingUpdate,
  pendingDelete,
  conflict,
}
