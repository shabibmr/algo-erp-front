import 'package:algo_erp_front/core/reports/report_definition.dart';

/// Stamped report definitions (Sprint G2).
abstract final class ReportCatalog {
  static const List<ReportDefinition> all = [
    salesRegister,
    purchaseRegister,
    stockSummary,
    stockValuation,
    vatReturn,
    trialBalance,
    dayBook,
    profitAndLoss,
    balanceSheet,
    ledgerStatement,
    accountsAging,
    overtimeSummary,
    creditNoteRegister,
    debitNoteRegister,
    quotationRegister,
    salesOrderRegister,
    purchaseOrderRegister,
    deliveryNoteRegister,
    receiptNoteRegister,
    godownTransferRegister,
    receiptsSummary,
    paymentsSummary,
    materialRequirements,
    itemBatchesReport,
    payrollRegister,
    attendanceSummaryReport,
    salaryRevisionHistory,
    cashFlowStatement,
    budgetVariance,
    collectionEfficiency,
    apCashForecast,
    vendorExpenses,
    salesAnalytics,
    salesMargin,
    priceVariance,
    stockMovement,
    bankReconciliation,
    cashFlowStatementDetailed,
    fixedAssetsDepreciation,
    quotationConversionRatio,
    salespersonCommission,
    inactiveCustomerAnalysis,
    vendorLeadtimeCompliance,
    ppvAudit,
    bomProductionCosting,
    binLocationStock,
    deadStockAnalysis,
    statutoryPayrollCompliance,
    leaveBalanceRegister,
  ];

  static ReportDefinition? byId(String id) {
    for (final r in all) {
      if (r.id == id) return r;
    }
    return null;
  }

  static const salesRegister = ReportDefinition(
    id: 'sales-register',
    title: 'Sales register',
    endpoint: '/transactions/reports/sales-register',
    requiredModule: 'Transactions',
    autoRun: true,
    params: [
      ReportParamSpec(
        key: 'start_date',
        label: 'From',
        type: ReportParamType.date,
        defaultMonthStart: true,
      ),
      ReportParamSpec(
        key: 'end_date',
        label: 'To',
        type: ReportParamType.date,
        defaultToday: true,
      ),
    ],
    rowsPath: 'items',
    columns: [
      ReportColumnSpec(key: 'voucher_no', label: 'Voucher', primary: true),
      ReportColumnSpec(key: 'voucher_date', label: 'Date', mono: true),
      ReportColumnSpec(key: 'voucher_prefix', label: 'Prefix'),
      ReportColumnSpec(
        key: 'sales_invoice_main.Gross_Total',
        label: 'Gross',
        mono: true,
      ),
      ReportColumnSpec(
        key: 'sales_invoice_main.Vat_Amount',
        label: 'VAT',
        mono: true,
      ),
      ReportColumnSpec(
        key: 'sales_invoice_main.Total',
        label: 'Total',
        mono: true,
      ),
    ],
  );

  static const purchaseRegister = ReportDefinition(
    id: 'purchase-register',
    title: 'Purchase register',
    endpoint: '/transactions/reports/purchase-register',
    requiredModule: 'Transactions',
    autoRun: true,
    params: [
      ReportParamSpec(
        key: 'start_date',
        label: 'From',
        type: ReportParamType.date,
        defaultMonthStart: true,
      ),
      ReportParamSpec(
        key: 'end_date',
        label: 'To',
        type: ReportParamType.date,
        defaultToday: true,
      ),
    ],
    rowsPath: 'items',
    columns: [
      ReportColumnSpec(key: 'voucher_no', label: 'Voucher', primary: true),
      ReportColumnSpec(key: 'voucher_date', label: 'Date', mono: true),
      ReportColumnSpec(key: 'voucher_prefix', label: 'Prefix'),
      ReportColumnSpec(
        key: 'purchase_invoice_main.Total',
        label: 'Total',
        mono: true,
      ),
      ReportColumnSpec(
        key: 'purchase_invoice_main.Vat_Amount',
        label: 'VAT',
        mono: true,
      ),
    ],
  );

  static const stockSummary = ReportDefinition(
    id: 'stock-summary',
    title: 'Stock summary',
    endpoint: '/transactions/reports/stock-summary',
    requiredModule: 'Inventory',
    autoRun: true,
    columns: [
      ReportColumnSpec(key: 'item_name', label: 'Item', primary: true, flex: 2),
      ReportColumnSpec(key: 'item_id', label: 'Item ID', mono: true),
      ReportColumnSpec(key: 'godown_id', label: 'Godown', mono: true),
      ReportColumnSpec(key: 'quantity_in', label: 'In', mono: true),
      ReportColumnSpec(key: 'quantity_out', label: 'Out', mono: true),
      ReportColumnSpec(key: 'closing_qty', label: 'Closing', mono: true),
    ],
  );

  static const stockValuation = ReportDefinition(
    id: 'stock-valuation',
    title: 'Stock valuation',
    endpoint: '/transactions/reports/stock-valuation',
    requiredModule: 'Inventory',
    autoRun: true,
    columns: [
      ReportColumnSpec(key: 'item_name', label: 'Item', primary: true, flex: 2),
      ReportColumnSpec(key: 'godown_id', label: 'Godown', mono: true),
      ReportColumnSpec(key: 'closing_qty', label: 'Qty', mono: true),
      ReportColumnSpec(key: 'avg_cost', label: 'Avg cost', mono: true),
      ReportColumnSpec(key: 'total_value', label: 'Value', mono: true),
    ],
  );

  static const vatReturn = ReportDefinition(
    id: 'vat-return',
    title: 'VAT return',
    endpoint: '/transactions/reports/vat-return',
    requiredModule: 'Transactions',
    shape: ReportShape.summary,
    params: [
      ReportParamSpec(
        key: 'period',
        label: 'Period (YYYY-MM or YYYY-Qn)',
        type: ReportParamType.text,
        required: true,
      ),
    ],
    columns: [
      ReportColumnSpec(key: 'period', label: 'Period'),
      ReportColumnSpec(
        key: 'sales_invoices',
        label: 'Sales invoices',
        mono: true,
      ),
      ReportColumnSpec(
        key: 'purchase_invoices',
        label: 'Purchase invoices',
        mono: true,
      ),
      ReportColumnSpec(
        key: 'total_sales_value',
        label: 'Sales value',
        mono: true,
      ),
      ReportColumnSpec(
        key: 'total_purchase_value',
        label: 'Purchase value',
        mono: true,
      ),
      ReportColumnSpec(key: 'output_tax', label: 'Output tax', mono: true),
      ReportColumnSpec(key: 'input_tax', label: 'Input tax', mono: true),
      ReportColumnSpec(
        key: 'net_vat_payable',
        label: 'Net VAT payable',
        mono: true,
      ),
    ],
  );

  static const trialBalance = ReportDefinition(
    id: 'trial-balance',
    title: 'Trial balance',
    endpoint: '/transactions/reports/trial-balance',
    requiredModule: 'JournalLedger',
    autoRun: true,
    params: [
      ReportParamSpec(
        key: 'as_of_date',
        label: 'As of',
        type: ReportParamType.date,
        defaultToday: true,
      ),
    ],
    rowsPath: 'entries',
    columns: [
      ReportColumnSpec(
        key: 'ledgerName',
        label: 'Ledger',
        primary: true,
        flex: 2,
      ),
      ReportColumnSpec(key: 'nature', label: 'Nature'),
      ReportColumnSpec(key: 'ledgerType', label: 'Type'),
      ReportColumnSpec(key: 'debit', label: 'Debit', mono: true),
      ReportColumnSpec(key: 'credit', label: 'Credit', mono: true),
    ],
  );

  static const dayBook = ReportDefinition(
    id: 'day-book',
    title: 'Day book',
    endpoint: '/transactions/reports/day-book',
    requiredModule: 'JournalLedger',
    params: [
      ReportParamSpec(
        key: 'date',
        label: 'Date',
        type: ReportParamType.date,
        required: true,
        defaultToday: true,
      ),
    ],
    autoRun: true,
    columns: [
      ReportColumnSpec(key: 'voucherNo', label: 'Voucher', primary: true),
      ReportColumnSpec(key: 'voucherType', label: 'Type'),
      ReportColumnSpec(key: 'ledgerName', label: 'Ledger', flex: 2),
      ReportColumnSpec(key: 'debit', label: 'Debit', mono: true),
      ReportColumnSpec(key: 'credit', label: 'Credit', mono: true),
      ReportColumnSpec(key: 'narration', label: 'Narration', flex: 2),
    ],
  );

  static const profitAndLoss = ReportDefinition(
    id: 'profit-loss',
    title: 'Profit & loss',
    endpoint: '/reports/profit-loss',
    requiredModule: 'JournalLedger',
    autoRun: true,
    params: [
      ReportParamSpec(
        key: 'start_date',
        label: 'From',
        type: ReportParamType.date,
        defaultMonthStart: true,
      ),
      ReportParamSpec(
        key: 'end_date',
        label: 'To',
        type: ReportParamType.date,
        defaultToday: true,
      ),
    ],
    rowsPath: 'entries',
    columns: [
      ReportColumnSpec(
        key: 'accountGroup',
        label: 'Group',
        primary: true,
        flex: 2,
      ),
      ReportColumnSpec(key: 'ledgerName', label: 'Ledger', flex: 2),
      ReportColumnSpec(key: 'income', label: 'Income', mono: true),
      ReportColumnSpec(key: 'expense', label: 'Expense', mono: true),
      ReportColumnSpec(key: 'netAmount', label: 'Net Amount', mono: true),
    ],
  );

  static const balanceSheet = ReportDefinition(
    id: 'balance-sheet',
    title: 'Balance sheet',
    endpoint: '/reports/balance-sheet',
    requiredModule: 'JournalLedger',
    autoRun: true,
    params: [
      ReportParamSpec(
        key: 'as_of_date',
        label: 'As of',
        type: ReportParamType.date,
        defaultToday: true,
      ),
    ],
    rowsPath: 'entries',
    columns: [
      ReportColumnSpec(
        key: 'category',
        label: 'Category',
        primary: true,
        flex: 2,
      ),
      ReportColumnSpec(key: 'ledgerName', label: 'Ledger', flex: 2),
      ReportColumnSpec(key: 'asset', label: 'Asset', mono: true),
      ReportColumnSpec(key: 'liability', label: 'Liability', mono: true),
      ReportColumnSpec(key: 'balance', label: 'Balance', mono: true),
    ],
  );

  static const ledgerStatement = ReportDefinition(
    id: 'ledger-statement',
    title: 'Ledger statement',
    endpoint: '/reports/ledger-statement',
    requiredModule: 'JournalLedger',
    params: [
      ReportParamSpec(
        key: 'ledger_id',
        label: 'Ledger ID',
        type: ReportParamType.text,
        required: true,
      ),
      ReportParamSpec(
        key: 'start_date',
        label: 'From',
        type: ReportParamType.date,
        defaultMonthStart: true,
      ),
      ReportParamSpec(
        key: 'end_date',
        label: 'To',
        type: ReportParamType.date,
        defaultToday: true,
      ),
    ],
    rowsPath: 'items',
    columns: [
      ReportColumnSpec(
        key: 'voucher_date',
        label: 'Date',
        primary: true,
        mono: true,
      ),
      ReportColumnSpec(key: 'voucher_no', label: 'Voucher'),
      ReportColumnSpec(key: 'voucher_type', label: 'Type'),
      ReportColumnSpec(key: 'particulars', label: 'Particulars', flex: 2),
      ReportColumnSpec(key: 'debit', label: 'Debit', mono: true),
      ReportColumnSpec(key: 'credit', label: 'Credit', mono: true),
      ReportColumnSpec(key: 'running_balance', label: 'Balance', mono: true),
    ],
  );

  static const accountsAging = ReportDefinition(
    id: 'accounts-aging',
    title: 'Accounts aging',
    endpoint: '/transactions/reports/aging',
    requiredModule: 'Transactions',
    autoRun: true,
    params: [
      ReportParamSpec(
        key: 'as_of_date',
        label: 'As of',
        type: ReportParamType.date,
        defaultToday: true,
      ),
      ReportParamSpec(
        key: 'type',
        label: 'Type (receivable/payable)',
        type: ReportParamType.text,
      ),
    ],
    rowsPath: 'items',
    columns: [
      ReportColumnSpec(
        key: 'party_name',
        label: 'Party name',
        primary: true,
        flex: 2,
      ),
      ReportColumnSpec(
        key: 'total_outstanding',
        label: 'Total outstanding',
        mono: true,
      ),
      ReportColumnSpec(key: 'current', label: 'Current', mono: true),
      ReportColumnSpec(key: 'days_31_60', label: '31-60 Days', mono: true),
      ReportColumnSpec(key: 'days_61_90', label: '61-90 Days', mono: true),
      ReportColumnSpec(key: 'over_90', label: '> 90 Days', mono: true),
    ],
  );

  static const overtimeSummary = ReportDefinition(
    id: 'overtime-summary',
    title: 'Overtime summary',
    endpoint: '/reports/overtime',
    requiredModule: 'Employee',
    autoRun: true,
    params: [
      ReportParamSpec(
        key: 'start_date',
        label: 'From',
        type: ReportParamType.date,
        defaultMonthStart: true,
      ),
      ReportParamSpec(
        key: 'end_date',
        label: 'To',
        type: ReportParamType.date,
        defaultToday: true,
      ),
    ],
    rowsPath: 'items',
    columns: [
      ReportColumnSpec(
        key: 'employee_name',
        label: 'Employee name',
        primary: true,
        flex: 2,
      ),
      ReportColumnSpec(key: 'employee_code', label: 'Code', mono: true),
      ReportColumnSpec(key: 'department_name', label: 'Department'),
      ReportColumnSpec(
        key: 'overtime_hours',
        label: 'Overtime hrs',
        mono: true,
      ),
      ReportColumnSpec(key: 'overtime_rate', label: 'Hourly rate', mono: true),
      ReportColumnSpec(
        key: 'total_overtime_pay',
        label: 'Total pay',
        mono: true,
      ),
    ],
  );

  static const creditNoteRegister = ReportDefinition(
    id: 'credit-note-register',
    title: 'Credit note register',
    endpoint: '/transactions/credit-notes',
    requiredModule: 'Transactions',
    autoRun: true,
    params: [
      ReportParamSpec(
        key: 'start_date',
        label: 'From',
        type: ReportParamType.date,
        defaultMonthStart: true,
      ),
      ReportParamSpec(
        key: 'end_date',
        label: 'To',
        type: ReportParamType.date,
        defaultToday: true,
      ),
    ],
    rowsPath: 'items',
    columns: [
      ReportColumnSpec(key: 'voucher_no', label: 'Voucher', primary: true),
      ReportColumnSpec(key: 'voucher_date', label: 'Date', mono: true),
      ReportColumnSpec(key: 'voucher_prefix', label: 'Prefix'),
      ReportColumnSpec(
        key: 'credit_note_main.Total',
        label: 'Total',
        mono: true,
      ),
      ReportColumnSpec(
        key: 'credit_note_main.Vat_Amount',
        label: 'VAT',
        mono: true,
      ),
    ],
  );

  static const debitNoteRegister = ReportDefinition(
    id: 'debit-note-register',
    title: 'Debit note register',
    endpoint: '/transactions/debit-notes',
    requiredModule: 'Transactions',
    autoRun: true,
    params: [
      ReportParamSpec(
        key: 'start_date',
        label: 'From',
        type: ReportParamType.date,
        defaultMonthStart: true,
      ),
      ReportParamSpec(
        key: 'end_date',
        label: 'To',
        type: ReportParamType.date,
        defaultToday: true,
      ),
    ],
    rowsPath: 'items',
    columns: [
      ReportColumnSpec(key: 'voucher_no', label: 'Voucher', primary: true),
      ReportColumnSpec(key: 'voucher_date', label: 'Date', mono: true),
      ReportColumnSpec(key: 'voucher_prefix', label: 'Prefix'),
      ReportColumnSpec(
        key: 'debit_note_main.Total',
        label: 'Total',
        mono: true,
      ),
      ReportColumnSpec(
        key: 'debit_note_main.Vat_Amount',
        label: 'VAT',
        mono: true,
      ),
    ],
  );

  static const quotationRegister = ReportDefinition(
    id: 'quotation-register',
    title: 'Quotation register',
    endpoint: '/transactions/quotations',
    requiredModule: 'Transactions',
    autoRun: true,
    params: [
      ReportParamSpec(
        key: 'start_date',
        label: 'From',
        type: ReportParamType.date,
        defaultMonthStart: true,
      ),
      ReportParamSpec(
        key: 'end_date',
        label: 'To',
        type: ReportParamType.date,
        defaultToday: true,
      ),
    ],
    rowsPath: 'items',
    columns: [
      ReportColumnSpec(key: 'voucher_no', label: 'Voucher', primary: true),
      ReportColumnSpec(key: 'voucher_date', label: 'Date', mono: true),
      ReportColumnSpec(key: 'voucher_prefix', label: 'Prefix'),
      ReportColumnSpec(key: 'quotation_main.VoucherStatus', label: 'Status'),
      ReportColumnSpec(key: 'quotation_main.Total', label: 'Total', mono: true),
    ],
  );

  static const salesOrderRegister = ReportDefinition(
    id: 'sales-order-register',
    title: 'Sales order register',
    endpoint: '/transactions/sales-orders',
    requiredModule: 'Transactions',
    autoRun: true,
    params: [
      ReportParamSpec(
        key: 'start_date',
        label: 'From',
        type: ReportParamType.date,
        defaultMonthStart: true,
      ),
      ReportParamSpec(
        key: 'end_date',
        label: 'To',
        type: ReportParamType.date,
        defaultToday: true,
      ),
    ],
    rowsPath: 'items',
    columns: [
      ReportColumnSpec(key: 'voucher_no', label: 'Voucher', primary: true),
      ReportColumnSpec(key: 'voucher_date', label: 'Date', mono: true),
      ReportColumnSpec(key: 'voucher_prefix', label: 'Prefix'),
      ReportColumnSpec(key: 'sales_order_main.VoucherStatus', label: 'Status'),
      ReportColumnSpec(
        key: 'sales_order_main.Total',
        label: 'Total',
        mono: true,
      ),
    ],
  );

  static const purchaseOrderRegister = ReportDefinition(
    id: 'purchase-order-register',
    title: 'Purchase order register',
    endpoint: '/transactions/purchase-orders',
    requiredModule: 'Transactions',
    autoRun: true,
    params: [
      ReportParamSpec(
        key: 'start_date',
        label: 'From',
        type: ReportParamType.date,
        defaultMonthStart: true,
      ),
      ReportParamSpec(
        key: 'end_date',
        label: 'To',
        type: ReportParamType.date,
        defaultToday: true,
      ),
    ],
    rowsPath: 'items',
    columns: [
      ReportColumnSpec(key: 'voucher_no', label: 'Voucher', primary: true),
      ReportColumnSpec(key: 'voucher_date', label: 'Date', mono: true),
      ReportColumnSpec(key: 'voucher_prefix', label: 'Prefix'),
      ReportColumnSpec(
        key: 'purchase_order_main.VoucherStatus',
        label: 'Status',
      ),
      ReportColumnSpec(
        key: 'purchase_order_main.Total',
        label: 'Total',
        mono: true,
      ),
    ],
  );

  static const deliveryNoteRegister = ReportDefinition(
    id: 'delivery-note-register',
    title: 'Delivery note register',
    endpoint: '/transactions/delivery-notes',
    requiredModule: 'Transactions',
    autoRun: true,
    params: [
      ReportParamSpec(
        key: 'start_date',
        label: 'From',
        type: ReportParamType.date,
        defaultMonthStart: true,
      ),
      ReportParamSpec(
        key: 'end_date',
        label: 'To',
        type: ReportParamType.date,
        defaultToday: true,
      ),
    ],
    rowsPath: 'items',
    columns: [
      ReportColumnSpec(key: 'voucher_no', label: 'Voucher', primary: true),
      ReportColumnSpec(key: 'voucher_date', label: 'Date', mono: true),
      ReportColumnSpec(key: 'voucher_prefix', label: 'Prefix'),
      ReportColumnSpec(
        key: 'delivery_note_main.VoucherStatus',
        label: 'Status',
      ),
    ],
  );

  static const receiptNoteRegister = ReportDefinition(
    id: 'receipt-note-register',
    title: 'Receipt note register',
    endpoint: '/transactions/receipt-notes',
    requiredModule: 'Transactions',
    autoRun: true,
    params: [
      ReportParamSpec(
        key: 'start_date',
        label: 'From',
        type: ReportParamType.date,
        defaultMonthStart: true,
      ),
      ReportParamSpec(
        key: 'end_date',
        label: 'To',
        type: ReportParamType.date,
        defaultToday: true,
      ),
    ],
    rowsPath: 'items',
    columns: [
      ReportColumnSpec(key: 'voucher_no', label: 'Voucher', primary: true),
      ReportColumnSpec(key: 'voucher_date', label: 'Date', mono: true),
      ReportColumnSpec(key: 'voucher_prefix', label: 'Prefix'),
      ReportColumnSpec(key: 'receipt_note_main.VoucherStatus', label: 'Status'),
    ],
  );

  static const godownTransferRegister = ReportDefinition(
    id: 'godown-transfer-register',
    title: 'Godown transfer register',
    endpoint: '/transactions/godown-transfers',
    requiredModule: 'Inventory',
    autoRun: true,
    params: [
      ReportParamSpec(
        key: 'start_date',
        label: 'From',
        type: ReportParamType.date,
        defaultMonthStart: true,
      ),
      ReportParamSpec(
        key: 'end_date',
        label: 'To',
        type: ReportParamType.date,
        defaultToday: true,
      ),
    ],
    rowsPath: 'items',
    columns: [
      ReportColumnSpec(key: 'voucher_no', label: 'Voucher', primary: true),
      ReportColumnSpec(key: 'voucher_date', label: 'Date', mono: true),
      ReportColumnSpec(key: 'voucher_prefix', label: 'Prefix'),
      ReportColumnSpec(
        key: 'godown_tranfer_main.VoucherStatus',
        label: 'Status',
      ),
    ],
  );

  static const receiptsSummary = ReportDefinition(
    id: 'receipts-summary',
    title: 'Customer receipts summary',
    endpoint: '/transactions/receipts',
    requiredModule: 'Transactions',
    autoRun: true,
    params: [
      ReportParamSpec(
        key: 'start_date',
        label: 'From',
        type: ReportParamType.date,
        defaultMonthStart: true,
      ),
      ReportParamSpec(
        key: 'end_date',
        label: 'To',
        type: ReportParamType.date,
        defaultToday: true,
      ),
    ],
    rowsPath: 'items',
    columns: [
      ReportColumnSpec(key: 'voucher_no', label: 'Voucher', primary: true),
      ReportColumnSpec(key: 'voucher_date', label: 'Date', mono: true),
      ReportColumnSpec(
        key: 'receipt_voucher_main.Total',
        label: 'Total',
        mono: true,
      ),
    ],
  );

  static const paymentsSummary = ReportDefinition(
    id: 'payments-summary',
    title: 'Supplier payments summary',
    endpoint: '/transactions/payments',
    requiredModule: 'Transactions',
    autoRun: true,
    params: [
      ReportParamSpec(
        key: 'start_date',
        label: 'From',
        type: ReportParamType.date,
        defaultMonthStart: true,
      ),
      ReportParamSpec(
        key: 'end_date',
        label: 'To',
        type: ReportParamType.date,
        defaultToday: true,
      ),
    ],
    rowsPath: 'items',
    columns: [
      ReportColumnSpec(key: 'voucher_no', label: 'Voucher', primary: true),
      ReportColumnSpec(key: 'voucher_date', label: 'Date', mono: true),
      ReportColumnSpec(
        key: 'payment_voucher_main.Total',
        label: 'Total',
        mono: true,
      ),
    ],
  );

  static const materialRequirements = ReportDefinition(
    id: 'material-requirements',
    title: 'Material requirements log',
    endpoint: '/transactions/requirements',
    requiredModule: 'Inventory',
    autoRun: true,
    params: [
      ReportParamSpec(
        key: 'start_date',
        label: 'From',
        type: ReportParamType.date,
        defaultMonthStart: true,
      ),
      ReportParamSpec(
        key: 'end_date',
        label: 'To',
        type: ReportParamType.date,
        defaultToday: true,
      ),
    ],
    rowsPath: 'items',
    columns: [
      ReportColumnSpec(key: 'voucher_no', label: 'Voucher', primary: true),
      ReportColumnSpec(key: 'voucher_date', label: 'Date', mono: true),
      ReportColumnSpec(key: 'requirement_main.VoucherStatus', label: 'Status'),
    ],
  );

  static const itemBatchesReport = ReportDefinition(
    id: 'item-batches-report',
    title: 'Item batches report',
    endpoint: '/inventory/item-batches',
    requiredModule: 'Inventory',
    autoRun: true,
    rowsPath: 'items',
    columns: [
      ReportColumnSpec(key: 'batch_no', label: 'Batch No', primary: true),
      ReportColumnSpec(key: 'item_id', label: 'Item ID', mono: true),
      ReportColumnSpec(key: 'mfg_date', label: 'Mfg Date', mono: true),
      ReportColumnSpec(key: 'exp_date', label: 'Expiry Date', mono: true),
      ReportColumnSpec(key: 'quantity', label: 'Quantity', mono: true),
    ],
  );

  static const payrollRegister = ReportDefinition(
    id: 'payroll-register',
    title: 'Payroll register',
    endpoint: '/payslips',
    requiredModule: 'Employee',
    autoRun: true,
    params: [
      ReportParamSpec(
        key: 'start_date',
        label: 'From',
        type: ReportParamType.date,
        defaultMonthStart: true,
      ),
      ReportParamSpec(
        key: 'end_date',
        label: 'To',
        type: ReportParamType.date,
        defaultToday: true,
      ),
    ],
    rowsPath: 'items',
    columns: [
      ReportColumnSpec(
        key: 'employee_id',
        label: 'Employee ID',
        primary: true,
        mono: true,
      ),
      ReportColumnSpec(key: 'period', label: 'Period'),
      ReportColumnSpec(key: 'gross_salary', label: 'Gross Salary', mono: true),
      ReportColumnSpec(key: 'deductions', label: 'Deductions', mono: true),
      ReportColumnSpec(key: 'net_salary', label: 'Net Salary', mono: true),
    ],
  );

  static const attendanceSummaryReport = ReportDefinition(
    id: 'attendance-summary-report',
    title: 'Attendance summary',
    endpoint: '/employees/attendance-summary',
    requiredModule: 'Employee',
    autoRun: true,
    params: [
      ReportParamSpec(
        key: 'start_date',
        label: 'From',
        type: ReportParamType.date,
        defaultMonthStart: true,
      ),
      ReportParamSpec(
        key: 'end_date',
        label: 'To',
        type: ReportParamType.date,
        defaultToday: true,
      ),
    ],
    rowsPath: 'items',
    columns: [
      ReportColumnSpec(
        key: 'employee_name',
        label: 'Employee',
        primary: true,
        flex: 2,
      ),
      ReportColumnSpec(key: 'present_days', label: 'Present Days', mono: true),
      ReportColumnSpec(key: 'absent_days', label: 'Absent Days', mono: true),
      ReportColumnSpec(key: 'leave_days', label: 'Leave Days', mono: true),
      ReportColumnSpec(
        key: 'overtime_hours',
        label: 'Overtime Hrs',
        mono: true,
      ),
    ],
  );

  static const salaryRevisionHistory = ReportDefinition(
    id: 'salary-revision-history',
    title: 'Salary revision history',
    endpoint: '/employees/salary-revisions',
    requiredModule: 'Employee',
    autoRun: true,
    rowsPath: 'items',
    columns: [
      ReportColumnSpec(
        key: 'employee_id',
        label: 'Employee ID',
        primary: true,
        mono: true,
      ),
      ReportColumnSpec(
        key: 'effective_date',
        label: 'Effective Date',
        mono: true,
      ),
      ReportColumnSpec(
        key: 'previous_salary',
        label: 'Previous Salary',
        mono: true,
      ),
      ReportColumnSpec(key: 'new_salary', label: 'New Salary', mono: true),
      ReportColumnSpec(key: 'reason', label: 'Reason', flex: 2),
    ],
  );

  static const cashFlowStatement = ReportDefinition(
    id: 'cash-flow',
    title: 'Cash flow statement',
    endpoint: '/reports/cash-flow',
    requiredModule: 'JournalLedger',
    autoRun: true,
    params: [
      ReportParamSpec(
        key: 'start_date',
        label: 'From',
        type: ReportParamType.date,
        defaultMonthStart: true,
      ),
      ReportParamSpec(
        key: 'end_date',
        label: 'To',
        type: ReportParamType.date,
        defaultToday: true,
      ),
    ],
    rowsPath: 'entries',
    columns: [
      ReportColumnSpec(
        key: 'category',
        label: 'Activity Category',
        primary: true,
        flex: 2,
      ),
      ReportColumnSpec(key: 'inflow', label: 'Cash Inflow', mono: true),
      ReportColumnSpec(key: 'outflow', label: 'Cash Outflow', mono: true),
      ReportColumnSpec(key: 'net_change', label: 'Net Change', mono: true),
    ],
  );

  static const budgetVariance = ReportDefinition(
    id: 'budget-variance',
    title: 'Budget vs actual variance',
    endpoint: '/reports/budget-variance',
    requiredModule: 'JournalLedger',
    autoRun: true,
    params: [
      ReportParamSpec(
        key: 'start_date',
        label: 'From',
        type: ReportParamType.date,
        defaultMonthStart: true,
      ),
      ReportParamSpec(
        key: 'end_date',
        label: 'To',
        type: ReportParamType.date,
        defaultToday: true,
      ),
    ],
    rowsPath: 'entries',
    columns: [
      ReportColumnSpec(
        key: 'account_group',
        label: 'Account Group',
        primary: true,
        flex: 2,
      ),
      ReportColumnSpec(key: 'budget_amount', label: 'Budget', mono: true),
      ReportColumnSpec(key: 'actual_amount', label: 'Actual', mono: true),
      ReportColumnSpec(key: 'variance', label: 'Variance', mono: true),
    ],
  );

  static const collectionEfficiency = ReportDefinition(
    id: 'collection-efficiency',
    title: 'Collection efficiency',
    endpoint: '/reports/collection-efficiency',
    requiredModule: 'Transactions',
    autoRun: true,
    params: [
      ReportParamSpec(
        key: 'start_date',
        label: 'From',
        type: ReportParamType.date,
        defaultMonthStart: true,
      ),
      ReportParamSpec(
        key: 'end_date',
        label: 'To',
        type: ReportParamType.date,
        defaultToday: true,
      ),
    ],
    rowsPath: 'items',
    columns: [
      ReportColumnSpec(
        key: 'customer_name',
        label: 'Customer',
        primary: true,
        flex: 2,
      ),
      ReportColumnSpec(key: 'dso_days', label: 'DSO (Days)', mono: true),
      ReportColumnSpec(key: 'total_billed', label: 'Total Billed', mono: true),
      ReportColumnSpec(
        key: 'total_collected',
        label: 'Total Collected',
        mono: true,
      ),
    ],
  );

  static const apCashForecast = ReportDefinition(
    id: 'ap-forecast',
    title: 'AP cash forecast',
    endpoint: '/reports/ap-forecast',
    requiredModule: 'Transactions',
    autoRun: true,
    params: [
      ReportParamSpec(
        key: 'as_of_date',
        label: 'As of',
        type: ReportParamType.date,
        defaultToday: true,
      ),
    ],
    rowsPath: 'items',
    columns: [
      ReportColumnSpec(
        key: 'vendor_name',
        label: 'Vendor',
        primary: true,
        flex: 2,
      ),
      ReportColumnSpec(
        key: 'due_this_week',
        label: 'Due This Week',
        mono: true,
      ),
      ReportColumnSpec(
        key: 'due_this_month',
        label: 'Due This Month',
        mono: true,
      ),
      ReportColumnSpec(key: 'total_due', label: 'Total Due', mono: true),
    ],
  );

  static const vendorExpenses = ReportDefinition(
    id: 'vendor-expenses',
    title: 'Vendor expense breakdown',
    endpoint: '/reports/vendor-expenses',
    requiredModule: 'Transactions',
    autoRun: true,
    params: [
      ReportParamSpec(
        key: 'start_date',
        label: 'From',
        type: ReportParamType.date,
        defaultMonthStart: true,
      ),
      ReportParamSpec(
        key: 'end_date',
        label: 'To',
        type: ReportParamType.date,
        defaultToday: true,
      ),
    ],
    rowsPath: 'items',
    columns: [
      ReportColumnSpec(
        key: 'category_name',
        label: 'Expense Category',
        primary: true,
        flex: 2,
      ),
      ReportColumnSpec(key: 'vendor_name', label: 'Vendor', flex: 2),
      ReportColumnSpec(key: 'total_amount', label: 'Total Amount', mono: true),
    ],
  );

  static const salesAnalytics = ReportDefinition(
    id: 'sales-analytics',
    title: 'Sales analytics',
    endpoint: '/reports/sales-analytics',
    requiredModule: 'Transactions',
    autoRun: true,
    params: [
      ReportParamSpec(
        key: 'start_date',
        label: 'From',
        type: ReportParamType.date,
        defaultMonthStart: true,
      ),
      ReportParamSpec(
        key: 'end_date',
        label: 'To',
        type: ReportParamType.date,
        defaultToday: true,
      ),
    ],
    rowsPath: 'items',
    columns: [
      ReportColumnSpec(
        key: 'category',
        label: 'Category / Segment',
        primary: true,
        flex: 2,
      ),
      ReportColumnSpec(key: 'unit_sales', label: 'Units Sold', mono: true),
      ReportColumnSpec(
        key: 'total_revenue',
        label: 'Total Revenue',
        mono: true,
      ),
    ],
  );

  static const salesMargin = ReportDefinition(
    id: 'sales-margin',
    title: 'Sales margin report',
    endpoint: '/reports/sales-margin',
    requiredModule: 'Transactions',
    autoRun: true,
    params: [
      ReportParamSpec(
        key: 'start_date',
        label: 'From',
        type: ReportParamType.date,
        defaultMonthStart: true,
      ),
      ReportParamSpec(
        key: 'end_date',
        label: 'To',
        type: ReportParamType.date,
        defaultToday: true,
      ),
    ],
    rowsPath: 'items',
    columns: [
      ReportColumnSpec(
        key: 'item_name',
        label: 'Item Name',
        primary: true,
        flex: 2,
      ),
      ReportColumnSpec(key: 'revenue', label: 'Revenue', mono: true),
      ReportColumnSpec(key: 'cogs', label: 'COGS', mono: true),
      ReportColumnSpec(key: 'gross_margin', label: 'Margin %', mono: true),
    ],
  );

  static const priceVariance = ReportDefinition(
    id: 'price-variance',
    title: 'Vendor price variance',
    endpoint: '/reports/price-variance',
    requiredModule: 'Transactions',
    autoRun: true,
    params: [
      ReportParamSpec(
        key: 'start_date',
        label: 'From',
        type: ReportParamType.date,
        defaultMonthStart: true,
      ),
      ReportParamSpec(
        key: 'end_date',
        label: 'To',
        type: ReportParamType.date,
        defaultToday: true,
      ),
    ],
    rowsPath: 'items',
    columns: [
      ReportColumnSpec(
        key: 'item_name',
        label: 'Item Name',
        primary: true,
        flex: 2,
      ),
      ReportColumnSpec(key: 'vendor_name', label: 'Vendor', flex: 2),
      ReportColumnSpec(
        key: 'standard_price',
        label: 'Standard Price',
        mono: true,
      ),
      ReportColumnSpec(key: 'actual_price', label: 'Actual Price', mono: true),
      ReportColumnSpec(
        key: 'variance_percent',
        label: 'Variance %',
        mono: true,
      ),
    ],
  );

  static const stockMovement = ReportDefinition(
    id: 'stock-movement',
    title: 'Stock movement analysis',
    endpoint: '/reports/stock-movement',
    requiredModule: 'Inventory',
    autoRun: true,
    params: [
      ReportParamSpec(
        key: 'start_date',
        label: 'From',
        type: ReportParamType.date,
        defaultMonthStart: true,
      ),
      ReportParamSpec(
        key: 'end_date',
        label: 'To',
        type: ReportParamType.date,
        defaultToday: true,
      ),
    ],
    rowsPath: 'items',
    columns: [
      ReportColumnSpec(
        key: 'item_name',
        label: 'Item Name',
        primary: true,
        flex: 2,
      ),
      ReportColumnSpec(
        key: 'turnover_ratio',
        label: 'Turnover Ratio',
        mono: true,
      ),
      ReportColumnSpec(key: 'movement_category', label: 'Category'),
      ReportColumnSpec(
        key: 'days_in_stock',
        label: 'Days in Stock',
        mono: true,
      ),
    ],
  );

  static const bankReconciliation = ReportDefinition(
    id: 'bank-reconciliation',
    title: 'Bank reconciliation statement',
    endpoint: '/reports/bank-reconciliation',
    requiredModule: 'JournalLedger',
    autoRun: true,
    params: [
      ReportParamSpec(
        key: 'as_of_date',
        label: 'As of',
        type: ReportParamType.date,
        defaultToday: true,
      ),
    ],
    rowsPath: 'entries',
    columns: [
      ReportColumnSpec(
        key: 'bank_name',
        label: 'Bank Ledger',
        primary: true,
        flex: 2,
      ),
      ReportColumnSpec(key: 'book_balance', label: 'Book Balance', mono: true),
      ReportColumnSpec(
        key: 'uncleared_deposits',
        label: 'Uncleared Deposits',
        mono: true,
      ),
      ReportColumnSpec(
        key: 'uncleared_cheques',
        label: 'Uncleared Cheques',
        mono: true,
      ),
      ReportColumnSpec(
        key: 'statement_balance',
        label: 'Statement Balance',
        mono: true,
      ),
    ],
  );

  static const cashFlowStatementDetailed = ReportDefinition(
    id: 'cash-flow-statement',
    title: 'Cash flow statement (Direct/Indirect)',
    endpoint: '/reports/cash-flow-statement',
    requiredModule: 'JournalLedger',
    autoRun: true,
    params: [
      ReportParamSpec(
        key: 'start_date',
        label: 'From',
        type: ReportParamType.date,
        defaultMonthStart: true,
      ),
      ReportParamSpec(
        key: 'end_date',
        label: 'To',
        type: ReportParamType.date,
        defaultToday: true,
      ),
    ],
    rowsPath: 'entries',
    columns: [
      ReportColumnSpec(
        key: 'activity_type',
        label: 'Activity Type',
        primary: true,
        flex: 2,
      ),
      ReportColumnSpec(key: 'particulars', label: 'Particulars', flex: 2),
      ReportColumnSpec(key: 'cash_inflow', label: 'Cash Inflow', mono: true),
      ReportColumnSpec(key: 'cash_outflow', label: 'Cash Outflow', mono: true),
      ReportColumnSpec(
        key: 'net_cash_flow',
        label: 'Net Cash Flow',
        mono: true,
      ),
    ],
  );

  static const fixedAssetsDepreciation = ReportDefinition(
    id: 'fixed-assets-depreciation',
    title: 'Fixed assets & depreciation',
    endpoint: '/reports/fixed-assets-depreciation',
    requiredModule: 'JournalLedger',
    autoRun: true,
    params: [
      ReportParamSpec(
        key: 'as_of_date',
        label: 'As of',
        type: ReportParamType.date,
        defaultToday: true,
      ),
    ],
    rowsPath: 'items',
    columns: [
      ReportColumnSpec(
        key: 'asset_name',
        label: 'Asset Name',
        primary: true,
        flex: 2,
      ),
      ReportColumnSpec(key: 'asset_category', label: 'Category'),
      ReportColumnSpec(key: 'gross_block', label: 'Gross Value', mono: true),
      ReportColumnSpec(
        key: 'accumulated_depreciation',
        label: 'Accumulated Dep.',
        mono: true,
      ),
      ReportColumnSpec(
        key: 'net_book_value',
        label: 'Net Book Value',
        mono: true,
      ),
    ],
  );

  static const quotationConversionRatio = ReportDefinition(
    id: 'quotation-conversion-ratio',
    title: 'Quotation conversion ratio',
    endpoint: '/reports/quotation-conversion-ratio',
    requiredModule: 'Transactions',
    autoRun: true,
    params: [
      ReportParamSpec(
        key: 'start_date',
        label: 'From',
        type: ReportParamType.date,
        defaultMonthStart: true,
      ),
      ReportParamSpec(
        key: 'end_date',
        label: 'To',
        type: ReportParamType.date,
        defaultToday: true,
      ),
    ],
    rowsPath: 'items',
    columns: [
      ReportColumnSpec(
        key: 'salesrep_name',
        label: 'Sales Representative',
        primary: true,
        flex: 2,
      ),
      ReportColumnSpec(
        key: 'total_quotations',
        label: 'Total Quotations',
        mono: true,
      ),
      ReportColumnSpec(
        key: 'converted_orders',
        label: 'Converted Orders',
        mono: true,
      ),
      ReportColumnSpec(
        key: 'lost_quotations',
        label: 'Lost Quotations',
        mono: true,
      ),
      ReportColumnSpec(
        key: 'conversion_rate',
        label: 'Conversion Rate %',
        mono: true,
      ),
    ],
  );

  static const salespersonCommission = ReportDefinition(
    id: 'salesperson-commission',
    title: 'Salesperson commission & territory',
    endpoint: '/reports/salesperson-commission',
    requiredModule: 'Transactions',
    autoRun: true,
    params: [
      ReportParamSpec(
        key: 'start_date',
        label: 'From',
        type: ReportParamType.date,
        defaultMonthStart: true,
      ),
      ReportParamSpec(
        key: 'end_date',
        label: 'To',
        type: ReportParamType.date,
        defaultToday: true,
      ),
    ],
    rowsPath: 'items',
    columns: [
      ReportColumnSpec(
        key: 'salesrep_name',
        label: 'Sales Representative',
        primary: true,
        flex: 2,
      ),
      ReportColumnSpec(key: 'territory', label: 'Territory / Region'),
      ReportColumnSpec(key: 'total_sales', label: 'Total Sales', mono: true),
      ReportColumnSpec(
        key: 'commission_rate',
        label: 'Commission %',
        mono: true,
      ),
      ReportColumnSpec(
        key: 'earned_commission',
        label: 'Commission Earned',
        mono: true,
      ),
    ],
  );

  static const inactiveCustomerAnalysis = ReportDefinition(
    id: 'inactive-customer-analysis',
    title: 'Inactive customer analysis',
    endpoint: '/reports/inactive-customer-analysis',
    requiredModule: 'Transactions',
    autoRun: true,
    params: [
      ReportParamSpec(
        key: 'as_of_date',
        label: 'As of',
        type: ReportParamType.date,
        defaultToday: true,
      ),
      ReportParamSpec(
        key: 'days_inactive',
        label: 'Days Inactive',
        type: ReportParamType.intField,
      ),
    ],
    rowsPath: 'items',
    columns: [
      ReportColumnSpec(
        key: 'customer_name',
        label: 'Customer Name',
        primary: true,
        flex: 2,
      ),
      ReportColumnSpec(
        key: 'last_order_date',
        label: 'Last Order Date',
        mono: true,
      ),
      ReportColumnSpec(
        key: 'days_since_last_order',
        label: 'Days Inactive',
        mono: true,
      ),
      ReportColumnSpec(
        key: 'last_order_value',
        label: 'Last Order Value',
        mono: true,
      ),
      ReportColumnSpec(
        key: 'total_historical_spend',
        label: 'Total Spend',
        mono: true,
      ),
    ],
  );

  static const vendorLeadtimeCompliance = ReportDefinition(
    id: 'vendor-leadtime-compliance',
    title: 'Vendor lead-time compliance',
    endpoint: '/reports/vendor-leadtime-compliance',
    requiredModule: 'Transactions',
    autoRun: true,
    params: [
      ReportParamSpec(
        key: 'start_date',
        label: 'From',
        type: ReportParamType.date,
        defaultMonthStart: true,
      ),
      ReportParamSpec(
        key: 'end_date',
        label: 'To',
        type: ReportParamType.date,
        defaultToday: true,
      ),
    ],
    rowsPath: 'items',
    columns: [
      ReportColumnSpec(
        key: 'vendor_name',
        label: 'Vendor Name',
        primary: true,
        flex: 2,
      ),
      ReportColumnSpec(key: 'total_pos', label: 'Total POs', mono: true),
      ReportColumnSpec(
        key: 'avg_promised_days',
        label: 'Promised Lead Time',
        mono: true,
      ),
      ReportColumnSpec(
        key: 'avg_actual_days',
        label: 'Actual Lead Time',
        mono: true,
      ),
      ReportColumnSpec(
        key: 'on_time_delivery_percent',
        label: 'On-Time %',
        mono: true,
      ),
    ],
  );

  static const ppvAudit = ReportDefinition(
    id: 'ppv-audit',
    title: 'Purchase price variance audit',
    endpoint: '/reports/ppv-audit',
    requiredModule: 'Transactions',
    autoRun: true,
    params: [
      ReportParamSpec(
        key: 'start_date',
        label: 'From',
        type: ReportParamType.date,
        defaultMonthStart: true,
      ),
      ReportParamSpec(
        key: 'end_date',
        label: 'To',
        type: ReportParamType.date,
        defaultToday: true,
      ),
    ],
    rowsPath: 'items',
    columns: [
      ReportColumnSpec(
        key: 'item_name',
        label: 'Item Name',
        primary: true,
        flex: 2,
      ),
      ReportColumnSpec(key: 'vendor_name', label: 'Vendor', flex: 2),
      ReportColumnSpec(key: 'master_cost', label: 'Standard Cost', mono: true),
      ReportColumnSpec(
        key: 'po_unit_price',
        label: 'PO Unit Price',
        mono: true,
      ),
      ReportColumnSpec(
        key: 'price_variance_amount',
        label: 'Variance Amount',
        mono: true,
      ),
    ],
  );

  static const bomProductionCosting = ReportDefinition(
    id: 'bom-production-costing',
    title: 'BOM & production costing',
    endpoint: '/reports/bom-production-costing',
    requiredModule: 'Inventory',
    autoRun: true,
    rowsPath: 'items',
    columns: [
      ReportColumnSpec(
        key: 'finished_good_name',
        label: 'Finished Good',
        primary: true,
        flex: 2,
      ),
      ReportColumnSpec(key: 'bom_code', label: 'BOM Code', mono: true),
      ReportColumnSpec(
        key: 'raw_material_cost',
        label: 'Raw Material Cost',
        mono: true,
      ),
      ReportColumnSpec(
        key: 'overhead_cost',
        label: 'Overhead Cost',
        mono: true,
      ),
      ReportColumnSpec(
        key: 'total_unit_cost',
        label: 'Total Unit Cost',
        mono: true,
      ),
    ],
  );

  static const binLocationStock = ReportDefinition(
    id: 'bin-location-stock',
    title: 'Bin & shelf location stock',
    endpoint: '/reports/bin-location-stock',
    requiredModule: 'Inventory',
    autoRun: true,
    rowsPath: 'items',
    columns: [
      ReportColumnSpec(
        key: 'godown_name',
        label: 'Godown / Warehouse',
        primary: true,
        flex: 2,
      ),
      ReportColumnSpec(
        key: 'bin_rack_code',
        label: 'Bin / Rack Code',
        mono: true,
      ),
      ReportColumnSpec(key: 'item_name', label: 'Item Name', flex: 2),
      ReportColumnSpec(key: 'on_hand_qty', label: 'Quantity', mono: true),
    ],
  );

  static const deadStockAnalysis = ReportDefinition(
    id: 'dead-stock-analysis',
    title: 'Dead stock & obsolescence analysis',
    endpoint: '/reports/dead-stock-analysis',
    requiredModule: 'Inventory',
    autoRun: true,
    params: [
      ReportParamSpec(
        key: 'as_of_date',
        label: 'As of',
        type: ReportParamType.date,
        defaultToday: true,
      ),
    ],
    rowsPath: 'items',
    columns: [
      ReportColumnSpec(
        key: 'item_name',
        label: 'Item Name',
        primary: true,
        flex: 2,
      ),
      ReportColumnSpec(
        key: 'last_movement_date',
        label: 'Last Movement',
        mono: true,
      ),
      ReportColumnSpec(key: 'days_idle', label: 'Days Idle', mono: true),
      ReportColumnSpec(key: 'closing_qty', label: 'Qty On Hand', mono: true),
      ReportColumnSpec(
        key: 'total_stock_value',
        label: 'Tied Capital',
        mono: true,
      ),
    ],
  );

  static const statutoryPayrollCompliance = ReportDefinition(
    id: 'statutory-payroll-compliance',
    title: 'Statutory payroll compliance',
    endpoint: '/reports/statutory-payroll-compliance',
    requiredModule: 'Employee',
    autoRun: true,
    params: [
      ReportParamSpec(
        key: 'start_date',
        label: 'From',
        type: ReportParamType.date,
        defaultMonthStart: true,
      ),
      ReportParamSpec(
        key: 'end_date',
        label: 'To',
        type: ReportParamType.date,
        defaultToday: true,
      ),
    ],
    rowsPath: 'items',
    columns: [
      ReportColumnSpec(
        key: 'employee_name',
        label: 'Employee Name',
        primary: true,
        flex: 2,
      ),
      ReportColumnSpec(key: 'gross_pay', label: 'Gross Pay', mono: true),
      ReportColumnSpec(
        key: 'employee_pf_deduction',
        label: 'Employee PF',
        mono: true,
      ),
      ReportColumnSpec(
        key: 'employer_pf_contribution',
        label: 'Employer PF',
        mono: true,
      ),
      ReportColumnSpec(
        key: 'total_statutory_liability',
        label: 'Total Liability',
        mono: true,
      ),
    ],
  );

  static const leaveBalanceRegister = ReportDefinition(
    id: 'leave-balance-register',
    title: 'Employee leave balance & accruals',
    endpoint: '/reports/leave-balance-register',
    requiredModule: 'Employee',
    autoRun: true,
    rowsPath: 'items',
    columns: [
      ReportColumnSpec(
        key: 'employee_name',
        label: 'Employee Name',
        primary: true,
        flex: 2,
      ),
      ReportColumnSpec(key: 'leave_type', label: 'Leave Type'),
      ReportColumnSpec(key: 'allocated_days', label: 'Allocated', mono: true),
      ReportColumnSpec(key: 'used_days', label: 'Used', mono: true),
      ReportColumnSpec(
        key: 'remaining_balance',
        label: 'Remaining',
        mono: true,
      ),
    ],
  );
}
