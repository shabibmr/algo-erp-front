# algoERP Frontend Architecture

> Living architecture note for the **online-only**, manifest-driven client.  
> Last updated: 2026-07-13 (Sprint G).

## Goal

Ship a multi-tenant ERP UI where **masters** are declared once and rendered by a shared engine, **vouchers** reuse typed document engines, and **reports / desk / palette** assemble the product shell — without per-entity list/form widgets.

## Layering

```
Presentation   AppShell · go_router · AuthBloc · *ListPage/*FormPage · Desk · ReportViewer
Domain         Entity · Repository · PageQuery · Line Engine · ReportDefinition
Data           DTO + Mapper · RemoteDataSourceBase · RemoteRepository · DioClient
Backend        Express + Prisma — /auth · /organization · /accounts · /inventory
               /employee · /transactions · /reports
```

Parked (unwired): `lib/core/database/**`, `lib/core/sync/**` (offline-first pivot reversed).

## EMR (Entity Manifest Runtime)

| Piece | Path | Role |
|-------|------|------|
| `EntityManifest<E>` | `core/manifest/` | Label, RBAC module, resource path, columns, fields, capability flags |
| `MasterListSurface` / `MasterFormSurface` | `core/surfaces/` | Generic list + create/edit |
| `FieldRenderer` | `core/manifest/field_renderer.dart` | One switch: FormFieldSpec → widget |
| `CrudBloc` / `DetailBloc` | `core/bloc/` | Load, search, filter, CRUD |
| `RemoteRepository` | `core/data/` | One repository implementation for masters |

**Feature package (flat master):** 7 files + 2 routes + 1 menu item.  
Recipe: [`manifest-spec.md`](./manifest-spec.md). Exceptions: [`manifest-exceptions.md`](./manifest-exceptions.md).  
**Migrating remaining hand-written list/form blocs:** [`bloc-migration-checklist.md`](./bloc-migration-checklist.md).

```
EntityManifest ──► MasterListSurface ◄── CrudBloc ◄── Repository
              └──► MasterFormSurface ◄── DetailBloc / Repository
                         └── FieldRenderer(FieldType)
```

### Dependency rules

- Features depend **inward** on `core/domain`, `core/surfaces`, `core/manifest`.
- Do **not** invent a per-feature CrudBloc or list table.
- Cross-module FKs resolve via another module’s `createXRepository` factory (not presentation imports).
- Master repositories are **plain factories**, not `@injectable` (see `repo_binding.dart`).
- Money/qty: `Decimal`, never `double`.
- UI chrome: `context.tokens` (`AppTokens`) — no hardcoded colors/spacing.

## Vouchers

| Family | Engine | Feature |
|--------|--------|---------|
| Sales Invoice (gold) | custom + Line Engine | `transactions_sales_invoice` |
| Item-qty trading | `core/vouchers/item_qty` | `transactions_item_qty` |
| Payment / Receipt | `core/vouchers/ledger_amount` | `transactions_ledger_amount` |
| Journal / Contra | `core/vouchers/debit_credit` | `transactions_debit_credit` |
| Stock (GT/MI/RQ/SR) | `core/vouchers/stock` | `transactions_stock` |

`DocumentSurface` hosts header + lines + totals for the SI path; sibling families reuse the same product patterns with typed repositories.

## Reports & desk (Sprint G)

| Piece | Path |
|-------|------|
| Desk KPIs / alerts | `features/desk` → `GET /reports/dashboard`, `/reports/alerts` |
| `ReportDefinition` + catalog | `core/reports/` |
| `ReportViewer` | `core/surfaces/report_viewer.dart` |
| Hub + pages | `features/reports/` |
| Export (Excel + CSV) | `core/export/` — see below |

Stamp a new report by adding a `ReportDefinition` to `ReportCatalog` and routing `/reports/:id` (already generic).

## Export (`core/export/`)

Every list and every report exports to a real `.xlsx` (Excel is the default; CSV sits beside it).
Entirely client-side — the backend's five `/excel` endpoints are deliberately not used, so all 49
reports behave the same way.

| Piece | Path | Role |
|-------|------|------|
| `ExportCell` | `export_cell.dart` | Sealed cell union: text / number / date / bool / blank |
| `ExcelWriter` | `excel_writer.dart` | Hand-rolled OOXML — zips the XML parts of an `.xlsx` |
| `CsvWriter` | `csv_writer.dart` | The secondary format (still pipe-separated) |
| `EntityExport` | `entity_export.dart` | `FieldSpec` → typed cells; `reportCell` for report JSON |
| `ExportCubit<E>` | `export_cubit.dart` | Walks **every page** of the current query (200/page, 5000 cap) |
| `ExportButton<E>` | `export_button.dart` | The Excel/CSV menu; `.fromManifest` for entities with one |
| `saveExportBytes` | `export_sink*.dart` | The one platform fork: file on IO, Blob on web |

Four things here are load-bearing and easy to undo by accident:

1. **The `.xlsx` writer is hand-rolled on purpose.** `package:excel` pins `xml <7.0.0`; `package:pdf`
   (the print stack) needs `xml ^7`. They cannot coexist, and the PDF stack is not worth trading away.
   `archive` supplies the zip; the OOXML is ours.
2. **Export re-runs the query server-side.** `CrudLoaded.items` holds only the pages scrolled into
   view, so a file built from it is silently partial — that was the old CSV's core bug.
3. **Cells are typed, not stringly.** `FieldSpec.type` drives recovery of the display string
   (`AED 1,234.50` → `1234.5`), so `SUM()` works. Where the string is genuinely lossy, set
   `FieldSpec.exportValue` and it wins. Parsing never guesses: an unrecognised value stays text.
4. **The cubit gathers; the view writes.** Keeps the filesystem out of the bloc layer.

Lists get this for free — `MasterListSurface` wires it from the manifest, and the feature-bloc lists
pass `repository.list` to an `ExportCubit`. The voucher lists have no manifest, so they declare
columns via `voucherExportColumns` (`core/vouchers/voucher_export.dart`).

## Command palette

- `NavigationRegistry` indexes `AppMenu`, organization masters, report catalog, and create shortcuts.
- `CommandPalette` dialog: Ctrl/Cmd+K from `AppShell`, search icon in `ShellHeader`.

## Auth, tenancy, network

- JWT via `AuthInterceptor`; single shared refresh on 401.
- `X-Company-Id` / `X-Branch-Id` from `TenantInterceptor` (JWT wins server-side).
- Envelope: `{ success, data?, error?, requestId? }` — see [`api-contract.md`](./api-contract.md).
- Query params: only known keys; unknown keys become Prisma filters (can 500).

## DI

`get_it` + `injectable` for platform services (`DioClient`, `AuthBloc`, `ThemeCubit`, `LocaleCubit`, storage, permissions). Master/report repositories stay factory functions.

## Design system

**Ledger & Linen** — linen canvas, paper sheets, lagoon seals, brass for money. Spec: [`UI_DESIGN_PLAN.md`](./UI_DESIGN_PLAN.md). Widget inventory: [`widget-catalog.md`](./widget-catalog.md).

## Status & plan

- Living board: [`STATUS.md`](./STATUS.md)
- Execution narrative: [`BUILD_TASKS_V2.md`](./BUILD_TASKS_V2.md)
- Backend gaps: [`backend-suggestions.md`](./backend-suggestions.md)
