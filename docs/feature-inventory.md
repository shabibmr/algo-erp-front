# algoERP Backend — Feature Inventory

> Source: `E:\work\algo-backend\models\backend` — `prisma/schema.prisma`, `src/modules/**`,
> `src/core/**`, cross-checked against `BACKEND_CONTEXT.md`, `ERD.md`, `ENUMS.md`.
> Field names below are the **real** Prisma model/column names (mixed snake_case /
> PascalCase — this is a legacy MySQL schema surfaced through Prisma, not a clean rewrite).
> RBAC `module:action` values are the literal strings passed to `authorize(moduleName, action)`
> in the route files — these are the values the Flutter client must map permissions against.
>
> Classification legend:
> - **Master-CRUD** — list/detail/create/edit/(soft or hard)-delete, no lifecycle state machine.
> - **Voucher-document** — header (+ type-specific "main" row) + line items + lifecycle
>   state machine + GL/stock posting.

---

## 0. Cross-cutting conventions actually observed in code

- **Auth**: JWT bearer (`Authorization: Bearer <token>`), see `api-contract.md`.
- **RBAC**: `authorize(moduleName, action)` middleware (`src/core/middleware/authorize.ts`)
  checks `user_access_permissions` (`Allow_Create/Read/Update/Delete/Share`) for
  `req.user.roleId` + `moduleName`. Deny-by-default (no row ⇒ false). Cached per role in-process.
- **Pagination**: `BaseRepository.findMany` and the voucher-read `parsePage()` helper both
  default `page=1`, `limit=20` (voucher lists cap `limit` at 200); response is
  `{ items, meta: { total, page, limit, totalPages } }`.
- **Soft delete**: `BaseRepository` defaults `softDeleteField: 'is_active'` but **not every
  model has `is_active`** — e.g. `brands`, `category`, `account_groups`,
  `ledger_bank_details/credit_settings/tax_settings`, `sales_invoice_main` and most
  voucher "main" tables have **no `is_active` column**; their repositories are configured
  with `softDeleteField: null` and their "delete" is a **hard delete**
  (confirmed for `BrandRepository`: `softDeleteField: null`, and `BrandService.deleteBrand`
  calls `.delete(id, { hardDelete: true })`).
- **Audit fields**: physical column names vary per table (`created_at`/`updated_at`,
  `Date_Created`/`Last_Modified`, `TimeStamp`, `timestamp` …) — `BaseRepository.auditFieldMap`
  maps them per repository instance.

---

## 1. Domain: Organization & System

Routes: `organization.routes.ts`, mounted at `/organization` (auth required on all).

### Entities

| Entity | Table | Classification | Key fields (real names) | Enums | FKs |
|---|---|---|---|---|---|
| CompanyProfile | `companyprofile` | Master-CRUD (no soft-delete field, no `created_at`/`updated_at` at all) | `id`(`_id`), `Company_Name`, `Branch`, `TRN`, `Currency`, `Currency_Decimal` (int, default 2), `Logo` (Bytes), `UseBom` (bool), address block (`AddressLine`,`City`,`Country`,`Building`,`POBox`,`Street`), `Bank_Details` | — | none |
| FinancialYear | `financialyear` | Master-CRUD | `id`, `fy_code`, `display_name`, `start_date`, `end_date`, `status` (enum), `is_default`, `company_id`, `added_by`, `created_at`, `updated_at` | `financialyear_status` = `Open`\|`Closed`\|`Locked` | `company_id`→companyprofile (no DB FK enforced in schema shown) |
| Branch | `branch` | Master-CRUD (soft-delete via `is_active`) | `id`, `branch_code` (unique), `branch_name`, `company_id`, `address`, `is_active`, `created_at`, `updated_at` | — | `company_id` |
| Currency | `currencymaster` | Master-CRUD | `id`, `iso_code` (unique, char3), `currency_name`, `symbol`, `decimal_places`, `is_base_currency`, `is_active`, `created_at`, `updated_at` | — | — |
| CurrencyRate | `currencyrates` | Master-CRUD (append-style; no soft-delete field) | `id`, `currency_id`, `rate_date`, `buy_rate`/`sell_rate`/`mid_rate` (`Decimal(18,6)`), `financial_year_id`, `added_by`, `created_at`. Unique `(currency_id, rate_date)` | — | `currency_id`, `financial_year_id` |
| VoucherSeries | `voucherseries` | Master-CRUD | `id`, `voucher_type`, `prefix`, `display_name`, `company_id`, `branch_id`, `financial_year_id`, `number_length` (default 5), `prefix_separator` (default `/`), `starting_number`, `is_default`, `is_active`, `require_approval`, `created_at`, `updated_at`. Unique `(voucher_type, prefix, company_id)` | — | company/branch/FY |
| UserRole | `user_roles` | Master-CRUD | `id`, `role_name` (unique), `description`, `created_at`, `updated_at` | — | — |
| UserCredentials | `user_credentials` | Master-CRUD | `id`, `contact_id` (unique, 1:1→address_book), `username` (unique), `password_hash`, `role_id`, `is_active`, `last_login_at`, `created_at`, `updated_at`, `employee_id`, `branch_id`, `password_changed_at`, `default_voucher_prefix`, `allow_all_prefix` | — | `contact_id`, `role_id`, `branch_id` |
| UserAccessPermission | `user_access_permissions` | Master-CRUD (upsert-per-role via `/roles/:roleId/permissions`) | `id`, `role_id`, `module_name`, `Allow_Create/Read/Update/Delete/Share` (bool), `Extras` (LongText) | — | `role_id` |
| ConfigSetting | `config_settings` | Master-CRUD (key-value; read/update only, no create route) | `id`, `gm_key` (unique), `gm_value`, `Data_Type`, `is_logged`, `created_at`, `updated_at` | data_type: string/integer/float/boolean/json/date (per ENUMS.md; column is free string `Data_Type`) | — |
| AddressBook | `address_book` | Master-CRUD | `id`, `contact_type` (enum), `Name`, `Email`, `Company_Name`, `Phone_Number`, `Mobile_Number`, full address block, `isActive` (bool, default **false** — note: default is false, not true), `Contact_Uuid`, `CustomerCode`, `Route` | `address_book_contact_type` = `INDIVIDUAL`\|`COMPANY`\|`VENDOR`\|`EMPLOYEE`\|`OTHER` | — |
| ProjectMaster | `project_master` | Master-CRUD, self-referential | `id`, `project_code` (unique), `parent_project_master_id` (self-FK), `project_owner_contact_id`, `associated_ledger_id`, `godown_id`, `coordinator_employee_id`, `Project_Name`, `Project_Status`, `Start_Date`/`End_Date`, `Estimated_Value`, `created_at`, `updated_at` | `Project_Status`: Pending/Active/On Hold/Completed/Cancelled (free string) | soft-FKs: ledger/godown/employee; hard self-FK parent |
| AuditLog | `log` | Read-only log | `id`(`_id`), `timestamp` (unique), `data` (JSON string), `action`, `status`, `client_id` | action: CREATE/UPDATE/DELETE/LOGIN/LOGOUT/EXPORT/PRINT/APPROVE/CANCEL/OTHER | — |
| ErrorReporting | `error_reporting` | Master-CRUD (create is open to any authenticated user; list is RBAC'd) | `id`, `error` (LongText), `tablename`, `query` (LongText), `time_stamp`, `client_id` | — | — |
| ExtraValuesTable | `extra_values_table` | Polymorphic KV store, keyed `(TYPE, OBJECT_ID)` | `id`(`_id`), `TYPE`, `OBJECT_ID`, `DATA` (LongText/JSON), `ADDED_BY`, `LAST_MODIFIED`, `HASH_TAGS` | — | — |

### Endpoint table (`/organization`)

| Method | Path | RBAC | Purpose |
|---|---|---|---|
| GET | `/companies` | `CompanyProfile:read` | List company profiles |
| GET | `/company/:id` | `CompanyProfile:read` | Get one company profile |
| PUT | `/company/:id` | `CompanyProfile:update` | Update company profile |
| POST | `/companies` | `CompanyProfile:create` | Provision a new company |
| GET | `/fy` | `FinancialYear:read` | List financial years |
| POST | `/fy` | `FinancialYear:create` | Create financial year |
| PUT | `/fy/:id` | `FinancialYear:update` | Update / set-default / lock financial year |
| GET | `/branches` | `Branch:read` | List branches |
| POST | `/branches` | `Branch:create` | Create branch |
| PUT | `/branches/:id` | `Branch:update` | Update branch |
| DELETE | `/branches/:id` | `Branch:delete` | Soft-delete branch |
| GET | `/currencies` | `Currency:read` | List currencies |
| POST | `/currencies` | `Currency:create` | Create currency |
| PUT | `/currencies/:id` | `Currency:update` | Update currency |
| DELETE | `/currencies/:id` | `Currency:delete` | Soft-delete currency |
| GET | `/rates` | `CurrencyRate:read` | Get FX rate(s) |
| POST | `/rates` | `CurrencyRate:create` | Post daily FX rate |
| GET | `/voucher-series` | `VoucherSeries:read` | List voucher numbering series |
| GET | `/voucher-series/:id` | `VoucherSeries:read` | Get one series |
| POST | `/voucher-series` | `VoucherSeries:create` | Create series |
| PUT | `/voucher-series/:id` | `VoucherSeries:update` | Update series |
| DELETE | `/voucher-series/:id` | `VoucherSeries:delete` | Delete series |
| GET | `/contacts` | `AddressBook:read` | List contacts |
| GET | `/contacts/search` | `AddressBook:read` | Search contacts |
| GET | `/contacts/:id` | `AddressBook:read` | Get contact |
| POST | `/contacts` | `AddressBook:create` | Create contact |
| PUT | `/contacts/:id` | `AddressBook:update` | Update contact |
| DELETE | `/contacts/:id` | `AddressBook:delete` | Delete contact |
| GET | `/config` | `ConfigSetting:read` | List config settings |
| GET | `/config/:key` | `ConfigSetting:read` | Get one setting (typed) |
| PUT | `/config/:key` | `ConfigSetting:update` | Update a setting value |
| GET | `/extras/:type/:objectId` | `ExtraValues:read` | Get custom attributes for any entity |
| PUT | `/extras/:type/:objectId` | `ExtraValues:update` | Set custom attributes |
| GET | `/audit-logs` | `AuditLog:read` | Read audit trail |
| GET | `/roles` | `UserRole:read` | List roles |
| GET | `/roles/:roleId` | `UserRole:read` | Get role |
| POST | `/roles` | `UserRole:create` | Create role |
| PUT | `/roles/:roleId` | `UserRole:update` | Update role |
| DELETE | `/roles/:roleId` | `UserRole:delete` | Delete role |
| PUT | `/roles/:roleId/permissions` | `UserAccessPermission:update` | Set per-module CRUD flags for a role |
| GET | `/users` | `UserCredentials:read` | List users |
| GET | `/users/:id` | `UserCredentials:read` | Get user |
| POST | `/users` | `UserCredentials:create` | Create user |
| PUT | `/users/:id` | `UserCredentials:update` | Update user |
| DELETE | `/users/:id` | `UserCredentials:delete` | Deactivate user |
| GET | `/projects` | `ProjectMaster:read` | List projects |
| GET | `/projects/:id` | `ProjectMaster:read` | Get project |
| POST | `/projects` | `ProjectMaster:create` | Create project |
| PUT | `/projects/:id` | `ProjectMaster:update` | Update project |
| DELETE | `/projects/:id` | `ProjectMaster:delete` | Delete project |
| POST | `/error-reports` | *(authenticated only, no authorize check)* | Client submits an error report |
| GET | `/error-reports` | `ErrorReporting:read` | List error reports |

---

## 2. Domain: Accounts

Routes: `accounts.routes.ts`, mounted at `/accounts`. **All accounts endpoints use a single
coarse RBAC module `Accounts:{create|read|update|delete}` — there is no per-sub-entity RBAC
split** (unlike Organization/Inventory which split by entity).

### Entities

| Entity | Table | Classification | Key fields | Enums | FKs |
|---|---|---|---|---|---|
| AccountGroup | `account_groups` | Master-CRUD, self-referential (**no `is_active` field** — hard-delete or restrict-only) | `id`, `group_code`, `parent_group_id` (self), `Group_Name`, `is_system_defined`, `created_at`, `updated_at` | nature/group_behavior documented conceptually (`Assets/Liabilities/Income/Expense/Capital`, `Debit/Credit`) but **not present as distinct columns in the live schema** — treat as app-level convention layered on `Group_Name`/hierarchy | self `parent_group_id` |
| LedgerMaster | `ledger_master` | Master-CRUD (soft-delete via `is_active`) | `id`, `ledger_code`, `account_group_id`, `Ledger_Name`, `Ledger_Type`, `contact_id` (soft-FK→address_book), `parent_ledger_id` (self), `currency_code` (default `AED`), `is_system_defined`, `is_active`, `Opening_Balance` (**stored as `String`, not Decimal** — app must parse), `Closing_Balance` (Float), `Credit_Period`, `Credit_Limit` (Float), `TRN`, `Date_Created`, `Last_Modified` | `Ledger_Type` free string per ENUMS.md set (SundryDebtor/SundryCreditor/Bank/Cash/Expense/Income/Tax/FixedAsset/Capital/DutyTax/Stock/Other) | `account_group_id`, `contact_id`(soft), `parent_ledger_id`(self) |
| LedgerBankDetails | `ledger_bank_details` | 1:1 extension (shares PK `ledger_id`) | `ledger_id`(PK/FK), `bank_account_number`, `iban`, `swift_code`, `bank_branch_name` | — | `ledger_id`→ledger_master (Cascade) |
| LedgerCreditSettings | `ledger_credit_settings` | 1:1 extension | `ledger_id`(PK/FK), `credit_period_days`, `credit_limit` (`Decimal(15,2)`), `payment_terms`, `caution_deposit` (`Decimal(15,2)`) | — | `ledger_id` |
| LedgerTaxSettings | `ledger_tax_settings` | 1:1 extension | `ledger_id`(PK/FK), `trn`, `tax_category_id` (soft-FK), `type_of_supply` | — | `ledger_id`; soft-FK `tax_category_id`→tax_categories |
| BillwiseRecord | `billwise_records` | Master-CRUD / ledger-derived record | `id`(`_id`), `voucherPrefix`, `VoucherType`, `VoucherNo`, `LedgerID` (**legacy string**, not int FK), `RefType`, `RefNo`, `RefPrefix`, `DebitAmount`/`CreditAmount` (Float), `VoucherDate`, `Due_Date`, `Method_of_adj`, `Salesman_ID` (soft-FK) | `RefType`: New Ref / Agst Ref / Advance / On Account | soft-FK `LedgerID` (string) |
| ChequeDetails | `cheque_details` | Master-CRUD | `id`(`_id`), `ledger_id` (**string**, legacy), `Instrument_Type`, `Instrument_No`, `Issued_On`/`Presented_On`/`Cleared_On`/`Instrument_Date`/`Reconciled_On`, `is_Presented`/`is_Cleared`/`is_Returned`, `debit_amount`/`credit_amount` (`Decimal(10,2)`), `Our_Bank_ID` (soft-FK, string) | `Instrument_Type`: Cheque/DD/NEFT/RTGS/Other | soft-FK ledger/bank |

### Endpoint table (`/accounts`)

| Method | Path | RBAC | Purpose |
|---|---|---|---|
| GET | `/groups` | `Accounts:read` | List account groups |
| GET | `/groups/:id` | `Accounts:read` | Get account group |
| POST | `/groups` | `Accounts:create` | Create account group |
| PUT | `/groups/:id` | `Accounts:update` | Update account group |
| DELETE | `/groups/:id` | `Accounts:delete` | Delete account group |
| GET | `/ledgers` | `Accounts:read` | List ledgers |
| GET | `/ledgers/:id` | `Accounts:read` | Get ledger |
| POST | `/ledgers` | `Accounts:create` | Create ledger (+ extensions) |
| PUT | `/ledgers/:id` | `Accounts:update` | Update ledger |
| DELETE | `/ledgers/:id` | `Accounts:delete` | Soft-delete ledger |
| GET | `/ledgers/:id/balance` | `Accounts:read` | Computed effective balance |
| GET/PUT | `/ledgers/:id/bank` | `Accounts:read`/`update` | LedgerBankDetails get/upsert |
| GET/PUT | `/ledgers/:id/credit` | `Accounts:read`/`update` | LedgerCreditSettings get/upsert |
| GET/PUT | `/ledgers/:id/tax` | `Accounts:read`/`update` | LedgerTaxSettings get/upsert |
| GET | `/billwise/ledger/:ledgerId` | `Accounts:read` | Bill-wise records for a ledger |
| GET | `/billwise/:id` | `Accounts:read` | Get one bill-wise record |
| POST | `/billwise` | `Accounts:create` | Create bill-wise record |
| PUT | `/billwise/:id` | `Accounts:update` | Update / settle bill-wise record |
| GET | `/cheque/ledger/:ledgerId` | `Accounts:read` | Cheques for a ledger |
| GET | `/cheque/:id` | `Accounts:read` | Get cheque |
| POST | `/cheque` | `Accounts:create` | Register cheque/PDC |
| PUT | `/cheque/:id` | `Accounts:update` | Update cheque (present/clear/return) |
| GET | `/outstanding/:ledgerId` | `Accounts:read` | Outstanding balance for ledger |
| GET | `/aging` | `Accounts:read` | Ageing report |

---

## 3. Domain: Inventory

Routes: `inventory.routes.ts`, mounted at `/inventory`. RBAC uses a single coarse
`Inventory:{action}` module for every sub-entity, same pattern as Accounts.

### Entities

| Entity | Table | Classification | Key fields | Enums | FKs |
|---|---|---|---|---|---|
| UOM | `uomlist` | Master-CRUD | `id`, `UOM_id`, `uom_code`, `uom_Name`, `decimal_places`, `uom_symbol`, `is_Composite`, `SubUom`, `created_at`, `updated_at` | — | — |
| InventoryGroup | `sales_inventory_groups` | Master-CRUD, self-referential | `id`, `group_code` (unique), `parent_group_id` (self), `Group_ID`, `Group_Name` (unique), `Group_Type`, `created_at`, `updated_at`, `Last_Modified` | — | self |
| Brand | `brands` | Master-CRUD, **hard delete** (no `is_active`) | `id`, `Brand_Name` (unique), `Brand_Description`, `created_at`, `updated_at`, `Last_Modified` | — | — |
| Category | `category` | Master-CRUD, **hard delete** (no `is_active`) | `id`, `category_code` (unique), `category_name`, `Description`, `created_at`, `updated_at` | — | — |
| TaxCategories | `tax_categories` | Master-CRUD (soft-delete via `is_active`) | `id`, `tax_name` (unique), `tax_rate` (`Decimal(5,2)`), `is_active`, `created_at`, `updated_at` | — | — |
| InventoryItem | `sales_inventory_items` | Master-CRUD (soft-delete via `is_active`) | `id`, `Item_Name`, `Item_Code` (unique), `Part_Number`, `inventory_group_id`, `uom_id`, `inventory_brand_id`, `category_id`, `Price` (Float), `base_price`/`standard_cost`/`moving_average_cost` (Decimal), `Opening_Stock`, `Reorder_Level`, flags `is_purchase_item/is_sales_item/is_stock_item/is_serialized/is_batch_tracked/is_perishable/is_service`, soft-FK GL ledgers (`sales_gl_ledger_id`, `default_purchase_ledger_id`, `default_sales_return_ledger_id`, `default_purchase_return_ledger_id`), `default_tax_category_id`, `Vat_Rate`, `created_at`, `updated_at` | — | group/uom/brand/category (hard FK); GL ledgers/tax category (hard FK in this schema, though conceptually "soft") |
| SKUMaster | `sku_master` | Master-CRUD | `id`, `sku_code`, `inventory_item_id`, `sku_name`, `barcode`, `rate` (`Decimal(15,2)`), `SKU_TYPE` (int code), `SKU_POSSIBLE_VALUES` (JSON text), `created_at`, `updated_at` | `SKU_TYPE`: 1=Variant, 2=Bundle, 3=Alternate Unit | `inventory_item_id` |
| ItemBatch | `item_batches` | Master-CRUD (soft-delete via `is_active`) | `id`, `item_id`, `batch_number`, `manufacturing_date`, `expiration_date`, `cost_price` (`Decimal(15,4)`), `selling_price` (`Decimal(15,2)`), `is_active`, `created_at`, `updated_at`. Unique `(item_id, batch_number)` | — | `item_id` |
| ItemProperty | `sales_inventory_item_properties` | Master-CRUD | `id`(`_id`), `Property_ID`, `Item_ID`, `Default_Value` | — | — |
| ItemImage | `sales_inventory_images` | Master-CRUD | `id`(`_id`), `Item_Id`, `Image` (Bytes), `width`/`height`, `type`, `FileName` | — | — |
| LedgerItemMapping | `ledger_item_mapping` | Master-CRUD | `id`(`_id`), `Ledger_Id` (string), `Item_Id` (string) | — | soft-FK both sides |
| Ingredient (BOM) | `ingredients` | Master-CRUD | `id`, `sales_item_id`, `purchase_item_id`, `purchase_uom_id`, `prep_route_id`, `sales_item_qty`/`purchase_item_qty` (`Decimal(12,4)`), `take_away_applicable` | — | items/uom/route |
| Godown | `godown` | Master-CRUD | `id`, `godown_code` (unique), `Godown_Name`, `Godown_Location`, `is_profit_centre`, `is_default`, `is_production`, `created_at`, `updated_at` | — | — |
| StockLedger | `stock_ledger` | Append-only ledger (not user-editable) | `id`, `voucher_header_id`, `item_id`, `sku_id`, `batch_id`, `godown_id`, `quantity_in`/`quantity_out` (XOR invariant), `unit_cost`, `total_cost`, `posting_date` | — | voucher/item/sku/batch/godown |
| UOMConversion | `uom_conversion` | Master-CRUD | `id`(`_id`), `baseUnit`, `toUnit`, `conValue` (string!), `itemID`, `barcode` | — | — |
| PriceList | `price_lists` | Master-CRUD | `Price_List_ID`(PK), `Price_List_Name`, `Price_List_Start_Date`/`End_Date`, `Price_List_Default`, `Price_List_ShowInPos`, `Price_List_isOnline`, `Last_Modified` | — | — |
| PriceListEntry | `pricelist_entries` | Master-CRUD | `id`(`_id`), `Item_Id` (string), `Price` (Float), `Price_List_ID`, `MRP2_STD1_CUS0` (int code), `timestamp` | `MRP2_STD1_CUS0`: 0=Custom,1=Standard,2=MRP | soft-FK item, hard FK price list |
| RouteMaster | `route_master` | Master-CRUD | `id`, `route_id`, `route_name`, `Description` | — | — |
| RouteCustomerMapping | `route_customer_mapping` | Master-CRUD | `id`, `route_master_id`, `customer_ledger_id`, `Ledger_ID` (string dup), `Last_Update_timestamp` | — | route + ledger |
| RouteMapping | `route_mapping` | Master-CRUD | `id`, `route_master_id`, `salesperson_employee_id`, `Day_Of_Week`, `Date_Created`, `Last_Modified` | `Day_Of_Week`: Monday..Sunday | route + employee |

### Endpoint table (`/inventory`)

| Method | Path | RBAC | Purpose |
|---|---|---|---|
| GET/POST/PUT/DELETE | `/uom`, `/uom/:id` | `Inventory:{read/create/update/delete}` | UOM CRUD |
| GET/POST/PUT/DELETE | `/brand`, `/brand/:id` | same | Brand CRUD |
| GET/POST/PUT/DELETE | `/category`, `/category/:id` | same | Category CRUD |
| GET/POST/PUT/DELETE | `/tax-category`, `/tax-category/:id` | same | Tax category CRUD |
| GET/POST/PUT/DELETE | `/group`, `/group/:id` | same | Inventory group CRUD |
| GET/POST/PUT/DELETE | `/item`, `/item/:id` | same | Inventory item CRUD |
| GET/POST/PUT/DELETE | `/sku`, `/sku/:id` | same | SKU CRUD |
| GET/POST/PUT/DELETE | `/batch`, `/batch/:id` | same | Item batch CRUD |
| GET/POST/DELETE | `/property`, `/property/:id` | same | Item property CRUD (no update route) |
| GET/POST/DELETE | `/image`, `/image/:id` | same | Item image CRUD (no update route) |
| GET | `/ingredient/recipe/:salesItemId` | `Inventory:read` | Recipe (BOM) for a finished item |
| GET | `/ingredient/usage/:purchaseItemId` | `Inventory:read` | Where a raw material is used |
| GET/POST/PUT/DELETE | `/ingredient`, `/ingredient/:id` | `Inventory:{action}` | Ingredient CRUD |
| GET/POST/PUT/DELETE | `/godown`, `/godown/:id` | same | Godown CRUD |
| GET | `/conversion/lookup` | `Inventory:read` | Convert qty between units |
| GET/POST/PUT/DELETE | `/conversion`, `/conversion/:id` | same | UOM conversion CRUD |
| GET | `/pricelist/effective-price` | `Inventory:read` | Effective price resolution |
| GET/POST/PUT/DELETE | `/pricelist`, `/pricelist/:id` | same | Price list CRUD |
| GET/POST/PUT/DELETE | `/pricelist-entry`, `/pricelist-entry/:id` | same | Price list entry CRUD (no plain list route, only `/:id`) |
| GET | `/route/salesman/:employeeId` | `Inventory:read` | Route schedule for a salesperson |
| GET | `/route/customers/:routeId` | `Inventory:read` | Customers on a route |
| GET/POST/DELETE | `/route/customer-mapping`, `/route/customer-mapping/:id` | `Inventory:{action}` | Route↔customer CRUD |
| GET/POST/DELETE | `/route/mapping`, `/route/mapping/:id` | same | Route↔salesperson CRUD |
| GET/POST/PUT/DELETE | `/route`, `/route/:id` | same | RouteMaster CRUD |
| GET | `/ledger-item-mapping/check` | `Inventory:read` | Check if ledger↔item allowed |
| GET | `/ledger-item-mapping/ledger/:ledgerId` | `Inventory:read` | Allowed items for a ledger |
| GET | `/ledger-item-mapping/item/:itemId` | `Inventory:read` | Allowed ledgers for an item |
| GET/POST/DELETE | `/ledger-item-mapping`, `/ledger-item-mapping/:id` | `Inventory:{action}` | Mapping CRUD |
| GET | `/stock-ledger/:itemId` | `Inventory:read` | Stock movement history for item |
| GET | `/stock-ledger/godown/:godownId` | `Inventory:read` | Stock movements at a godown |
| GET | `/stock-balance` | `Inventory:read` | Current stock balance (query params) |
| GET | `/stock-balance/:itemId/by-godown` | `Inventory:read` | Balance for item split by godown |

---

## 4. Domain: Employee (HR)

Routes: `employee.routes.ts`, mounted at `/employee`. RBAC uses a single coarse
`Employee:{action}` module for all sub-entities.

### Entities

| Entity | Table | Classification | Key fields | Enums |
|---|---|---|---|---|
| Department | `department` | Master-CRUD, self-referential | `id`, `dept_code` (unique), `dept_name`, `parent_dept_id`, `is_active`, `created_at`/`updated_at`, `added_by`/`last_modified_by` | — |
| Designation | `designation` | Master-CRUD | `id`, `designation_code` (unique), `designation_name`, `department_id`, `is_active` | — |
| EmployeeDetails | `employee_details` | Master-CRUD | `id`, `employee_code`, `contact_id` (unique, 1:1 addr book), `Name`, `Gender`, `Marital_Status`, `designation_id`, `department_id`, `Date_of_Joining`, `Biometric_ID`, huge set of document fields duplicated on the main row (`Passport_No/Expiry`, `Visa_No/Expiry`, `Emirates_ID*`, `Labour_Card*`, `Driving_License*`, `Health_Card*`, `Airport_Pass*` — **note: these duplicate `employeedocuments`, a legacy/normalized overlap**), `is_active`, `created_at`/`updated_at` | Gender: Male/Female/Other (free string); Marital_Status: Single/Married/Divorced/Widowed |
| EmployeeDocument | `employeedocuments` | Master-CRUD | `id`, `employee_id`, `doc_type` (real Prisma enum), `doc_number`, `issue_date`/`expiry_date`, `visa_status`/`visa_sponsor`, `file_path`. Unique `(employee_id, doc_type)`, indexed on `expiry_date` | `employeedocuments_doc_type`: Passport/Visa/EmiratesID/LabourCard/DrivingLicense/HealthCard/AirportPass/Other |
| EmployeeBankDetails | `employeebankdetails` | 1:1 extension | `employee_id`(unique/FK), `bank_name`, `account_number`, `iban`, `swift_code`, `account_type` (free string), `is_active` | account_type: Savings/Current/WPS (per ENUMS.md) |
| EmployeeSalaryDetails | `employee_salary_details` | 1:1-ish extension (keyed by `salary_employee_id`, plus legacy unique `Employee_Id` string) | `salary_employee_id`, `adv_salary_ledger_id`/`salary_ledger_id` (soft/hard FK), `overtime_hourly_rate`, `Basic_Salary`, `DA`, `HRA`, `Conveyance`, `Monthly_Leave`/`Weekly_Leave`/`Annual_Leave`, `Working_Hours`, `OverTime_Pay` | — |
| SalaryRevisionHistory | `salaryrevisionhistory` | Append-only audit | `id`, `employee_id`, `revision_date`, `basic_salary_before/after`, `gross_before/after`, `revision_reason`, `revised_by` | — |
| LeavePolicy | `leavepolicy` | Master-CRUD | `id`, `leave_type` (unique), `display_name`, `max_days_per_year`, `carry_forward_limit`, `requires_approval`, `is_paid`, `applicable_gender`, `is_active` | leave_type free string per ENUMS.md set |
| LeaveAllocation | `leaveallocation` | Master-CRUD | `id`, `employee_id`, `leave_policy_id`, `year`, `allocated_days`/`carried_forward`/`used_days` (`Decimal(6,1)`). Unique `(employee_id, leave_policy_id, year)` | — |
| LeaveRequest | `leaverequest` | Voucher-like approval workflow (no GL/stock posting, but has a status machine) | `id`, `employee_id`, `leave_policy_id`, `from_date`/`to_date`, `number_of_days`, `status` (real Prisma enum), `approved_by`, `approved_at`, `rejection_reason` | `leaverequest_status`: Pending/Approved/Rejected/Cancelled |
| AttendanceDetails | `attendance_details` | Master-CRUD (daily log, unique per employee+date via app logic) | `id`, `attendance_employee_id`, `working_date`, `check_in_time`/`check_out_time`, `Working_Hours`, `overtime_hours`, `status` (real Prisma enum), `HalfDay`, `leave_request_id` | `attendance_details_status`: PRESENT/ABSENT/HALFDAY/LEAVEPAID/LEAVEUNPAID/HOLIDAY |
| ShiftMaster | `shiftmaster` | Master-CRUD | `id`, `shift_code` (unique), `shift_name`, `start_time`/`end_time`, `working_hours` (`Decimal(4,1)`), `break_minutes`, `is_night_shift`, `is_active` | — |
| EmployeeShiftAssignment | `employeeshiftassignment` | Master-CRUD (date-ranged) | `id`, `employee_id`, `shift_id`, `valid_from`, `valid_to` (null=open-ended) | — |
| PayslipMain | `payslip_main` | Voucher-like header (no separate detail table found; likely computed) | `id`(`_id`), `Employee_Id`, `Voucher_No`/`Type`/`Prefix`, `Salary_Period_Start`/`End`, `Date_Created`, `Created_By` | — |

### Endpoint table (`/employee`)

| Method | Path | RBAC | Purpose |
|---|---|---|---|
| GET/POST/PUT/DELETE | `/departments`, `/departments/:id` | `Employee:{action}` | Department CRUD |
| GET/POST/PUT/DELETE | `/designations`, `/designations/:id` | same | Designation CRUD |
| GET/POST/PUT/DELETE | `/employees`, `/employees/:id` | same | Employee CRUD |
| GET | `/employees/:id/salary-history` | `Employee:read` | Salary revision history |
| POST | `/employees/:id/documents` | `Employee:create` | Add employee document |
| PUT | `/documents/:docId` | `Employee:update` | Update document |
| GET | `/documents/expiries` | `Employee:read` | Upcoming document expiries (alerting) |
| GET | `/leave/policies` | `Employee:read` | List leave policies |
| POST | `/leave/policies` | `Employee:create` | Create leave policy |
| POST | `/leave/allocations` | `Employee:create` | Allocate leave to employee |
| GET | `/employees/:id/leave-allocations` | `Employee:read` | Allocations for employee |
| POST | `/employees/:id/leave-requests` | `Employee:create` | Submit leave request |
| PUT | `/leave-requests/:requestId` | `Employee:update` | Approve/reject/cancel leave request |
| GET | `/leave-requests` | `Employee:read` | List leave requests |
| POST | `/employees/:id/attendance` | `Employee:create` | Log attendance for a day |
| GET | `/employees/:id/roster` | `Employee:read` | Monthly attendance roster |
| POST | `/shifts` | `Employee:create` | Create shift |
| GET | `/shifts` | `Employee:read` | List shifts |
| POST | `/employees/:id/shift` | `Employee:create` | Assign shift to employee |
| GET | `/employees/:id/shift-roster` | `Employee:read` | Employee's shift roster |
| POST | `/payslips` | `Employee:create` | Create payslip |
| GET | `/payslips/:id` | `Employee:read` | Get payslip |
| GET | `/employees/:employeeId/payslips` | `Employee:read` | Payslips for employee |
| GET | `/payslips` | `Employee:read` | Payslips by period |
| POST | `/employees/:id/salary-revision` | `Employee:update` | Record salary revision |
| GET | `/employees/:id/salary-revisions` | `Employee:read` | Salary revision list |
| GET | `/employees/:id/attendance-summary` | `Employee:read` | Attendance summary |
| GET | `/reports/overtime` | `Employee:read` | Overtime report |

---

## 5. Domain: Transactions (Vouchers) — the heart of the system

Routes span 6 files mounted at `/transactions` and `/reports`:
- `transactions.routes.ts` — POST-only "classic" voucher posting (SalesInvoice, PurchaseInvoice, Payment, Receipt, Contra, Journal, CreditNote, DebitNote)
- `phase4.routes.ts` — POST for order/stock vouchers (Quotation, SalesOrder, PurchaseOrder, GodownTransfer, DeliveryNote, ReceiptNote, MaterialIn, Requirement, StockRequest) + financial reports
- `voucherRead.routes.ts` — GET (list/detail) for every voucher type above
- `voucherLifecycle.routes.ts` — generic edit/cancel/approve/reject by `:type/:id`
- `ancillary.routes.ts` — TermsAndConditions, TransportationDetails
- `reports.routes.ts` (mounted at `/transactions/reports`) + `dashboard.routes.ts` (mounted at `/reports`)

### 5.1 Voucher structure (confirmed in code, `voucherPosting.service.ts` / `voucherLifecycle.service.ts`)

Every voucher = **`voucher_headers`** row (`voucher_type`, `voucher_prefix`, `voucher_no`,
`voucher_date`, `created_at`, `updated_at`; unique `(voucher_type, voucher_prefix, voucher_no)`)
**+ a type-specific "main" row sharing the header's PK** (e.g. `sales_invoice_main`) **+ N
detail/line rows** (e.g. `sales_invoice_details`, referencing `voucher_id`).

`VOUCHER_META` map in `voucherLifecycle.service.ts` (real code, not inferred) — this is the
authoritative type→table map and GL/stock-affecting flags:

| voucher_type | mainModel | detailModel | glAffecting | stockAffecting |
|---|---|---|---|---|
| SalesInvoice | sales_invoice_main | sales_invoice_details | yes | yes |
| PurchaseInvoice | purchase_invoice_main | purchase_invoice_details | yes | yes |
| Payment | payment_voucher_main | payment_voucher_details | yes | no |
| Receipt | receipt_voucher_main | receipt_voucher_details | yes | no |
| Contra | contra_voucher_main | contra_voucher_details | yes | no |
| Journal | journal_voucher_main | journal_voucher_details | yes | no |
| CreditNote | credit_note_main | credit_note_details | yes | yes |
| DebitNote | debit_note_main | debit_note_details | yes | yes |
| Quotation | quotation_main | quotation_details | no | no |
| SalesOrder | sales_order_main | sales_order_details | no | no |
| PurchaseOrder | purchase_order_main | purchase_order_details | no | no |
| DeliveryNote | delivery_note_main | delivery_note_details | no | yes |
| ReceiptNote | receipt_note_main | receipt_note_details | no | yes |
| GodownTransfer | godown_tranfer_main | godown_transfer_details | no | yes |
| MaterialIn | material_in_main | material_in_details | no | yes |
| Requirement | requirement_main | requirement_details | no | no |
| StockRequest | stock_request_main | stock_request_details | no | no |

**Lifecycle state machine (as implemented, `voucherLifecycle.service.ts`)** — `VoucherStatus`
column on the "main" table, free string:
- `Draft` → editable (line replace) via `VoucherEditService.edit`; only Draft is editable.
- `Draft`/`Approved` → **Approve**: if the matching `voucherseries.require_approval` is
  false, goes straight to `Posted`; if true, Draft→Approved, Approved→Posted.
- `Draft`/`Approved` → **Reject**: sets `Rejected` + reason (stored in the reused
  `Quotation_Dropped_Reason`/`Quotation_Dropped` columns on the main table — a generic
  "notes" field name shared across all voucher mains).
- `Posted`/`Approved` → **Cancel**: reverses GL (`journal_ledger`, debit/credit swapped) and
  stock (`stock_ledger`, in/out swapped) entries, sets `Cancelled`, records a
  self-referencing `voucherlinkage` row with `link_type='Cancellation'`. Blocked if the
  voucher has downstream linkages (must cancel those first) or the voucher's date falls in
  a Locked/Closed financial year.
- `SalesInvoice` posting directly creates the voucher in status `'Posted'` (no separate
  "create-then-approve" step observed for the direct-post endpoints in
  `transactions.routes.ts`/`phase4.routes.ts` — approval workflow applies to
  edit/cancel/approve/reject lifecycle actions only).

Note: ENUMS.md documents a 5-state set (`Draft/Approved/Posted/Cancelled/Closed`); the
observed code additionally uses `Rejected` (not in that set) and does not appear to use
`Closed` at the voucher level (Closed applies to FinancialYear). Treat the *effective*
runtime set as `Draft, Approved, Posted, Cancelled, Rejected`.

### 5.2 Posting invariants (verified in `voucherPosting.service.ts::postSalesInvoice`)

- Guards before write: FY not locked (`assertFyNotLocked`), customer credit limit check,
  per-line discount-percent vs `ConfigSettingService.getMaxDiscountPercent()`.
- Voucher number from `TransactionHelperService.generateNextNumber` (maps to
  `transactionhelper` table), inside the same `prisma.$transaction`.
- GL: builds a `journalEntries[]` array, asserts `sumDebits.equals(sumCredits)` in code
  before `journal_ledger.createMany` (not relying on a DB CHECK).
- Stock: one `stock_ledger` row per line with `quantity_out` set (sales) — `quantity_in`
  always `Decimal(0)` for a sales invoice line (XOR by construction, not just DB check).
- Bill-wise: creates one `billwise_records` row (`RefType='New Ref'`) with a computed
  `Due_Date` from `credit_days`.
- If `source_voucher_id` supplied, creates a `voucherlinkage` row `link_type='Conversion'`.
- Response returned to the controller: `{ id, voucherNo, total, subtotal, discount, vat }`
  (see `api-contract.md` for the full shape).

### 5.3 Supporting/ancillary entities

| Entity | Table | Purpose |
|---|---|---|
| JournalLedger | `journal_ledger` | Normalized GL log; `debit_amount`/`credit_amount` XOR per row |
| VoucherLineAllocation | `voucher_line_allocations` | Sub-line splits (Expense/Discount/Tax/Charge/Rebate) |
| VoucherLinkage | `voucherlinkage` | Header-to-header lineage (`Conversion`/`Reference`/`Return`/`Amendment`, plus observed `Cancellation`) |
| VoucherLineRelation | `voucher_line_relations` | Line-level conversion lineage / pending qty |
| Shipment | `shipments` | 1:1 logistics metadata per voucher header |
| ItemPhysicalSpec | `itemphysicalspecs` | 1:1 dimension metadata per detail line (polymorphic) |
| TermsAndConditions | `terms_and_conditions` | Reusable T&C templates (Master-CRUD) |
| TransportationDetails | `transportation_details` | Dispatch tracking (Master-CRUD) |
| TransactionHelper | `transactionhelper` | Atomic numbering row per (type, prefix, FY) — not directly exposed as CRUD, only via posting |

### Endpoint table — posting (`/transactions`, `transactions.routes.ts`)

| Method | Path | RBAC | Purpose |
|---|---|---|---|
| POST | `/sales-invoice` | `SalesInvoice:create` | Post Sales Invoice (full GL+stock+billwise orchestration) |
| POST | `/purchase-invoice` | `PurchaseInvoice:create` | Post Purchase Invoice |
| POST | `/payment` | `PaymentVoucher:create` | Post Payment Voucher |
| POST | `/receipt` | `ReceiptVoucher:create` | Post Receipt Voucher |
| POST | `/contra` | `ContraVoucher:create` | Post Contra Voucher |
| POST | `/journal` | `JournalVoucher:create` | Post Journal Voucher |
| POST | `/credit-note` | `CreditNote:create` | Post Credit Note |
| POST | `/debit-note` | `DebitNote:create` | Post Debit Note |

### Endpoint table — order/stock posting + financial reports (`/transactions`, `phase4.routes.ts`)

| Method | Path | RBAC | Purpose |
|---|---|---|---|
| POST | `/quotation` | `Quotation:create` | Post quotation |
| PUT | `/quotation/:id/status` | `Quotation:update` | Update quotation status (drop/convert flag) |
| POST | `/sales-order` | `SalesOrder:create` | Post sales order |
| POST | `/purchase-order` | `PurchaseOrder:create` | Post purchase order |
| POST | `/godown-transfer` | `GodownTransfer:create` | Post godown transfer (stock only) |
| POST | `/delivery-note` | `DeliveryNote:create` | Post delivery note (stock out) |
| POST | `/receipt-note` | `ReceiptNote:create` | Post receipt note (stock in) |
| GET | `/pending-quantities/:id` | `DeliveryNote:read` | Pending qty to deliver/invoice for a source voucher |
| POST | `/material-in` | `MaterialIn:create` | Post material-in |
| POST | `/requirement` | `Requirement:create` | Post requirement |
| POST | `/stock-request` | `StockRequest:create` | Post stock request |
| POST | `/stock-request/:id/fulfill` | `StockRequest:update` | Fulfill stock request |
| GET | `/reports/ledger-statement` | `JournalLedger:read` | Ledger statement |
| GET | `/reports/trial-balance` | `JournalLedger:read` | Trial balance |
| GET | `/reports/profit-loss` | `JournalLedger:read` | P&L |
| GET | `/reports/balance-sheet` | `JournalLedger:read` | Balance sheet |
| GET | `/reports/day-book` | `JournalLedger:read` | Day book |
| GET | `/shipment/:voucherHeaderId` | `Transactions:read` | Shipment info |
| GET | `/physical-specs/:detailLineId` | `Transactions:read` | Physical spec of a line |
| GET | `/line-allocations/:detailLineId` | `Transactions:read` | Allocations of a line |

### Endpoint table — voucher reads (`/transactions`, `voucherRead.routes.ts`)

| Method | Path | RBAC |
|---|---|---|
| GET | `/sales-invoices`, `/sales-invoices/:id` | `SalesInvoice:read` |
| GET | `/purchase-invoices`, `/purchase-invoices/:id` | `PurchaseInvoice:read` |
| GET | `/payments`, `/payments/:id` | `PaymentVoucher:read` |
| GET | `/receipts`, `/receipts/:id` | `ReceiptVoucher:read` |
| GET | `/contra`, `/contra/:id` | `ContraVoucher:read` |
| GET | `/journals`, `/journals/:id` | `JournalVoucher:read` |
| GET | `/credit-notes`, `/credit-notes/:id` | `CreditNote:read` |
| GET | `/debit-notes`, `/debit-notes/:id` | `DebitNote:read` |
| GET | `/quotations`, `/quotations/:id` | `Quotation:read` |
| GET | `/sales-orders`, `/sales-orders/:id` | `SalesOrder:read` |
| GET | `/purchase-orders`, `/purchase-orders/:id` | `PurchaseOrder:read` |
| GET | `/delivery-notes`, `/delivery-notes/:id` | `DeliveryNote:read` |
| GET | `/receipt-notes`, `/receipt-notes/:id` | `ReceiptNote:read` |
| GET | `/godown-transfers`, `/godown-transfers/:id` | `GodownTransfer:read` |
| GET | `/material-in`, `/material-in/:id` | `MaterialIn:read` |
| GET | `/requirements`, `/requirements/:id` | `Requirement:read` |
| GET | `/stock-requests`, `/stock-requests/:id` | `StockRequest:read` |
| GET | `/voucher-header/:id` | `Transactions:read` |
| GET | `/linkages/:voucherHeaderId` | `Transactions:read` |
| GET | `/line-relations/:detailLineId` | `Transactions:read` |

List filters supported (from `ListFilters` in `voucherRead.service.ts`, real code):
`start_date`, `end_date`, `prefix`, `financial_year`, `ledger_id`, `status`, `page`, `limit`
(`limit` capped at 200). **No `updatedSince`/delta filter exists** (see `offline-sync-readiness.md`).

### Endpoint table — lifecycle (`/transactions`, `voucherLifecycle.routes.ts`)

| Method | Path | RBAC | Purpose |
|---|---|---|---|
| PUT | `/:type/:id` | `Transactions:update` | Edit a Draft voucher (header/lines) |
| POST | `/:type/:id/cancel` | `Transactions:update` | Cancel/void with GL+stock reversal |
| POST | `/:type/:id/approve` | `Transactions:update` | Approve (Draft→Approved/Posted per series config) |
| POST | `/:type/:id/reject` | `Transactions:update` | Reject with reason |

### Endpoint table — ancillary (`/transactions`, `ancillary.routes.ts`)

| Method | Path | RBAC |
|---|---|---|
| GET/POST/PUT/DELETE | `/terms-and-conditions`, `/terms-and-conditions/:id` | `TermsAndConditions:{action}` |
| GET/POST/PUT/DELETE | `/transportation-details`, `/transportation-details/:id` | `TransportationDetails:{action}` |

### Endpoint table — reports & dashboard

| Method | Path | RBAC | Purpose |
|---|---|---|---|
| GET | `/transactions/reports/sales-register` | `Transactions:read` | Sales register |
| GET | `/transactions/reports/purchase-register` | `Transactions:read` | Purchase register |
| GET | `/transactions/reports/stock-summary` | `Inventory:read` | Stock summary |
| GET | `/transactions/reports/stock-valuation` | `Inventory:read` | Stock valuation |
| GET | `/transactions/reports/vat-return` | `Transactions:read` | VAT return |
| GET | `/reports/dashboard` | `Transactions:read` | Dashboard summary (date-ranged, company/branch filter) |
| GET | `/reports/alerts` | `Transactions:read` | Cross-domain alerts (e.g. expiring docs/batches) |
| GET | `/reports/search` | `Transactions:read` | Global search (ledgers, items, contacts, vouchers — top 10 each, min 2 chars) |

---

## 6. Notes for the Flutter client

- Every list endpoint is paginated the same way; standardize one `Paginated<T>` model.
- RBAC granularity is **uneven**: Organization splits by fine-grained entity module name
  (e.g. `Branch`, `Currency`, `ProjectMaster`…) while Accounts/Inventory/Employee use one
  coarse module (`Accounts`, `Inventory`, `Employee`) for everything underneath. The
  permission-gating UI must key off the exact strings in the endpoint tables above, not an
  assumed 1:1 entity↔module mapping.
- Not all "masters" soft-delete — `Brand`, `Category`, `AccountGroup` and the 1:1 ledger
  extension tables have no `is_active` column and are hard-deleted; build the UI's delete
  confirmation copy accordingly (irreversible vs reversible).
