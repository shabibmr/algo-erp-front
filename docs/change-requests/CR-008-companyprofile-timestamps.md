# CR-008: `companyprofile` has no `created_at`/`updated_at` at all
- **Status:** Open
- **Priority:** P2
- **Module / Endpoint:** organization / CompanyProfile
- **Type:** Offline-sync gap
- **Found in step:** 0

## Problem
`companyprofile` is the one master entity verified in the Prisma schema to have zero timestamp
columns, making even a full-refresh diff unable to short-circuit on "nothing changed."

## Evidence
Direct schema check confirms `companyprofile` has no `created_at`/`updated_at` columns,
unlike nearly every other master table.

## Proposed change
Add `created_at`/`updated_at` to `companyprofile` for consistency with the rest of the schema.

## Frontend impact / workaround
Low impact in practice: `companyprofile` is a single-row-per-tenant entity, so the client
simply always re-fetches and overwrites it locally rather than trying to diff by timestamp.
