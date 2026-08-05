# API calls by app function

List of backend calls the Flutter app makes, grouped by the **real function** that
issues the HTTP request.

**Total distinct functions listed: 77**

Shared helpers (e.g. `RemoteDataSourceBase.list`) are listed **once**, with the
paths they are used for. One function may hit many paths when the path is
parameterized.

---

## Auth (1–6)

| # | Function | Method | Path |
|---|---|---|---|
| 1 | `AuthRemoteDataSource.login` | `POST` | `/auth/login` |
| 2 | `AuthRemoteDataSource.me` | `GET` | `/auth/me` |
| 3 | `AuthRemoteDataSource.permissions` | `GET` | `/auth/permissions` |
| 4 | `AuthRemoteDataSource.changePassword` | `POST` | `/auth/change-password` |
| 5 | `AuthRemoteDataSource.logout` | `POST` | `/auth/logout` |
| 6 | `AuthInterceptor` (on 401) | `POST` | `/auth/refresh` |

---

## EMR masters — `RemoteDataSourceBase` (7–11)

Used for standard master entities (brand, item, ledger, branch, …).  
Path comes from each feature’s `resourcePath`.

| # | Function | Method | Path |
|---|---|---|---|
| 7 | `RemoteDataSourceBase.list` | `GET` | `{resourcePath}` |
| 8 | `RemoteDataSourceBase.getById` | `GET` | `{resourcePath}/:id` |
| 9 | `RemoteDataSourceBase.create` | `POST` | `{resourcePath}` |
| 10 | `RemoteDataSourceBase.update` | `PUT` | `{resourcePath}/:id` |
| 11 | `RemoteDataSourceBase.delete` | `DELETE` | `{resourcePath}/:id` |

### `resourcePath` values (paths these five functions use)

| Feature | `resourcePath` |
|---|---|
| Brand | `/inventory/brand` |
| Category | `/inventory/category` |
| UOM | `/inventory/uom` |
| UOM conversion | `/inventory/conversion` |
| Godown | `/inventory/godown` |
| Inventory group | `/inventory/group` |
| Inventory item | `/inventory/item` |
| SKU | `/inventory/sku` |
| Item batch | `/inventory/batch` |
| Item property | `/inventory/property` (no update) |
| Tax category | `/inventory/tax-category` |
| Price list | `/inventory/pricelist` |
| Route | `/inventory/route` |
| Account group | `/accounts/groups` |
| Ledger | `/accounts/ledgers` |
| Branch | `/organization/branches` |
| Currency | `/organization/currencies` |
| User role | `/organization/roles` |
| User credentials | `/organization/users` (also has own repo; same paths) |
| Address book | `/organization/contacts` |
| Financial year | `/organization/fy` (no delete) |
| Voucher series | `/organization/voucher-series` |
| Project | `/organization/projects` |
| Department | `/employee/departments` |
| Designation | `/employee/designations` |
| Employee | `/employee/employees` |

---

## Custom masters (own repositories)

### Company (12–14)

| # | Function | Method | Path |
|---|---|---|---|
| 12 | `CompanyProfileRepository.list` | `GET` | `/organization/companies` |
| 13 | `CompanyProfileRepository.getById` | `GET` | `/organization/company/:id` |
| 14 | `CompanyProfileRepository.update` | `PUT` | `/organization/company/:id` |

### Currency rates (15–17)

| # | Function | Method | Path |
|---|---|---|---|
| 15 | `CurrencyRateRepository.list` | `GET` | `/organization/rates/history` |
| 16 | `CurrencyRateRepository.getById` | `GET` | `/organization/rates/:id` |
| 17 | `CurrencyRateRepository.create` | `POST` | `/organization/rates` |

### Config (18–19)

| # | Function | Method | Path |
|---|---|---|---|
| 18 | `ConfigSettingRepository._loadAll` | `GET` | `/organization/config` |
| 19 | `ConfigSettingRepository.update` | `PUT` | `/organization/config/:key` |

### Audit / error reports (20–22)

| # | Function | Method | Path |
|---|---|---|---|
| 20 | `AuditLogRepository.list` | `GET` | `/organization/audit-logs` |
| 21 | `ErrorReportRepository.list` | `GET` | `/organization/error-reports` |
| 22 | `ErrorReportRepository.create` | `POST` | `/organization/error-reports` |

### Role permissions (23–24)

| # | Function | Method | Path |
|---|---|---|---|
| 23 | `RolePermissionsRepository.list` | `GET` | `/organization/roles/:roleId/permissions` |
| 24 | `RolePermissionsRepository.save` | `PUT` | `/organization/roles/:roleId/permissions` |

### User credentials (25–29)

| # | Function | Method | Path |
|---|---|---|---|
| 25 | `UserCredentialsRepository.list` | `GET` | `/organization/users` |
| 26 | `UserCredentialsRepository.getById` | `GET` | `/organization/users/:id` |
| 27 | `UserCredentialsRepository.create` | `POST` | `/organization/users` |
| 28 | `UserCredentialsRepository.update` | `PUT` | `/organization/users/:id` |
| 29 | `UserCredentialsRepository.delete` | `DELETE` | `/organization/users/:id` |

### Leave policy (30–31)

| # | Function | Method | Path |
|---|---|---|---|
| 30 | `LeavePolicyRepository.list` | `GET` | `/employee/leave/policies` |
| 31 | `LeavePolicyRepository.create` | `POST` | `/employee/leave/policies` |

### Leave allocation (32–33)

| # | Function | Method | Path |
|---|---|---|---|
| 32 | `LeaveAllocationRepository.listForEmployee` | `GET` | `/employee/employees/:employeeId/leave-allocations` |
| 33 | `LeaveAllocationRepository.create` | `POST` | `/employee/leave/allocations` |

### Leave request (34–36)

| # | Function | Method | Path |
|---|---|---|---|
| 34 | `LeaveRequestRepository.list` | `GET` | `/employee/leave-requests` |
| 35 | `LeaveRequestRepository.create` | `POST` | `/employee/employees/:employeeId/leave-requests` |
| 36 | `LeaveRequestRepository.updateStatus` | `PUT` | `/employee/leave-requests/:id` |

### Shift (37–38)

| # | Function | Method | Path |
|---|---|---|---|
| 37 | `ShiftMasterRepository.list` | `GET` | `/employee/shifts` |
| 38 | `ShiftMasterRepository.create` | `POST` | `/employee/shifts` |

---

## Desk (39–41)

| # | Function | Method | Path |
|---|---|---|---|
| 39 | `DeskRepository.fetchDashboard` | `GET` | `/reports/dashboard` |
| 40 | `DeskRepository.fetchTrend` | `GET` | `/reports/dashboard/trend` |
| 41 | `DeskRepository.fetchAlerts` | `GET` | `/reports/alerts` |

---

## Reports (42)

| # | Function | Method | Path |
|---|---|---|---|
| 42 | `ReportRepository.fetch` | `GET` | `{ReportDefinition.endpoint}` |

Endpoints come from `ReportCatalog` (49 definitions), including e.g.:

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
- `/accounts/aging`
- `/employee/reports/overtime`
- `/employee/payslips`
- `/employees/attendance-summary`
- `/employees/salary-revisions`
- `/reports/cash-flow`, `/reports/budget-variance`, … (see catalog)
- plus register-style reports that reuse list paths (`/transactions/credit-notes`, …)

---

## Vouchers — item-qty family (43–51)

`ItemQtyRepository` (and `SalesInvoiceRepository`, which delegates to it).

Path from `kind.blueprint` / `kind.lifecycleType`.

| # | Function | Method | Path |
|---|---|---|---|
| 43 | `ItemQtyRepository.list` | `GET` | `{listPath}` e.g. `/transactions/sales-invoices` |
| 44 | `ItemQtyRepository.getById` | `GET` | `{listPath}/:id` |
| 45 | `ItemQtyRepository.post` | `POST` | `{postPath}` e.g. `/transactions/sales-invoice` |
| 46 | `ItemQtyRepository.updateDraft` | `PUT` | `/transactions/{LifecycleType}/:id` |
| 47 | `ItemQtyRepository.cancel` | `POST` | `/transactions/{LifecycleType}/:id/cancel` |
| 48 | `ItemQtyRepository.approve` | `POST` | `/transactions/{LifecycleType}/:id/approve` |
| 49 | `ItemQtyRepository.reject` | `POST` | `/transactions/{LifecycleType}/:id/reject` |
| 50 | `ItemQtyRepository.searchSourceVouchers` | `GET` | source list path (SO / quotation / PO) |
| 51 | `ItemQtyRepository.getSourceVoucher` | `GET` | source detail path |

### Sales invoice extras (52–56)

| # | Function | Method | Path |
|---|---|---|---|
| 52 | `SalesInvoiceRepository.seriesRequiresApproval` | `GET` | `/organization/voucher-series` |
| 53 | `SalesInvoiceRepository.searchEmployees` | `GET` | `/employee/employees` |
| 54 | `SalesInvoiceRepository.getEmployee` | `GET` | `/employee/employees/:id` |
| 55 | `SalesInvoiceRepository.searchProjects` | `GET` | `/organization/projects` |
| 56 | `SalesInvoiceRepository.getProject` | `GET` | `/organization/projects/:id` |

**Item-qty kinds:** Sales invoice, Quotation, Sales order, Delivery note, Purchase order, Receipt note, Purchase invoice, Credit note, Debit note.

---

## Vouchers — payment / receipt (57–64)

| # | Function | Method | Path |
|---|---|---|---|
| 57 | `LedgerAmountRepository.list` | `GET` | `{listPath}` |
| 58 | `LedgerAmountRepository.getById` | `GET` | `{listPath}/:id` |
| 59 | `LedgerAmountRepository.post` | `POST` | `{postPath}` |
| 60 | `LedgerAmountRepository.cancel` | `POST` | `/transactions/{LifecycleType}/:id/cancel` |
| 61 | `LedgerAmountRepository.approve` | `POST` | `/transactions/{LifecycleType}/:id/approve` |
| 62 | `LedgerAmountRepository.reject` | `POST` | `/transactions/{LifecycleType}/:id/reject` |
| 63 | `LedgerAmountRepository.listOutstanding` | `GET` | `/accounts/outstanding/:ledgerId` |
| 64 | `LedgerAmountRepository.createBillwiseSettlement` | `POST` | `/accounts/billwise` |

---

## Vouchers — journal / contra (65–70)

| # | Function | Method | Path |
|---|---|---|---|
| 65 | `DebitCreditRepository.list` | `GET` | `{listPath}` |
| 66 | `DebitCreditRepository.getById` | `GET` | `{listPath}/:id` |
| 67 | `DebitCreditRepository.post` | `POST` | `{postPath}` |
| 68 | `DebitCreditRepository.cancel` | `POST` | `/transactions/{LifecycleType}/:id/cancel` |
| 69 | `DebitCreditRepository.approve` | `POST` | `/transactions/{LifecycleType}/:id/approve` |
| 70 | `DebitCreditRepository.reject` | `POST` | `/transactions/{LifecycleType}/:id/reject` |

---

## Vouchers — stock (71–77)

| # | Function | Method | Path |
|---|---|---|---|
| 71 | `StockVoucherRepository.list` | `GET` | `{listPath}` |
| 72 | `StockVoucherRepository.getById` | `GET` | `{listPath}/:id` |
| 73 | `StockVoucherRepository.post` | `POST` | `{postPath}` |
| 74 | `StockVoucherRepository.cancel` | `POST` | `/transactions/{LifecycleType}/:id/cancel` |
| 75 | `StockVoucherRepository.approve` | `POST` | `/transactions/{LifecycleType}/:id/approve` |
| 76 | `StockVoucherRepository.reject` | `POST` | `/transactions/{LifecycleType}/:id/reject` |
| 77 | `StockVoucherRepository.fulfill` | `POST` | `/transactions/stock-request/:id/fulfill` |

---

## Summary

| Range | Section | Count |
|---|---|---:|
| 1–6 | Auth | 6 |
| 7–11 | EMR base | 5 |
| 12–38 | Custom masters | 27 |
| 39–41 | Desk | 3 |
| 42 | Reports | 1 |
| 43–56 | Item-qty + SI extras | 14 |
| 57–64 | Payment / receipt | 8 |
| 65–70 | Journal / contra | 6 |
| 71–77 | Stock | 7 |
| | **Total** | **77** |

These are **77 distinct app functions** that call the backend. Many cover multiple
URL paths via parameters (`resourcePath`, voucher `kind`, report `endpoint`).

For a full path inventory (not by function), see `docs/API_CALLS.md`.
