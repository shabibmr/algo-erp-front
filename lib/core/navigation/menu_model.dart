import 'package:flutter/material.dart';

/// A single navigation destination. [requiredModule]/[requiredAction] name
/// the RBAC permission that gates this item once `PermissionGate`/`RbacMixin`
/// land in Step 8 — until then every item renders unconditionally.
@immutable
class MenuItemModel {
  const MenuItemModel({
    required this.label,
    required this.icon,
    required this.route,
    this.selectedIcon,
    this.requiredModule,
    this.requiredAction = 'read',
  });

  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final String route;
  final String? requiredModule;
  final String requiredAction;
}

@immutable
class MenuSectionModel {
  const MenuSectionModel({required this.items, this.title});

  final String? title;
  final List<MenuItemModel> items;
}

/// The single source of truth for the app's navigation menu. Every route
/// referenced here must exist in `app_router.dart`.
abstract final class AppMenu {
  static const List<MenuSectionModel> sections = [
    MenuSectionModel(
      items: [
        MenuItemModel(
          label: 'Desk',
          icon: Icons.home_work_outlined,
          selectedIcon: Icons.home_work,
          route: '/dashboard',
        ),
      ],
    ),
    // Only the hub is in the binder. Masters open from OrganizationHubPage.
    MenuSectionModel(
      title: 'Organization',
      items: [
        MenuItemModel(
          label: 'Organization',
          icon: Icons.corporate_fare_outlined,
          selectedIcon: Icons.corporate_fare,
          route: '/organization',
          requiredModule: 'CompanyProfile',
        ),
      ],
    ),
    MenuSectionModel(
      title: 'Accounts',
      items: [
        MenuItemModel(
          label: 'Accounts',
          icon: Icons.account_balance_outlined,
          selectedIcon: Icons.account_balance,
          route: '/accounts',
          requiredModule: 'Accounts',
        ),
        MenuItemModel(
          label: 'Account group',
          icon: Icons.account_tree_outlined,
          selectedIcon: Icons.account_tree,
          route: '/accounts/groups',
          requiredModule: 'Accounts',
        ),
        MenuItemModel(
          label: 'Ledger',
          icon: Icons.menu_book_outlined,
          selectedIcon: Icons.menu_book,
          route: '/accounts/ledgers',
          requiredModule: 'Accounts',
        ),
      ],
    ),
    MenuSectionModel(
      title: 'Inventory',
      items: [
        MenuItemModel(
          label: 'Inventory',
          icon: Icons.inventory_2_outlined,
          selectedIcon: Icons.inventory_2,
          route: '/inventory',
          requiredModule: 'Inventory',
        ),
        MenuItemModel(
          label: 'Item',
          icon: Icons.inventory_outlined,
          selectedIcon: Icons.inventory,
          route: '/inventory/item',
          requiredModule: 'Inventory',
        ),
        MenuItemModel(
          label: 'Item group',
          icon: Icons.account_tree_outlined,
          selectedIcon: Icons.account_tree,
          route: '/inventory/group',
          requiredModule: 'Inventory',
        ),
        MenuItemModel(
          label: 'SKU',
          icon: Icons.qr_code_2_outlined,
          selectedIcon: Icons.qr_code_2,
          route: '/inventory/sku',
          requiredModule: 'Inventory',
        ),
        MenuItemModel(
          label: 'Batch',
          icon: Icons.layers_outlined,
          selectedIcon: Icons.layers,
          route: '/inventory/batch',
          requiredModule: 'Inventory',
        ),
        MenuItemModel(
          label: 'Brand',
          icon: Icons.sell_outlined,
          selectedIcon: Icons.sell,
          route: '/inventory/brand',
          requiredModule: 'Inventory',
        ),
        MenuItemModel(
          label: 'UOM',
          icon: Icons.straighten_outlined,
          selectedIcon: Icons.straighten,
          route: '/inventory/uom',
          requiredModule: 'Inventory',
        ),
        MenuItemModel(
          label: 'Category',
          icon: Icons.category_outlined,
          selectedIcon: Icons.category,
          route: '/inventory/category',
          requiredModule: 'Inventory',
        ),
        MenuItemModel(
          label: 'Tax category',
          icon: Icons.percent_outlined,
          selectedIcon: Icons.percent,
          route: '/inventory/tax-category',
          requiredModule: 'Inventory',
        ),
        MenuItemModel(
          label: 'Godown',
          icon: Icons.warehouse_outlined,
          selectedIcon: Icons.warehouse,
          route: '/inventory/godown',
          requiredModule: 'Inventory',
        ),
        MenuItemModel(
          label: 'Route',
          icon: Icons.alt_route_outlined,
          selectedIcon: Icons.alt_route,
          route: '/inventory/route',
          requiredModule: 'Inventory',
        ),
        MenuItemModel(
          label: 'UOM conversion',
          icon: Icons.swap_horiz_outlined,
          selectedIcon: Icons.swap_horiz,
          route: '/inventory/conversion',
          requiredModule: 'Inventory',
        ),
        MenuItemModel(
          label: 'Price list',
          icon: Icons.price_change_outlined,
          selectedIcon: Icons.price_change,
          route: '/inventory/pricelist',
          requiredModule: 'Inventory',
        ),
        MenuItemModel(
          label: 'Item property',
          icon: Icons.tune_outlined,
          selectedIcon: Icons.tune,
          route: '/inventory/property',
          requiredModule: 'Inventory',
        ),
      ],
    ),
    MenuSectionModel(
      title: 'Employee',
      items: [
        MenuItemModel(
          label: 'Employees',
          icon: Icons.badge_outlined,
          selectedIcon: Icons.badge,
          route: '/employee/employees',
          requiredModule: 'Employee',
        ),
        MenuItemModel(
          label: 'Department',
          icon: Icons.apartment_outlined,
          selectedIcon: Icons.apartment,
          route: '/employee/department',
          requiredModule: 'Employee',
        ),
        MenuItemModel(
          label: 'Designation',
          icon: Icons.work_outline,
          selectedIcon: Icons.work,
          route: '/employee/designation',
          requiredModule: 'Employee',
        ),
        MenuItemModel(
          label: 'Leave policy',
          icon: Icons.event_available_outlined,
          selectedIcon: Icons.event_available,
          route: '/employee/leave/policies',
          requiredModule: 'Employee',
        ),
        MenuItemModel(
          label: 'Leave allocation',
          icon: Icons.pie_chart_outline,
          selectedIcon: Icons.pie_chart,
          route: '/employee/leave/allocations',
          requiredModule: 'Employee',
        ),
        MenuItemModel(
          label: 'Leave request',
          icon: Icons.beach_access_outlined,
          selectedIcon: Icons.beach_access,
          route: '/employee/leave-requests',
          requiredModule: 'Employee',
        ),
        MenuItemModel(
          label: 'Shift',
          icon: Icons.schedule_outlined,
          selectedIcon: Icons.schedule,
          route: '/employee/shifts',
          requiredModule: 'Employee',
        ),
      ],
    ),
    MenuSectionModel(
      title: 'Transactions',
      items: [
        MenuItemModel(
          label: 'Transactions',
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long,
          route: '/transactions',
          requiredModule: 'Transactions',
        ),
        MenuItemModel(
          label: 'Sales invoice',
          icon: Icons.point_of_sale_outlined,
          selectedIcon: Icons.point_of_sale,
          route: '/transactions/sales-invoices',
          requiredModule: 'SalesInvoice',
        ),
        MenuItemModel(
          label: 'Quotation',
          icon: Icons.request_quote_outlined,
          selectedIcon: Icons.request_quote,
          route: '/transactions/quotations',
          requiredModule: 'Quotation',
        ),
        MenuItemModel(
          label: 'Sales order',
          icon: Icons.shopping_cart_outlined,
          selectedIcon: Icons.shopping_cart,
          route: '/transactions/sales-orders',
          requiredModule: 'SalesOrder',
        ),
        MenuItemModel(
          label: 'Delivery note',
          icon: Icons.local_shipping_outlined,
          selectedIcon: Icons.local_shipping,
          route: '/transactions/delivery-notes',
          requiredModule: 'DeliveryNote',
        ),
        MenuItemModel(
          label: 'Purchase order',
          icon: Icons.shopping_bag_outlined,
          selectedIcon: Icons.shopping_bag,
          route: '/transactions/purchase-orders',
          requiredModule: 'PurchaseOrder',
        ),
        MenuItemModel(
          label: 'Receipt note',
          icon: Icons.move_to_inbox_outlined,
          selectedIcon: Icons.move_to_inbox,
          route: '/transactions/receipt-notes',
          requiredModule: 'ReceiptNote',
        ),
        MenuItemModel(
          label: 'Purchase invoice',
          icon: Icons.receipt_outlined,
          selectedIcon: Icons.receipt,
          route: '/transactions/purchase-invoices',
          requiredModule: 'PurchaseInvoice',
        ),
        MenuItemModel(
          label: 'Payment',
          icon: Icons.payments_outlined,
          selectedIcon: Icons.payments,
          route: '/transactions/payments',
          requiredModule: 'PaymentVoucher',
        ),
        MenuItemModel(
          label: 'Receipt',
          icon: Icons.account_balance_wallet_outlined,
          selectedIcon: Icons.account_balance_wallet,
          route: '/transactions/receipts',
          requiredModule: 'ReceiptVoucher',
        ),
        MenuItemModel(
          label: 'Credit note',
          icon: Icons.note_alt_outlined,
          selectedIcon: Icons.note_alt,
          route: '/transactions/credit-notes',
          requiredModule: 'CreditNote',
        ),
        MenuItemModel(
          label: 'Debit note',
          icon: Icons.sticky_note_2_outlined,
          selectedIcon: Icons.sticky_note_2,
          route: '/transactions/debit-notes',
          requiredModule: 'DebitNote',
        ),
        MenuItemModel(
          label: 'Journal',
          icon: Icons.menu_book_outlined,
          selectedIcon: Icons.menu_book,
          route: '/transactions/journals',
          requiredModule: 'JournalVoucher',
        ),
        MenuItemModel(
          label: 'Contra',
          icon: Icons.swap_horiz_outlined,
          selectedIcon: Icons.swap_horiz,
          route: '/transactions/contra',
          requiredModule: 'ContraVoucher',
        ),
        MenuItemModel(
          label: 'Godown transfer',
          icon: Icons.warehouse_outlined,
          selectedIcon: Icons.warehouse,
          route: '/transactions/godown-transfers',
          requiredModule: 'GodownTransfer',
        ),
        MenuItemModel(
          label: 'Material in',
          icon: Icons.input_outlined,
          selectedIcon: Icons.input,
          route: '/transactions/material-in',
          requiredModule: 'MaterialIn',
        ),
        MenuItemModel(
          label: 'Requirement',
          icon: Icons.playlist_add_check_outlined,
          selectedIcon: Icons.playlist_add_check,
          route: '/transactions/requirements',
          requiredModule: 'Requirement',
        ),
        MenuItemModel(
          label: 'Stock request',
          icon: Icons.inventory_2_outlined,
          selectedIcon: Icons.inventory_2,
          route: '/transactions/stock-requests',
          requiredModule: 'StockRequest',
        ),
      ],
    ),
    MenuSectionModel(
      items: [
        MenuItemModel(
          label: 'Reports',
          icon: Icons.bar_chart_outlined,
          selectedIcon: Icons.bar_chart,
          route: '/reports',
        ),
        MenuItemModel(
          label: 'Settings',
          icon: Icons.settings_outlined,
          selectedIcon: Icons.settings,
          route: '/settings',
        ),
        MenuItemModel(
          label: 'Theme preview',
          icon: Icons.palette_outlined,
          selectedIcon: Icons.palette,
          route: '/theme-preview',
        ),
        MenuItemModel(
          label: 'Widget gallery',
          icon: Icons.widgets_outlined,
          selectedIcon: Icons.widgets,
          route: '/widget-gallery',
        ),
      ],
    ),
  ];

  static List<MenuItemModel> get allItems =>
      sections.expand((s) => s.items).toList(growable: false);

  /// Organization masters shown on the Organization hub page, not in the
  /// binder. Each still needs a list route in `app_router.dart`.
  static const List<MenuItemModel> organizationMasters = [
    MenuItemModel(
      label: 'Company',
      icon: Icons.business_outlined,
      selectedIcon: Icons.business,
      route: '/organization/companies',
      requiredModule: 'CompanyProfile',
    ),
    MenuItemModel(
      label: 'Branch',
      icon: Icons.store_outlined,
      selectedIcon: Icons.store,
      route: '/organization/branches',
      requiredModule: 'Branch',
    ),
    MenuItemModel(
      label: 'Currency',
      icon: Icons.currency_exchange_outlined,
      selectedIcon: Icons.currency_exchange,
      route: '/organization/currencies',
      requiredModule: 'Currency',
    ),
    MenuItemModel(
      label: 'Currency rate',
      icon: Icons.show_chart_outlined,
      selectedIcon: Icons.show_chart,
      route: '/organization/rates/history',
      requiredModule: 'CurrencyRate',
    ),
    MenuItemModel(
      label: 'Financial year',
      icon: Icons.event_note_outlined,
      selectedIcon: Icons.event_note,
      route: '/organization/fy',
      requiredModule: 'FinancialYear',
    ),
    MenuItemModel(
      label: 'Voucher series',
      icon: Icons.pin_outlined,
      selectedIcon: Icons.pin,
      route: '/organization/voucher-series',
      requiredModule: 'VoucherSeries',
    ),
    MenuItemModel(
      label: 'User role',
      icon: Icons.admin_panel_settings_outlined,
      selectedIcon: Icons.admin_panel_settings,
      route: '/organization/roles',
      requiredModule: 'UserRole',
    ),
    MenuItemModel(
      label: 'User',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      route: '/organization/users',
      requiredModule: 'UserCredentials',
    ),
    MenuItemModel(
      label: 'Contact',
      icon: Icons.contacts_outlined,
      selectedIcon: Icons.contacts,
      route: '/organization/contacts',
      requiredModule: 'AddressBook',
    ),
    MenuItemModel(
      label: 'Project',
      icon: Icons.account_tree_outlined,
      selectedIcon: Icons.account_tree,
      route: '/organization/projects',
      requiredModule: 'ProjectMaster',
    ),
    MenuItemModel(
      label: 'Config',
      icon: Icons.tune_outlined,
      selectedIcon: Icons.tune,
      route: '/organization/config',
      requiredModule: 'ConfigSetting',
    ),
    MenuItemModel(
      label: 'Audit log',
      icon: Icons.history_outlined,
      selectedIcon: Icons.history,
      route: '/organization/audit-logs',
      requiredModule: 'AuditLog',
    ),
    MenuItemModel(
      label: 'Error report',
      icon: Icons.bug_report_outlined,
      selectedIcon: Icons.bug_report,
      route: '/organization/error-reports',
      requiredModule: 'ErrorReporting',
    ),
  ];
}
