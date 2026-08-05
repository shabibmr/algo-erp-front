# algoERP Frontend — Application Context & Feature Inventory

> **Document Version:** 1.0.0  
> **Last Updated:** 2026-07-26  
> **Target Audience:** Developers, Technical Product Managers, AI Coding Agents  
> **Code Ground Truth:** `lib/features/**`, `lib/core/**`, `docs/**`

---

## 1. Executive Overview & System Architecture

`algo_erp_front` is the Flutter desktop, web, and mobile client for **algoERP**, a multi-tenant enterprise resource planning (ERP) system. The client connects directly over HTTPS via Dio to the backend service (`algo-backend` running Node.js, Express 5, Prisma ORM, MySQL).

### Core Architectural Paradigm: Manifest-Driven Master Engine (EMR)

Unlike standard Flutter apps with bespoke List/Form screens for every entity, `algoERP` uses the **Entity Manifest Runtime (EMR)**. The `core` layer provides generic list, form, bloc, data source, and repository infrastructure. A master entity is **declared** via an `EntityManifest<E>`, and the EMR dynamically renders lists, forms, field types, validation rules, search filters, and RBAC permissions.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            PRESENTATION LAYER                               │
│ AppShell · go_router · AuthBloc · Today's Desk · ReportViewer · Surface UI  │
│                                                                             │
│  MasterListSurface<E>                      MasterFormSurface<E, ID>        │
│    ├── AdaptiveEntityList                     ├── FieldRenderer (FieldType) │
│    ├── FilterBar                              ├── FormMixin & Wire Errors   │
│    └── PermissionGate                         └── Sub-tabs & FK Selectors   │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │ BlocProvider / RepositoryProvider
┌──────────────────────────────────────▼──────────────────────────────────────┐
│                              DOMAIN LAYER                                   │
│ Entity<E> · Repository<E, ID> · PageQuery · Line Engine · VoucherBlueprint  │
│ CrudBloc<E, ID, F> · DetailBloc<E, ID> · ReportDefinition                   │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │ Data Contracts / DTO Mappers
┌──────────────────────────────────────▼──────────────────────────────────────┐
│                               DATA LAYER                                    │
│ RemoteRepository<E, ID> · RemoteDataSourceBase · DTO + Mapper               │
│ DioClient (Auth, Tenant X-Company-Id / X-Branch-Id, Request-Id)              │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │ HTTPS / JSON API
┌──────────────────────────────────────▼──────────────────────────────────────┐
│                              BACKEND SYSTEM                                 │
│ Express 5 API (/auth, /organization, /accounts, /inventory, /employee,     │
│ /transactions, /reports)                                                    │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Key Architectural Principles (R1–R7 Rules)

1. **R1: Program to Interfaces:** Every feature programs against abstract contracts (`Repository<E, ID>`, `PermissionService`).
2. **R2: Single Generic Master Engine:** 30+ master entities share `MasterListSurface`, `MasterFormSurface`, `CrudBloc`, and `RemoteRepository`.
3. **R3: Sealed UI States:** UI states are sealed unions (`ViewState<T>`, `CrudState<E>`, `AuthState`), guaranteeing exhaustive `switch` handling.
4. **R4: Composition over Inheritance:** Functionality is composed using mixins (`FormMixin`, `PaginationMixin`, `SearchDebounceMixin`, `RbacMixin`).
5. **R5: Contract-First Development:** Wire contracts, DTO mappers, and repository factory signatures are frozen before UI construction.
6. **R6: Single Source of Truth for Wire Shapes:** One DTO per wire payload, mapping exact backend field casings defensively.
7. **R7: Financial Precision & Security by Default:** All currency and quantity calculations use `package:decimal` (never double). Security and RBAC are enforced at surface, bloc, and network boundaries.

---

## 2. Core Frameworks & System Engines

### 2.1 Entity Manifest Runtime (EMR)
- **`EntityManifest<E>`** (`lib/core/manifest/entity_manifest.dart`): Typed metadata specifying resource path, RBAC module, primary key, list columns, form fields, and capabilities (`supportsCreate`, `supportsUpdate`, `supportsDelete`, `hardDelete`).
- **`MasterListSurface<E>`** (`lib/core/surfaces/master_list_surface.dart`): Renders adaptive entity list tables and cards, debounced search bar, sorting, pagination, and multi-format client-side export (Excel `.xlsx` / CSV).
- **`MasterFormSurface<E, ID>`** (`lib/core/surfaces/master_form_surface.dart`): Dynamic form builder handling create, view, and edit modes, displaying field controls according to `FormFieldSpec`.
- **`FieldRenderer`** (`lib/core/manifest/field_renderer.dart`): Central rendering switch mapping field types (`text`, `number`, `decimal`, `bool`, `dateTime`, `fk`, `selfFk`) to design-system inputs.
- **`CrudBloc<E, ID, F>`** (`lib/core/bloc/crud_bloc.dart`): Generic BLoC managing list fetching, debounced search, infinite scroll pagination, and optimistic CRUD mutations with error rollback.

### 2.2 Document & Voucher Engines
Document vouchers (invoices, orders, transfers, vouchers) are processed by dedicated document engines:
- **Line Engine** (`lib/core/domain/line_engine/`): Pure Dart calculation engine utilizing `Decimal` for precision handling of item rates, gross amounts, line discounts, tax rates (VAT), net line totals, and document headers.
- **`VoucherBlueprint`** (`lib/core/vouchers/voucher_blueprint.dart`): Structural declaration defining document type, title, numbering series, header fields, line column specs, and lifecycle actions.
- **`DocumentSurface`** (`lib/core/surfaces/`): Unified header-and-lines transaction screen for creating, viewing, posting, printing, and canceling vouchers.
- **Voucher Engine Families:**
  1. **Sales Invoice Engine (Gold Standard)** (`lib/features/transactions_sales_invoice/`): Full document lifecycle (Draft → Approved → Posted → Canceled), PDF generation, conversion from Quotation/Sales Order, salesperson/project selection, and instant GL/Stock booking.
  2. **Item-Qty Engine** (`lib/core/vouchers/item_qty/`): Powers 8 trading document types (Quotation, Sales Order, Purchase Order, Delivery Note, Receipt Note, Purchase Invoice, Credit Note, Debit Note).
  3. **Ledger-Amount Engine** (`lib/core/vouchers/ledger_amount/`): Powers cash/bank financial vouchers (Payment, Receipt) with optional billwise outstanding allocation.
  4. **Debit-Credit Engine** (`lib/core/vouchers/debit_credit/`): Powers double-entry accounting vouchers (Journal, Contra) with real-time debit/credit balancing verification.
  5. **Stock Engine** (`lib/core/vouchers/stock/`): Powers warehouse stock transactions (Godown Transfer, Material In, Requirement, Stock Request with Fulfill UI).

### 2.3 Report & Business Intelligence Engine
- **`ReportDefinition`** (`lib/core/reports/report_definition.dart`): Declarative specification of report parameters, filter fields, table schemas, summary rows, and grouping.
- **`ReportViewer`** (`lib/core/surfaces/report_viewer.dart`): Dynamic report UI featuring parameter inputs, interactive data tables, automatic total calculation, and export.
- **`ReportCatalog`** (`lib/core/reports/report_catalog.dart`): Stamped catalog of ~49 business reports across Sales, Purchase, Inventory, Accounts, HR, and VAT.
- **Client-Side Export Subsystem** (`lib/core/export/`): Custom OOXML `.xlsx` Excel generator (`ExcelWriter`), pipe-delimited CSV generator (`CsvWriter`), and paginated dataset query aggregator (`ExportCubit`). Exports run completely client-side without external binary lock-in.

### 2.4 Navigation & App Shell
- **Adaptive Shell & Domain Hubs** (`lib/core/navigation/`): Responsive navigation system featuring domain hubs (`/sales`, `/purchase`, `/inventory`, `/accounts`, `/employee`, `/organization`, `/reports`) rendering business tiles and cross-module links.
- **Command Palette** (`lib/core/navigation/command_palette.dart`): Keyboard-driven (`Ctrl+K` / `Cmd+K`) global search dialog indexing all hub pages, master list views, report definitions, and creation shortcuts via `NavigationRegistry`.

### 2.5 Security, Auth & RBAC
- **Authentication Stack** (`lib/features/auth/`): JWT bearer authentication with automatic, transparent token refresh via `AuthInterceptor`. Secure token storage in `flutter_secure_storage`.
- **RBAC Subsystem** (`lib/core/auth/`): `MatrixPermissionService` enforcing granular role-based permissions fetched from `GET /auth/permissions`. UI elements and routes are guarded by `PermissionGate` and `RbacMixin`.

---

## 3. Business Domains & Module Inventory

The application is structured into **7 core business domains** accessible via domain hubs and navigation menus:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           BUSINESS DOMAIN HUBS                              │
├──────────────┬──────────────┬──────────────┬──────────────┬─────────────────┤
│ 1. Sales     │ 2. Purchase  │ 3. Inventory │ 4. Finance   │ 5. People (HR)  │
├──────────────┴──────────────┴──────────────┴──────────────┴─────────────────┤
│ 6. Organization & System Administration                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│ 7. Reports & Executive Desk (Dashboard)                                     │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

### 3.1 Organization & System Administration Domain

**Hub Route:** `/organization`  
**Purpose:** Multi-tenant setup, company profile, branches, user access, security roles, financial years, FX currencies, system settings, and auditing.

| Module / Feature | Package Path | Classification | RBAC Module | Shipped Status & Capabilities |
|---|---|---|---|---|
| **Company Profile** | `features/organization_company` | Master-CRUD | `CompanyProfile` | `[x]` View and update company identity, TRN, base currency, address block, bank details, BOM flag. |
| **Financial Year** | `features/organization_financial_year` | Master-CRUD | `FinancialYear` | `[x]` Financial year setup (Open/Closed/Locked status), set default year (`supportsDelete: false`). |
| **Branch** | `features/organization_branch` | Master-CRUD | `Branch` | `[x]` Multi-branch location setup with unique branch codes and soft delete. |
| **Currency** | `features/organization_currency` | Master-CRUD | `Currency` | `[x]` ISO currency master, symbol definition, decimal precision, base currency flag. |
| **Currency Rate** | `features/organization_currency_rate` | Master-CRUD | `CurrencyRate` | `[x]` Daily FX exchange rates (Buy/Sell/Mid rates), date-stamped history list and creation. |
| **Voucher Series** | `features/organization_voucher_series` | Master-CRUD | `VoucherSeries` | `[x]` Document numbering series configuration (prefix, starting number, length, approval requirement). |
| **User Role** | `features/organization_user_role` | Master-CRUD | `UserRole` | `[x]` Custom security role creation and description management. |
| **Permissions Matrix** | `features/organization_user_role` | System Service | `UserAccessPermission` | `[x]` Administrative grid to configure granular Create/Read/Update/Delete/Share permissions per role. |
| **User Credentials** | `features/organization_user` | Master-CRUD | `UserCredentials` | `[x]` System user management, username, role mapping, branch assignment, password management. |
| **Address Book (Contacts)** | `features/organization_address_book` | Master-CRUD | `AddressBook` | `[x]` Master directory for Customers, Vendors, Employees, and Individuals with phone, email, and address. |
| **Config Setting** | `features/organization_config` | Master-CRUD | `ConfigSetting` | `[x]` Key-value system configuration parameters with typed data formats (read and update). |
| **Project Master** | `features/organization_project` | Master-CRUD | `ProjectMaster` | `[x]` Project tracking master with self-referential parent project hierarchy, ledger/godown/contact FKs. |
| **Audit Log** | `features/organization_audit` | Read-only Log | `AuditLog` | `[x]` Read-only audit trail logging system events, client actions, timestamps, and data payloads. |
| **Error Reporting** | `features/organization_error_report` | Master-CRUD | `ErrorReporting` | `[x]` Client runtime error submission and administrative error log viewer. |
| **Extra Values (Custom KV)** | `features/organization` | Polymorphic Store | `ExtraValues` | `[!]` Deferred polymorphic custom key-value metadata store. |

---

### 3.2 Accounts & Financial Management Domain

**Hub Route:** `/accounts`  
**Purpose:** Chart of Accounts, general ledgers, sub-ledgers, party accounts, double-entry financial accounting, and cash/bank management.

| Module / Feature | Package Path | Classification | RBAC Module | Shipped Status & Capabilities |
|---|---|---|---|---|
| **Account Group** | `features/accounts_account_group` | Master-CRUD | `Accounts` | `[x]` Chart of Accounts tree structure with self-referential parent group selection (`FieldType.selfFk`). |
| **Ledger Master** | `features/accounts_ledger` | Master-CRUD | `Accounts` | `[x]` Core ledger accounts with opening/closing balances, currency, contact mapping, plus sub-tabs for Bank Details, Credit Settings, and Tax Settings. |
| **Ledger Bank Details** | `features/accounts_ledger` | 1:1 Sub-tab | `Accounts` | `[x]` Bank account number, IBAN, SWIFT code, and branch details embedded in Ledger form. |
| **Ledger Credit Settings** | `features/accounts_ledger` | 1:1 Sub-tab | `Accounts` | `[x]` Credit period (days), credit limit (amount), payment terms, and caution deposit embedded in Ledger form. |
| **Ledger Tax Settings** | `features/accounts_ledger` | 1:1 Sub-tab | `Accounts` | `[x]` Tax Registration Number (TRN), tax category link, and supply type embedded in Ledger form. |
| **Billwise Settlement** | `features/accounts` | Transaction Extension | `Accounts` | `[~]` Outstanding bill-by-bill allocation on Payment/Receipt vouchers and Against-Ref matching. |
| **Cheque Details** | `features/accounts` | Transaction Master | `Accounts` | `[ ]` Bank cheque, draft, and electronic instrument lifecycle tracking (issued, presented, cleared, returned). |

---

### 3.3 Inventory & Warehouse Management Domain

**Hub Route:** `/inventory`  
**Purpose:** Stock item catalog, SKU variants, batch tracking, warehouse godowns, units of measure, price lists, tax rules, and stock movements.

| Module / Feature | Package Path | Classification | RBAC Module | Shipped Status & Capabilities |
|---|---|---|---|---|
| **Inventory Item** | `features/inventory_item` | Master-CRUD | `Inventory` | `[x]` Master product catalog item with item code, group, brand, category, UOM, tax category, valuation method. |
| **Inventory Group** | `features/inventory_group` | Master-CRUD | `Inventory` | `[x]` Item classification tree hierarchy with self-referential parent group selection (`FieldType.selfFk`). |
| **SKU Master** | `features/inventory_sku` | Master-CRUD | `Inventory` | `[x]` Stock Keeping Units (SKU) linked to master items for variant management (barcode, code). |
| **Item Batch** | `features/inventory_batch` | Master-CRUD | `Inventory` | `[x]` Batch/lot tracking master with batch number, manufacturing date, and expiry date linked to items. |
| **Brand** | `features/inventory_brand` | Master-CRUD | `Inventory` | `[x]` Product brand registry (`supportsDelete: true` hard delete). |
| **Category** | `features/inventory_category` | Master-CRUD | `Inventory` | `[x]` Product category classification master (`supportsDelete: true` hard delete). |
| **Tax Category** | `features/inventory_tax_category` | Master-CRUD | `Inventory` | `[x]` Tax rates, tax codes, and VAT classification setup. |
| **Unit of Measure (UOM)** | `features/inventory_uom` | Master-CRUD | `Inventory` | `[x]` Master measurement units (Pcs, Kg, Box, Mtr, etc.). |
| **UOM Conversion** | `features/inventory_uom_conversion` | Master-CRUD | `Inventory` | `[x]` Multi-UOM conversion factors (e.g., 1 Box = 12 Pcs). |
| **Godown (Warehouse)** | `features/inventory_godown` | Master-CRUD | `Inventory` | `[x]` Physical warehouses, storage locations, and godown details. |
| **Price List** | `features/inventory_pricelist` | Master-CRUD | `Inventory` | `[x]` Selling/purchasing price lists and pricing rules. |
| **Route Master** | `features/inventory_route` | Master-CRUD | `Inventory` | `[x]` Delivery routes and logistics distribution paths. |
| **Item Property** | `features/inventory_item_property` | Master-CRUD | `Inventory` | `[x]` Custom dynamic item attribute specifications (`supportsUpdate: false`). |
| **Stock Ledger & Balance** | `features/inventory` | Read-only Views | `Inventory` | `[ ]` Read-only stock valuation, quantity-on-hand, and godown movement logs. |

---

### 3.4 People & Human Resources Domain

**Hub Route:** `/employee`  
**Purpose:** Organization structure, employee master records, leave management, shift scheduling, and HR administrative policies.

| Module / Feature | Package Path | Classification | RBAC Module | Shipped Status & Capabilities |
|---|---|---|---|---|
| **Employee Master** | `features/employee_employee` | Master-CRUD | `Employee` | `[x]` Employee profile master with Core info, Department/Designation FKs, plus sub-tabs for Bank Details and Salary Details. |
| **Department** | `features/employee_department` | Master-CRUD | `Employee` | `[x]` Organizational department master. |
| **Designation** | `features/employee_designation` | Master-CRUD | `Employee` | `[x]` Job designation master linked to Department via cross-module FK repository binder. |
| **Leave Policy** | `features/employee_leave_policy` | Master-CRUD | `Employee` | `[x]` HR leave policy rules, annual leave entitlement limits (create-only endpoint support). |
| **Leave Allocation** | `features/employee_leave_allocation` | Master-CRUD | `Employee` | `[x]` Annual/periodic leave quota allocation per employee. |
| **Leave Request** | `features/employee_leave_request` | Workflow Master | `Employee` | `[x]` Employee leave application lifecycle (Pending → Approved / Rejected / Canceled). |
| **Shift Master** | `features/employee_shift` | Master-CRUD | `Employee` | `[x]` Work shift schedules, start/end times, and break durations. |
| **Attendance & Roster** | `features/employee` | Log Master | `Employee` | `[ ]` Daily attendance logging, clock-in/out, and shift roster assignments. |
| **Payslip Processing** | `features/employee` | Document Master | `Employee` | `[ ]` Monthly salary payslip generation and payroll processing. |

---

### 3.5 Transactions & Document Vouchers Matrix

**Hub Routes:** `/sales`, `/purchase`, `/inventory`, `/accounts`, `/transactions`  
**Purpose:** Complete financial, trading, and inventory transaction lifecycle management.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          TRANSACTION ENGINES (17 TYPES)                     │
├───────────────────┬───────────────────┬───────────────────┬─────────────────┤
│ Sales Invoice     │ Item-Qty Engine   │ Ledger-Amount     │ Debit-Credit    │
│ (Gold Document)   │ (8 Vouchers)      │ (2 Vouchers)      │ (2 Vouchers)    │
│                   │ Quo / SO / PO /   │ Payment           │ Journal         │
│                   │ DelN / RecN / PI  │ Receipt           │ Contra          │
│                   │ Cr Note / Db Note │                   │                 │
├───────────────────┴───────────────────┴───────────────────┴─────────────────┤
│ Stock Engine (4 Vouchers): Godown Transfer, Material In, Requirement,       │
│ Stock Request (+ Fulfill UI)                                                │
└─────────────────────────────────────────────────────────────────────────────┘
```

| Voucher Type | Engine Family | Domain Hub | Shipped Status & Feature Capabilities |
|---|---|---|---|
| **Sales Invoice** | `sales_invoice` | Sales | `[x]` **Gold Standard:** Draft/Post/Edit lifecycle, Line Engine, PDF preview, Quotation/SO conversion, salesperson/project selection, instant GL/Stock booking. |
| **Quotation** | `item_qty` | Sales | `[x]` Sales quote creation, pricing estimation, customer selection, line items. |
| **Sales Order** | `item_qty` | Sales | `[x]` Customer sales order recording, line item processing, conversion to Delivery Note/SI. |
| **Delivery Note** | `item_qty` | Sales | `[x]` Goods dispatch note, stock reduction out of godown, optional SO conversion. |
| **Purchase Order** | `item_qty` | Purchase | `[x]` Supplier purchase order creation, line items, order status tracking. |
| **Receipt Note** | `item_qty` | Purchase | `[x]` Goods receipt note (GRN), inbound stock entry into godown, optional PO conversion. |
| **Purchase Invoice** | `item_qty` | Purchase | `[x]` Supplier bill recording, stock intake, supplier ledger credit. |
| **Credit Note** | `item_qty` | Sales | `[x]` Sales return / customer credit adjustment note with party ledger link. |
| **Debit Note** | `item_qty` | Purchase | `[x]` Purchase return / vendor debit adjustment note with party ledger link. |
| **Payment Voucher** | `ledger_amount` | Finance / Purchase | `[x]` Outgoing cash/bank payment voucher, party ledger debit, optional billwise allocation. |
| **Receipt Voucher** | `ledger_amount` | Finance / Sales | `[x]` Incoming cash/bank receipt voucher, party ledger credit, optional billwise allocation. |
| **Journal Voucher** | `debit_credit` | Finance | `[x]` General double-entry accounting journal adjustment with multi-row DR/CR validation. |
| **Contra Voucher** | `debit_credit` | Finance | `[x]` Cash-to-bank, bank-to-cash, or bank-to-bank money transfers with DR/CR balance check. |
| **Godown Transfer** | `stock` | Inventory | `[x]` Inter-warehouse stock transfer note (source godown → destination godown). |
| **Material In** | `stock` | Inventory | `[x]` Internal material inward adjustment note into warehouse. |
| **Requirement** | `stock` | Inventory | `[x]` Internal material requirement / requisition request note. |
| **Stock Request** | `stock` | Inventory | `[x]` Warehouse stock request with dedicated **Fulfill UI** workflow for store managers. |

---

### 3.6 Reports & Executive Intelligence Domain

**Hub Route:** `/reports`  
**Purpose:** Financial statements, transaction registers, inventory valuation, VAT returns, aging analysis, and executive dashboard analytics.

| Report Category | Key Reports Included (~49 Total Stamped Definitions) | Output Formats |
|---|---|---|
| **Financial Statements** | Trial Balance, Profit & Loss Statement (P&L), Balance Sheet, General Ledger Statement, Day Book. | Interactive Table, `.xlsx`, CSV, Print |
| **Sales Reports** | Sales Register, Sales Summary by Customer, Sales Summary by Item, Salesperson Performance, Quotation Register. | Interactive Table, `.xlsx`, CSV, Print |
| **Purchase Reports** | Purchase Register, Purchase Summary by Vendor, Purchase Order Tracking. | Interactive Table, `.xlsx`, CSV, Print |
| **Accounts & Receivables** | Accounts Receivable Aging, Accounts Payable Aging, Outstanding Bills, Ledger Balance Summary. | Interactive Table, `.xlsx`, CSV, Print |
| **Inventory Reports** | Stock Summary, Stock Valuation Report, Godown Balance, Batch Expiry Report, Reorder Level Alert Report. | Interactive Table, `.xlsx`, CSV, Print |
| **HR & Payroll Reports** | Employee Directory Summary, Leave Balance Summary, Monthly Attendance Register, Overtime Summary. | Interactive Table, `.xlsx`, CSV, Print |
| **Tax & VAT Reports** | VAT Return Summary (UAE FTA compliant VAT 201 format), Input Tax Register, Output Tax Register. | Interactive Table, `.xlsx`, CSV, Print |

---

### 3.7 Executive Dashboard ("Today's Desk")

**Route:** `/dashboard`  
**Purpose:** Operator home surface for real-time operational state, key metrics, quick actions, and visual data analytics.

- **Quiet Pulse KPIs:** Real-time revenue, total sales, purchases, outstanding receivables, and pending orders.
- **Live Alerts ("Needs You"):** Actionable list highlighting low stock items, pending approval vouchers, expiring documents, and overdue invoices.
- **Visual Analytics (`fl_chart`):**
  - Sales & Purchase financial trends (interactive line and bar charts via `GET /reports/dashboard/trend`).
  - Top selling product categories (donut chart breakdown).
  - Top performing customer accounts (ranked bar charts).
- **Recent Activity & Continue Chips:** Quick-resume shortcuts for recent vouchers and masters.

---

## 4. Backend API Contract & Integration Specifications

### 4.1 Connection Settings & Base URL
- **Dev Port:** `http://localhost:5000` (started via `make run-dev`)
- **Staging URL:** `https://staging-api.algoerp.internal` (`make run-staging`)
- **Production URL:** `https://api.algoerp.com` (`make run-prod`)
- **Mounting:** Routers mount directly at the root (e.g., `/auth`, `/organization`, `/accounts`, `/inventory`, `/employee`, `/transactions`, `/reports`). There is **no `/api/v1` prefix**.

### 4.2 Standard API Envelope
All REST API responses adhere to a consistent envelope structure:

```json
{
  "success": true,
  "message": "Operation completed successfully",
  "data": {
    "items": [...],
    "meta": {
      "total": 142,
      "page": 1,
      "limit": 20,
      "totalPages": 8
    }
  },
  "requestId": "req_8f9a2b1c"
}
```

Error responses return:

```json
{
  "success": false,
  "error": {
    "message": "Validation failed",
    "details": [
      { "path": "body.Company_Name", "message": "Company Name is required" }
    ]
  },
  "requestId": "req_8f9a2b1c"
}
```

### 4.3 Tenancy & Request Headers
- `Authorization`: `Bearer <jwt_token>` attached automatically by `AuthInterceptor`.
- `X-Company-Id`: Active tenant company ID header attached by `TenantInterceptor`.
- `X-Branch-Id`: Active branch location ID header attached by `TenantInterceptor`.
- `X-Request-Id`: Client trace request ID header for request correlation.

---

## 5. Development Workflow & Commands Reference

### 5.1 CLI Commands

```bash
# Bootstrap & dependencies
flutter pub get                                            # make bootstrap

# Code generation (Freezed, Injectable, Mapper)
dart run build_runner build --delete-conflicting-outputs   # make gen
dart run build_runner watch --delete-conflicting-outputs   # make gen-watch

# Static analysis & formatting
flutter analyze                                            # make analyze
dart format .                                              # strictly enforced on CI

# Automated testing
flutter test                                               # make test
flutter test test/features/auth/auth_bloc_test.dart        # run single test file

# Run application flavors
make run-dev        # lib/main_dev.dart (http://localhost:5000)
make run-staging    # lib/main_staging.dart
make run-prod       # lib/main_prod.dart
```

### 5.2 7-File Recipe for Adding a Master Entity

To add a new master entity `E` under `lib/features/<module>_<entity>/`:

1. `domain/<entity>.dart`: Equatable domain entity + `copyWith`.
2. `data/<entity>_dto.dart`: Wire DTO matching backend field casing.
3. `data/<entity>_mapper.dart`: DTO ↔ Entity mapper implementing `Mapper<Dto, Entity>`.
4. `<entity>_manifest.dart`: `EntityManifest<E>` defining metadata, fields, columns, and flags.
5. `<entity>_di.dart`: Factory functions `create<E>Repository()` and `create<E>CrudBloc()`.
6. `presentation/<entity>_list_page.dart`: Renders `MasterListSurface<E>`.
7. `presentation/<entity>_form_page.dart`: Renders `MasterFormSurface<E, ID>`.

Finally, register the 2 routes (`/<path>` and `/<path>/:id`) in `app_router.dart` and the tile in `menu_model.dart`.
