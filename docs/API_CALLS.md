# Application → Backend API Calls

> Inventory of every HTTP path the Flutter client (`lib/`) calls against the
> algoERP backend. Derived from manifests (`resourcePath`), voucher blueprints,
> custom repositories, auth/interceptor code, desk feeds, and
> `ReportCatalog` endpoints.
>
> **Not included:** frontend-only go_router routes, seed tooling under `tool/`,
> or test doubles.
>
> **Base URL:** set per flavor via `--dart-define=API_BASE_URL` (dev default
> `http://localhost:5000`). There is **no** `/api/v1` prefix; routers mount at
> the root (`/auth`, `/inventory`, …).
>
> **Common list query params** (EMR + voucher lists): `page`, `limit`,
> `search`, `sortBy`, `sortOrder`, plus entity-specific filters.

---

## How calls are made

| Mechanism | Location | Typical verbs |
|---|---|---|
| EMR CRUD (`RemoteDataSourceBase`) | `lib/core/data/remote_data_source_base.dart` | `GET` list, `GET /:id`, `POST`, `PUT /:id`, `DELETE /:id` |
| Auth | `lib/features/auth/data/auth_remote_data_source.dart` + `AuthInterceptor` | `POST` login/refresh/logout/change-password, `GET` me/permissions |
| Voucher families | `lib/core/vouchers/**` | `GET` list/detail, `POST` create, lifecycle `POST`/`PUT` |
| Custom masters | feature `*_repository.dart` (company, config, leave, rates, …) | subset of CRUD, non-standard paths |
| Desk | `lib/features/desk/data/desk_repository.dart` | `GET` dashboard/alerts |
| Reports | `lib/core/reports/report_repository.dart` + `report_catalog.dart` | `GET` only |

For EMR entities, **capability flags** on the manifest gate which verbs the UI
actually issues (`supportsUpdate`, `supportsDelete`). Where the repository
refuses a verb, that is noted.

---

## 1. Auth

| Method | Path | Source | Notes |
|---|---|---|---|
| `POST` | `/auth/login` | `AuthRemoteDataSource` | Public; body `{ username, password }` |
| `POST` | `/auth/refresh` | `AuthInterceptor` | Public; on 401; body `{ refreshToken }` |
| `GET` | `/auth/me` | `AuthRemoteDataSource` | Bearer |
| `GET` | `/auth/permissions` | `AuthRemoteDataSource` | Bearer; permission matrix after login |
| `POST` | `/auth/change-password` | `AuthRemoteDataSource` | Bearer |
| `POST` | `/auth/logout` | `AuthRemoteDataSource` | Bearer; audit-only server-side |

---

## 2. Desk / dashboard

| Method | Path | Source | Notes |
|---|---|---|---|
| `GET` | `/reports/dashboard` | `DeskRepository` | Query: `start_date`, `end_date` |
| `GET` | `/reports/dashboard/trend` | `DeskRepository` | Query: `months` |
| `GET` | `/reports/alerts` | `DeskRepository` | Action alerts for Today's Desk |

---

## 3. Master entities (EMR / standard CRUD)

Unless noted, full EMR set:

- `GET {path}` — paginated list  
- `GET {path}/:id` — detail  
- `POST {path}` — create  
- `PUT {path}/:id` — update  
- `DELETE {path}/:id` — delete  

### 3.1 Inventory

| Path | Feature | Verbs used | Notes |
|---|---|---|---|
| `/inventory/brand` | Brand | full CRUD | |
| `/inventory/category` | Category | full CRUD | `hardDelete: true` |
| `/inventory/uom` | UOM | full CRUD | `hardDelete: true` |
| `/inventory/conversion` | UOM conversion | full CRUD | |
| `/inventory/godown` | Godown | full CRUD | `hardDelete: true` |
| `/inventory/group` | Inventory group | full CRUD | `hardDelete: true` |
| `/inventory/item` | Inventory item | full CRUD | |
| `/inventory/sku` | SKU master | full CRUD | `hardDelete: true` |
| `/inventory/batch` | Item batch | full CRUD | Also used as a report endpoint |
| `/inventory/property` | Item property | list, get, create, delete | **No PUT** (`supportsUpdate: false`) |
| `/inventory/tax-category` | Tax category | full CRUD | |
| `/inventory/pricelist` | Price list | full CRUD | `hardDelete: true` |
| `/inventory/route` | Route master | full CRUD | `hardDelete: true` |

### 3.2 Accounts

| Path | Feature | Verbs used | Notes |
|---|---|---|---|
| `/accounts/groups` | Account group | full CRUD | |
| `/accounts/ledgers` | Ledger | full CRUD | Also used for FK search from vouchers |

### 3.3 Organization (standard EMR)

| Path | Feature | Verbs used | Notes |
|---|---|---|---|
| `/organization/branches` | Branch | full CRUD | |
| `/organization/currencies` | Currency | full CRUD | |
| `/organization/roles` | User role | full CRUD | Permissions are a separate path (below) |
| `/organization/users` | User credentials | full CRUD | Custom repo, same path shape |
| `/organization/contacts` | Address book | full CRUD | |
| `/organization/fy` | Financial year | list, get, create, update | **No DELETE** (`supportsDelete: false`) |
| `/organization/voucher-series` | Voucher series | full CRUD | Also queried from sales invoice for approval flag |
| `/organization/projects` | Project master | full CRUD | Also used for SI FK search |

### 3.4 Employee (standard EMR)

| Path | Feature | Verbs used | Notes |
|---|---|---|---|
| `/employee/departments` | Department | full CRUD | UI route uses `/employee/department` |
| `/employee/designations` | Designation | full CRUD | UI route uses `/employee/designation` |
| `/employee/employees` | Employee | full CRUD | Also SI salesperson search |

---

## 4. Master entities (custom / partial paths)

### 4.1 Company profile

| Method | Path | Notes |
|---|---|---|
| `GET` | `/organization/companies` | List (no server-side search; client filters) |
| `GET` | `/organization/company/:id` | Detail — **singular** `company` |
| `PUT` | `/organization/company/:id` | Update |
| — | create / delete | Not called (provision out of scope; `supportsDelete: false`) |

### 4.2 Currency rates

| Method | Path | Notes |
|---|---|---|
| `GET` | `/organization/rates/history` | List |
| `GET` | `/organization/rates/:id` | Detail |
| `POST` | `/organization/rates` | Create (append-only) |
| — | update / delete | Not called |

### 4.3 Config settings

| Method | Path | Notes |
|---|---|---|
| `GET` | `/organization/config` | Full array (not paginated) |
| `PUT` | `/organization/config/:key` | Update by **key** string, not numeric id |
| — | create / delete | Not called |

### 4.4 Audit logs

| Method | Path | Notes |
|---|---|---|
| `GET` | `/organization/audit-logs` | List only |

### 4.5 Error reports

| Method | Path | Notes |
|---|---|---|
| `GET` | `/organization/error-reports` | List |
| `POST` | `/organization/error-reports` | Create |
| — | get / update / delete | Not called |

### 4.6 Role permissions

| Method | Path | Notes |
|---|---|---|
| `GET` | `/organization/roles/:roleId/permissions` | Matrix for one role |
| `PUT` | `/organization/roles/:roleId/permissions` | Save matrix |

### 4.7 Leave policy

| Method | Path | Notes |
|---|---|---|
| `GET` | `/employee/leave/policies` | List; get-by-id scans list |
| `POST` | `/employee/leave/policies` | Create |
| — | update / delete | Not called |

### 4.8 Leave allocation

| Method | Path | Notes |
|---|---|---|
| `GET` | `/employee/employees/:employeeId/leave-allocations` | Query: `year` |
| `POST` | `/employee/leave/allocations` | Create |
| — | global list / get / update / delete | No HTTP (local refuse or empty) |

### 4.9 Leave request

| Method | Path | Notes |
|---|---|---|
| `GET` | `/employee/leave-requests` | Global list; get-by-id scans list |
| `POST` | `/employee/employees/:employeeId/leave-requests` | Create nested under employee |
| `PUT` | `/employee/leave-requests/:id` | Status update (`status`, optional `reason`) |
| — | delete | Not called (cancel via status) |

### 4.10 Shift master

| Method | Path | Notes |
|---|---|---|
| `GET` | `/employee/shifts` | List; get-by-id scans list |
| `POST` | `/employee/shifts` | Create |
| — | update / delete | Not called |

### 4.11 Accounts helpers (payment / receipt settlement)

| Method | Path | Notes |
|---|---|---|
| `GET` | `/accounts/outstanding/:ledgerId` | Outstanding bills for settlement UI |
| `POST` | `/accounts/billwise` | Write Agst-Ref settlement after payment/receipt |
| `GET` | `/accounts/aging` | Also a report endpoint (accounts aging) |

---

## 5. Transactions (vouchers)

Each voucher type uses a **list/detail** path and usually a **singular POST**
path. Lifecycle actions use the backend **type name** segment:

```
POST /transactions/{LifecycleType}/:id/cancel
POST /transactions/{LifecycleType}/:id/approve
POST /transactions/{LifecycleType}/:id/reject   # body: { reason }
PUT  /transactions/{LifecycleType}/:id         # draft edit (Sales Invoice only today)
```

Lifecycle methods exist on all voucher repositories; the UI only surfaces
actions listed on each `VoucherBlueprint.lifecycle`.

### 5.1 Item-qty family

| Type | LifecycleType | List | Detail | Post | Extra |
|---|---|---|---|---|---|
| Sales invoice | `SalesInvoice` | `GET /transactions/sales-invoices` | `GET …/sales-invoices/:id` | `POST /transactions/sales-invoice` | `PUT /transactions/SalesInvoice/:id` (draft); cancel / approve / reject; source list from SO or quotation |
| Quotation | `Quotation` | `GET /transactions/quotations` | `GET …/quotations/:id` | `POST /transactions/quotation` | cancel / approve / reject |
| Sales order | `SalesOrder` | `GET /transactions/sales-orders` | `GET …/sales-orders/:id` | `POST /transactions/sales-order` | cancel / approve / reject |
| Delivery note | `DeliveryNote` | `GET /transactions/delivery-notes` | `GET …/delivery-notes/:id` | `POST /transactions/delivery-note` | cancel; source from sales-orders |
| Purchase order | `PurchaseOrder` | `GET /transactions/purchase-orders` | `GET …/purchase-orders/:id` | `POST /transactions/purchase-order` | cancel |
| Receipt note | `ReceiptNote` | `GET /transactions/receipt-notes` | `GET …/receipt-notes/:id` | `POST /transactions/receipt-note` | cancel; source from purchase-orders |
| Purchase invoice | `PurchaseInvoice` | `GET /transactions/purchase-invoices` | `GET …/purchase-invoices/:id` | `POST /transactions/purchase-invoice` | cancel / approve / reject |
| Credit note | `CreditNote` | `GET /transactions/credit-notes` | `GET …/credit-notes/:id` | `POST /transactions/credit-note` | cancel |
| Debit note | `DebitNote` | `GET /transactions/debit-notes` | `GET …/debit-notes/:id` | `POST /transactions/debit-note` | cancel |

**Sales invoice lookup extras** (same session):

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/organization/voucher-series` | Approval-required flag for prefix |
| `GET` | `/employee/employees` | Salesperson search |
| `GET` | `/employee/employees/:id` | Resolve salesperson |
| `GET` | `/organization/projects` | Project search |
| `GET` | `/organization/projects/:id` | Resolve project |
| `GET` | `/transactions/sales-orders` | Convert-from source list |
| `GET` | `/transactions/sales-orders/:id` | Convert-from source detail |
| `GET` | `/transactions/quotations` | Convert-from source list |
| `GET` | `/transactions/quotations/:id` | Convert-from source detail |

### 5.2 Ledger-amount family (payment / receipt)

| Type | LifecycleType | List | Detail | Post | Lifecycle |
|---|---|---|---|---|---|
| Payment | `PaymentVoucher` | `GET /transactions/payments` | `GET …/payments/:id` | `POST /transactions/payment` | cancel / approve / reject |
| Receipt | `ReceiptVoucher` | `GET /transactions/receipts` | `GET …/receipts/:id` | `POST /transactions/receipt` | cancel / approve / reject |

Plus settlement helpers in §4.11.

### 5.3 Debit-credit family (journal / contra)

| Type | LifecycleType | List | Detail | Post | Lifecycle |
|---|---|---|---|---|---|
| Journal | `JournalVoucher` | `GET /transactions/journals` | `GET …/journals/:id` | `POST /transactions/journal` | cancel (/ approve / reject if used) |
| Contra | `ContraVoucher` | `GET /transactions/contra` | `GET …/contra/:id` | `POST /transactions/contra` | cancel |

### 5.4 Stock voucher family

| Type | LifecycleType | List | Detail | Post | Lifecycle / extra |
|---|---|---|---|---|---|
| Godown transfer | `GodownTransfer` | `GET /transactions/godown-transfers` | `GET …/godown-transfers/:id` | `POST /transactions/godown-transfer` | cancel |
| Material in | `MaterialIn` | `GET /transactions/material-in` | `GET …/material-in/:id` | `POST /transactions/material-in` | cancel |
| Requirement | `Requirement` | `GET /transactions/requirements` | `GET …/requirements/:id` | `POST /transactions/requirement` | cancel |
| Stock request | `StockRequest` | `GET /transactions/stock-requests` | `GET …/stock-requests/:id` | `POST /transactions/stock-request` | cancel; **`POST /transactions/stock-request/:id/fulfill`** |

---

## 6. Reports

All reports are **`GET`** via `ReportRepository.fetch(definition, params)`.
Query params come from each `ReportDefinition` (dates, filters, etc.).

### 6.1 Dedicated report endpoints

| Report id | Path |
|---|---|
| `sales-register` | `/transactions/reports/sales-register` |
| `purchase-register` | `/transactions/reports/purchase-register` |
| `stock-summary` | `/transactions/reports/stock-summary` |
| `stock-valuation` | `/transactions/reports/stock-valuation` |
| `vat-return` | `/transactions/reports/vat-return` |
| `trial-balance` | `/transactions/reports/trial-balance` |
| `day-book` | `/transactions/reports/day-book` |
| `profit-loss` | `/transactions/reports/profit-loss` |
| `balance-sheet` | `/transactions/reports/balance-sheet` |
| `ledger-statement` | `/transactions/reports/ledger-statement` |
| `accounts-aging` | `/accounts/aging` |
| `overtime-summary` | `/employee/reports/overtime` |
| `payroll-register` | `/employee/payslips` |
| `attendance-summary` | `/employees/attendance-summary` |
| `salary-revision-history` | `/employees/salary-revisions` |
| `cash-flow` | `/reports/cash-flow` |
| `budget-variance` | `/reports/budget-variance` |
| `collection-efficiency` | `/reports/collection-efficiency` |
| `ap-forecast` | `/reports/ap-forecast` |
| `vendor-expenses` | `/reports/vendor-expenses` |
| `sales-analytics` | `/reports/sales-analytics` |
| `sales-margin` | `/reports/sales-margin` |
| `price-variance` | `/reports/price-variance` |
| `stock-movement` | `/reports/stock-movement` |
| `bank-reconciliation` | `/reports/bank-reconciliation` |
| `cash-flow-statement` | `/reports/cash-flow-statement` |
| `fixed-assets-depreciation` | `/reports/fixed-assets-depreciation` |
| `quotation-conversion-ratio` | `/reports/quotation-conversion-ratio` |
| `salesperson-commission` | `/reports/salesperson-commission` |
| `inactive-customer-analysis` | `/reports/inactive-customer-analysis` |
| `vendor-leadtime-compliance` | `/reports/vendor-leadtime-compliance` |
| `ppv-audit` | `/reports/ppv-audit` |
| `bom-production-costing` | `/reports/bom-production-costing` |
| `bin-location-stock` | `/reports/bin-location-stock` |
| `dead-stock-analysis` | `/reports/dead-stock-analysis` |
| `statutory-payroll-compliance` | `/reports/statutory-payroll-compliance` |
| `leave-balance-register` | `/reports/leave-balance-register` |

### 6.2 Register-style reports (reuse list endpoints)

These report definitions call the same list paths as the transaction masters
(paginated voucher lists, not dedicated report handlers):

| Report id | Path |
|---|---|
| `credit-note-register` | `/transactions/credit-notes` |
| `debit-note-register` | `/transactions/debit-notes` |
| `quotation-register` | `/transactions/quotations` |
| `sales-order-register` | `/transactions/sales-orders` |
| `purchase-order-register` | `/transactions/purchase-orders` |
| `delivery-note-register` | `/transactions/delivery-notes` |
| `receipt-note-register` | `/transactions/receipt-notes` |
| `godown-transfer-register` | `/transactions/godown-transfers` |
| `receipts-summary` | `/transactions/receipts` |
| `payments-summary` | `/transactions/payments` |
| `material-requirements` | `/transactions/requirements` |
| `item-batches` | `/inventory/batch` |

---

## 7. Flat path checklist (unique resource roots)

Sorted unique paths the app may hit (including `/:id` and lifecycle suffixes
where fixed):

### Auth
- `POST /auth/login`
- `POST /auth/refresh`
- `GET /auth/me`
- `GET /auth/permissions`
- `POST /auth/change-password`
- `POST /auth/logout`

### Desk
- `GET /reports/dashboard`
- `GET /reports/dashboard/trend`
- `GET /reports/alerts`

### Inventory masters
- `/inventory/brand`
- `/inventory/category`
- `/inventory/uom`
- `/inventory/conversion`
- `/inventory/godown`
- `/inventory/group`
- `/inventory/item`
- `/inventory/sku`
- `/inventory/batch`
- `/inventory/property`
- `/inventory/tax-category`
- `/inventory/pricelist`
- `/inventory/route`

### Accounts
- `/accounts/groups`
- `/accounts/ledgers`
- `GET /accounts/outstanding/:ledgerId`
- `POST /accounts/billwise`
- `GET /accounts/aging`

### Organization
- `GET /organization/companies`
- `GET|PUT /organization/company/:id`
- `/organization/branches`
- `/organization/currencies`
- `GET /organization/rates/history`
- `GET|POST /organization/rates` / `GET /organization/rates/:id`
- `/organization/roles`
- `GET|PUT /organization/roles/:id/permissions`
- `/organization/users`
- `/organization/contacts`
- `/organization/fy`
- `/organization/voucher-series`
- `/organization/projects`
- `GET /organization/config` / `PUT /organization/config/:key`
- `GET /organization/audit-logs`
- `GET|POST /organization/error-reports`

### Employee
- `/employee/departments`
- `/employee/designations`
- `/employee/employees`
- `GET|POST /employee/leave/policies`
- `POST /employee/leave/allocations`
- `GET /employee/employees/:id/leave-allocations`
- `GET /employee/leave-requests`
- `POST /employee/employees/:id/leave-requests`
- `PUT /employee/leave-requests/:id`
- `GET|POST /employee/shifts`
- `GET /employee/payslips` (report)
- `GET /employee/reports/overtime`

### Transactions — create (POST singular)
- `/transactions/sales-invoice`
- `/transactions/quotation`
- `/transactions/sales-order`
- `/transactions/delivery-note`
- `/transactions/purchase-order`
- `/transactions/receipt-note`
- `/transactions/purchase-invoice`
- `/transactions/credit-note`
- `/transactions/debit-note`
- `/transactions/payment`
- `/transactions/receipt`
- `/transactions/journal`
- `/transactions/contra`
- `/transactions/godown-transfer`
- `/transactions/material-in`
- `/transactions/requirement`
- `/transactions/stock-request`

### Transactions — list / detail (GET plural-style)
- `/transactions/sales-invoices[/:id]`
- `/transactions/quotations[/:id]`
- `/transactions/sales-orders[/:id]`
- `/transactions/delivery-notes[/:id]`
- `/transactions/purchase-orders[/:id]`
- `/transactions/receipt-notes[/:id]`
- `/transactions/purchase-invoices[/:id]`
- `/transactions/credit-notes[/:id]`
- `/transactions/debit-notes[/:id]`
- `/transactions/payments[/:id]`
- `/transactions/receipts[/:id]`
- `/transactions/journals[/:id]`
- `/transactions/contra[/:id]`
- `/transactions/godown-transfers[/:id]`
- `/transactions/material-in[/:id]`
- `/transactions/requirements[/:id]`
- `/transactions/stock-requests[/:id]`

### Transactions — lifecycle (POST unless noted)
Pattern: `/transactions/{LifecycleType}/:id/{action}`  
Types: `SalesInvoice`, `Quotation`, `SalesOrder`, `DeliveryNote`,
`PurchaseOrder`, `ReceiptNote`, `PurchaseInvoice`, `CreditNote`, `DebitNote`,
`PaymentVoucher`, `ReceiptVoucher`, `JournalVoucher`, `ContraVoucher`,
`GodownTransfer`, `MaterialIn`, `Requirement`, `StockRequest`.

Actions: `cancel`, `approve`, `reject` (+ body for reject).  
Draft edit: `PUT /transactions/SalesInvoice/:id`.  
Fulfill: `POST /transactions/stock-request/:id/fulfill`.

### Transactions — financial reports
- `/transactions/reports/sales-register`
- `/transactions/reports/purchase-register`
- `/transactions/reports/stock-summary`
- `/transactions/reports/stock-valuation`
- `/transactions/reports/vat-return`
- `/transactions/reports/trial-balance`
- `/transactions/reports/day-book`
- `/transactions/reports/profit-loss`
- `/transactions/reports/balance-sheet`
- `/transactions/reports/ledger-statement`

### `/reports/*` analytics (GET)
- `/reports/cash-flow`
- `/reports/budget-variance`
- `/reports/collection-efficiency`
- `/reports/ap-forecast`
- `/reports/vendor-expenses`
- `/reports/sales-analytics`
- `/reports/sales-margin`
- `/reports/price-variance`
- `/reports/stock-movement`
- `/reports/bank-reconciliation`
- `/reports/cash-flow-statement`
- `/reports/fixed-assets-depreciation`
- `/reports/quotation-conversion-ratio`
- `/reports/salesperson-commission`
- `/reports/inactive-customer-analysis`
- `/reports/vendor-leadtime-compliance`
- `/reports/ppv-audit`
- `/reports/bom-production-costing`
- `/reports/bin-location-stock`
- `/reports/dead-stock-analysis`
- `/reports/statutory-payroll-compliance`
- `/reports/leave-balance-register`

### Odd / legacy-shaped report paths (as coded)
- `GET /employees/attendance-summary` — note: **no** `/employee` module prefix
- `GET /employees/salary-revisions` — same

---

## 8. Headers (all authenticated calls)

Sent by interceptors on the shared `Dio` client:

| Header | Source |
|---|---|
| `Authorization: Bearer <accessToken>` | `AuthInterceptor` |
| `X-Company-Id` | `TenantInterceptor` (JWT still wins server-side) |
| `X-Branch-Id` | `TenantInterceptor` |
| Request-id | `RequestIdInterceptor` |

`POST`/`PUT` auto-retry with Idempotency-Key is **not** used by the client
(see BE-005 in `docs/backend-suggestions.md`).

---

## 9. Source map (where to look when adding/changing calls)

| Concern | Primary files |
|---|---|
| Generic CRUD | `lib/core/data/remote_data_source_base.dart`, feature `*_manifest.dart` / `*_di.dart` |
| Auth | `lib/features/auth/data/auth_remote_data_source.dart`, `lib/core/network/interceptors/auth_interceptor.dart` |
| Voucher paths | `lib/core/vouchers/voucher_blueprint.dart`, `*_kind.dart`, `*_repository.dart` |
| Reports | `lib/core/reports/report_catalog.dart`, `report_repository.dart` |
| Desk | `lib/features/desk/data/desk_repository.dart` |
| Backend envelope / contract | `docs/api-contract.md` |

---

*Generated from the Flutter client codebase. Re-scan manifests, voucher
blueprints, and `report_catalog.dart` when paths change.*
