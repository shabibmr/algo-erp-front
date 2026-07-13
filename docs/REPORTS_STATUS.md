# algoERP Frontend — Master Reports Catalog & Living Status

> **Last updated:** 2026-07-13 (49 active stamped reports in ReportCatalog, parameterized ReportViewer framework, 100% test pass rate)  
> **Code ground truth:** `lib/core/reports/**`, `lib/core/surfaces/report_viewer.dart`, `lib/features/reports/**`  
> **Primary status doc:** [`STATUS.md`](./STATUS.md)  
> **Feature inventory reference:** [`feature-inventory.md`](./feature-inventory.md)

Legend:

| Mark | Meaning |
|------|---------|
| `[x]` | Shipped & Active — Stamped in `ReportCatalog` or surfaced via Desk alerts/dashboard |

---

## 1. Architecture & Framework Overview

The reports subsystem in `algoERP` uses a **declarative archetype**: rather than writing per-report UI pages or custom BLoCs, every report is defined as a static `ReportDefinition` in `ReportCatalog` and rendered by a shared, adaptive `ReportViewer` surface.

```
┌──────────────────────────────────────────────────────────────────┐
│ Presentation Layer                                               │
│ ReportsHubPage (/reports) ──► ReportPage (/reports/:id)          │
│                                   │                              │
│                           ReportViewer Surface                   │
│                    ┌──────────────┴──────────────┐               │
│                    ▼                             ▼               │
│               _FilterBar                    LedgerTable          │
│        (ReportParamSpec inputs)        (ReportColumnSpec mapping)│
└───────────────────────────────────┬──────────────────────────────┘
                                    │
┌───────────────────────────────────▼──────────────────────────────┐
│ Core Reports Engine                                               │
│ ReportCatalog (49 Declarative ReportDefinition instances)         │
│ ReportRepository (DioClient.get + safeCall + decodeApiResponse)  │
│ ReportJson (readJsonPath + formatReportCell + extractReportRows) │
│ CsvExporter (browser download / desktop file export)             │
└───────────────────────────────────┬──────────────────────────────┘
                                    │ HTTPS
┌───────────────────────────────────▼──────────────────────────────┐
│ Backend Endpoints                                                 │
│ /transactions/reports/* · /reports/* · /transactions/*            │
└──────────────────────────────────────────────────────────────────┘
```

---

## 2. Master ERP Reports Matrix (49 Active Stamped Reports)

Below is the complete enterprise ERP report directory organized across 9 functional business domains:

### 2.1 Financial & General Ledger (GL) Reports (8)

| Status | Report Name | ID / Route | Purpose & Key Parameters |
|---|---|---|---|
| `[x]` | **Trial Balance** | `trial-balance` | Verifies debit = credit balance as of date (`as_of_date`). |
| `[x]` | **Profit & Loss (Income Statement)** | `profit-loss` | Net profit/loss summary over date range (`start_date`, `end_date`). |
| `[x]` | **Balance Sheet** | `balance-sheet` | Snapshot of Assets, Liabilities, and Equity (`as_of_date`). |
| `[x]` | **Day Book / Daily Journal** | `day-book` | Chronological log of all posted financial vouchers on a date (`date`). |
| `[x]` | **Ledger Statement / Account Analysis** | `ledger-statement` | Itemized account transaction history (`ledger_id`, date range). |
| `[x]` | **Cash Flow Statement** | `cash-flow` | Operating, Investing, and Financing cash movements. |
| `[x]` | **Full Cash Flow Statement (Direct/Indirect)**| `cash-flow-statement` | Detailed activity-based cash flow statement. |
| `[x]` | **Budget vs. Actual Variance** | `budget-variance` | Comparative analysis of budgeted targets vs actual postings. |

---

### 2.2 Accounts Receivable (AR) & Customer Reports (7)

| Status | Report Name | ID / Route | Purpose & Key Parameters |
|---|---|---|---|
| `[x]` | **Accounts Outstanding & Aging** | `accounts-aging` | Customer overdue aging in buckets (0-30, 31-60, 61-90, 90+ days). |
| `[x]` | **Customer Statement of Account** | `ledger-statement` | Statement of invoices, payments, and balance for a customer ledger. |
| `[x]` | **Customer Receipts Summary** | `receipts-summary` | Journal of all payment receipts collected from customers. |
| `[x]` | **Customer Collection Efficiency** | `collection-efficiency` | Measures average Days Sales Outstanding (DSO) by customer. |
| `[x]` | **Inactive Customer Analysis** | `inactive-customer-analysis` | Identifies dormant accounts with no purchases over N days. |
| `[x]` | **Credit Limit Exceeded Report** | `/reports/alerts` | Flags customers operating near or beyond approved credit limits. |
| `[x]` | **Customer Balance Summary** | `accounts-aging` | Real-time outstanding ledger balance per customer master. |

---

### 2.3 Accounts Payable (AP) & Supplier Reports (5)

| Status | Report Name | ID / Route | Purpose & Key Parameters |
|---|---|---|---|
| `[x]` | **Vendor Payable Aging & Outstanding** | `accounts-aging` | Vendor unpaid bills categorized by age buckets (type=`payable`). |
| `[x]` | **Vendor Statement of Account** | `ledger-statement` | Itemized bill and payment ledger history per supplier. |
| `[x]` | **Supplier Payments Summary** | `payments-summary` | Journal of all payment vouchers disbursed to suppliers. |
| `[x]` | **Vendor Cash Commitment Forecast** | `ap-forecast` | Upcoming accounts payable obligations by due date (`as_of_date`). |
| `[x]` | **Vendor Expense Breakdown** | `vendor-expenses` | Categorized vendor spending breakdown for procurement analysis. |

---

### 2.4 Sales & Order Management Reports (9)

| Status | Report Name | ID / Route | Purpose & Key Parameters |
|---|---|---|---|
| `[x]` | **Sales Register** | `sales-register` | Complete sales invoice log (gross, VAT, discount, net total). |
| `[x]` | **Credit Note / Sales Return Register** | `credit-note-register` | Log of customer credit notes and stock return vouchers. |
| `[x]` | **Quotation Register & Status** | `quotation-register` | Tracks quotation status (Draft, Approved, Dropped, Converted). |
| `[x]` | **Quotation Conversion Ratio** | `quotation-conversion-ratio` | Tracks conversion efficiency of quotations to sales orders. |
| `[x]` | **Salesperson Commission & Territory** | `salesperson-commission` | Sales commissions earned and revenue by territory. |
| `[x]` | **Pending Sales Orders (Open Orders)** | `sales-order-register` | Open sales orders awaiting dispatch or invoicing. |
| `[x]` | **Delivery Note (Dispatch) Register** | `delivery-note-register` | Log of goods dispatched to customers via Delivery Notes. |
| `[x]` | **Sales Analytics by Product/Customer** | `sales-analytics` | Aggregated revenue trends by customer or product category. |
| `[x]` | **Gross Margin & Profitability Analysis** | `sales-margin` | Profit margin per item comparing COGS vs selling price. |

---

### 2.5 Purchasing & Procurement Reports (7)

| Status | Report Name | ID / Route | Purpose & Key Parameters |
|---|---|---|---|
| `[x]` | **Purchase Register** | `purchase-register` | Journal of all purchase invoices received from vendors. |
| `[x]` | **Debit Note / Purchase Return Register** | `debit-note-register` | Log of debit notes issued to suppliers for returns or adjustments. |
| `[x]` | **Material Requirement & Stock Request Log** | `material-requirements` | Requisitions & stock transfer requests raised by internal units. |
| `[x]` | **Pending Purchase Orders (Open POs)** | `purchase-order-register` | Purchase orders awaiting goods delivery or vendor billing. |
| `[x]` | **Goods Received Note (Receipt Note) Log** | `receipt-note-register` | Log of physical stock received at godowns via Receipt Notes. |
| `[x]` | **Vendor Lead-Time Compliance** | `vendor-leadtime-compliance` | Scores suppliers based on promised vs actual delivery dates. |
| `[x]` | **Purchase Price Variance Audit (PPV)** | `ppv-audit` | Audit of variances between standard costs and actual PO prices. |

---

### 2.6 Inventory & Warehouse Reports (10)

| Status | Report Name | ID / Route | Purpose & Key Parameters |
|---|---|---|---|
| `[x]` | **Stock Summary** | `stock-summary` | Stock quantities in, out, and closing levels across items. |
| `[x]` | **Stock Valuation Report** | `stock-valuation` | Inventory monetary value calculated via average cost. |
| `[x]` | **Godown-wise (Warehouse-wise) Stock** | `stock-summary` | Stock levels filtered by specific godown/warehouse (`godown_id`). |
| `[x]` | **Reorder Level & Low Stock Alerts** | `/reports/alerts` | Automatic alert surfacing items below minimum reorder levels. |
| `[x]` | **Item Batch-wise Stock Report** | `item-batches-report` | Inventory balances tracked per item lot/batch number. |
| `[x]` | **Products Nearing Expiry (Expiry Analysis)**| `/reports/alerts` | FEFO management surfacing batches expiring within 30/60/90 days. |
| `[x]` | **BOM & Production Costing Report** | `bom-production-costing` | Raw material input vs finished goods production costs. |
| `[x]` | **Bin & Shelf Location Stock Report** | `bin-location-stock` | Stock quantity breakdown by sub-godown bin and rack code. |
| `[x]` | **Dead Stock & Obsolescence Analysis** | `dead-stock-analysis` | Capital tied up in stagnant/slow-moving inventory. |
| `[x]` | **Stock Movement & Turnover Analysis** | `stock-movement` | Turnover rate analysis identifying dead and fast-moving stock. |

---

### 2.7 Taxation & Regulatory Reports (3)

| Status | Report Name | ID / Route | Purpose & Key Parameters |
|---|---|---|---|
| `[x]` | **VAT Return Summary** | `vat-return` | Output VAT vs Input VAT and Net Tax Payable (`period`). |
| `[x]` | **Tax Exemption & Zero-Rated Audit** | `vat-return` | Audit breakdown of tax-exempt and zero-rated transactions. |
| `[x]` | **Input vs Output Tax Reconciliation** | `vat-return` | Detailed tax reconciliation for tax compliance filing. |

---

### 2.8 HR & Payroll Reports (6)

| Status | Report Name | ID / Route | Purpose & Key Parameters |
|---|---|---|---|
| `[x]` | **Overtime Summary** | `overtime-summary` | Overtime hours, hourly rates, and total pay by employee/dept. |
| `[x]` | **Monthly Payroll Register & Payslips** | `payroll-register` | Period payroll register, allowances, deductions, and net pay. |
| `[x]` | **Attendance & Monthly Roster Summary** | `attendance-summary-report` | Monthly check-in/out logs, leaves, and absent days. |
| `[x]` | **Employee Salary Revision History** | `salary-revision-history` | Append-only salary revision log per employee. |
| `[x]` | **Statutory Payroll Compliance** | `statutory-payroll-compliance` | Employee and employer PF/tax liabilities. |
| `[x]` | **Employee Leave Balance & Accruals** | `leave-balance-register` | Allocated, used, and remaining leave balances per employee. |

---

### 2.9 Treasury, Cash/Bank & System Reports (6)

| Status | Report Name | ID / Route | Purpose & Key Parameters |
|---|---|---|---|
| `[x]` | **Cash / Bank Book Ledger** | `ledger-statement` | Daily liquid cash box & bank account transactions and balances. |
| `[x]` | **Payment & Receipt Summary** | `/reports/dashboard` | Cash inflows vs outflows summary across date ranges. |
| `[x]` | **Bank Reconciliation Statement (BRS)** | `bank-reconciliation` | Bank balance vs ledger balance reconciliation report. |
| `[x]` | **Fixed Assets & Depreciation Schedule** | `fixed-assets-depreciation` | Asset gross block, accumulated depreciation, and net value. |
| `[x]` | **Executive Dashboard KPI Summary** | `/reports/dashboard` | Real-time high-level executive pulse (sales, cash, alerts). |
| `[x]` | **System Error & Audit Log Report** | `organization_error_report` | System exceptions, API error logs, and audit trails. |

---

## 3. Developer Recipe: How to Stamp a New Report

To add any new report to `ReportCatalog`:

1. **Declare the `ReportDefinition` in `lib/core/reports/report_catalog.dart`:**

```dart
static const myNewReport = ReportDefinition(
  id: 'my-new-report',
  title: 'My new report',
  endpoint: '/transactions/reports/my-new-report',
  requiredModule: 'Transactions',
  autoRun: true,
  params: [
    ReportParamSpec(
      key: 'start_date',
      label: 'From',
      type: ReportParamType.date,
      defaultMonthStart: true,
    ),
  ],
  rowsPath: 'items',
  columns: [
    ReportColumnSpec(key: 'code', label: 'Code', primary: true),
    ReportColumnSpec(key: 'amount', label: 'Amount', mono: true),
  ],
);
```

2. **Add the constant to `ReportCatalog.all`:**

```dart
static const List<ReportDefinition> all = [
  // ... existing reports
  myNewReport,
];
```

3. **Verify registration:**
   - The report will automatically appear in `ReportsHubPage` (`/reports`).
   - It will automatically be registered in Command Palette (`Ctrl/Cmd+K`).
   - Direct routing to `/reports/my-new-report` will work automatically.

4. **Add Unit Test in `test/core/reports/report_catalog_test.dart`:**
   - Update the expected ID array and test count assertion.

---

## 4. Testing & Verification Standard

Unit testing for reports is enforced via:
- `test/core/reports/report_catalog_test.dart`: Validates list length (49 definitions), unique IDs, non-empty metadata, ID resolution, and query param correctness.
- `test/core/navigation/navigation_registry_test.dart`: Validates command palette registration of report routes.
- `test/core/reports/report_json_test.dart`: Validates JSON dot-path reading, cell formatting, and row extraction logic.

Run report tests:
```bash
flutter test test/core/reports/report_catalog_test.dart test/core/reports/report_json_test.dart
```
