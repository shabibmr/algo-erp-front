import 'package:algo_erp_front/core/auth/permission_contract.dart';
import 'package:flutter/material.dart';

/// A single navigation destination — a binder hub, a hub tile, or a utility
/// page. [requiredModule]/[requiredAction] name the RBAC permission that gates
/// it: hub tiles are filtered by `ModuleHubPage`, and hubs themselves by
/// [AppMenu.visibleSections].
@immutable
class MenuItemModel {
  const MenuItemModel({
    required this.label,
    required this.icon,
    required this.route,
    this.blurb = 'Open master',
    this.selectedIcon,
    this.requiredModule,
    this.requiredAction = 'read',
  });

  final String label;

  /// One-line description shown under the title on a hub tile.
  final String blurb;
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

/// A titled band of tiles inside a [ModuleHub].
@immutable
class MenuGroup {
  const MenuGroup({required this.items, this.title});

  final String? title;
  final List<MenuItemModel> items;
}

/// A business domain: one binder entry whose page is a grid of [groups].
///
/// [crossLinks] are tiles owned by *another* hub but reachable from this one —
/// per the "one canonical home + cross-links" rule, they are rendered in a
/// separate Related band and are deliberately **not** part of [tiles], so they
/// neither register routes twice nor claim ownership.
@immutable
class ModuleHub {
  const ModuleHub({
    required this.route,
    required this.label,
    required this.icon,
    required this.eyebrow,
    required this.subtitle,
    required this.groups,
    this.selectedIcon,
    this.crossLinks = const [],
    this.footerHint = 'Open a master to list, create, or edit records.',
    this.inBinder = true,
  });

  final String route;
  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final String eyebrow;
  final String subtitle;
  final List<MenuGroup> groups;
  final List<MenuItemModel> crossLinks;
  final String footerHint;

  /// `/transactions` is routed and searchable but not in the binder — its
  /// vouchers live on the business hubs.
  final bool inBinder;

  /// The tiles this hub owns. Cross-links excluded on purpose.
  List<MenuItemModel> get tiles => [for (final group in groups) ...group.items];

  MenuItemModel get menuItem => MenuItemModel(
    label: label,
    icon: icon,
    selectedIcon: selectedIcon,
    route: route,
    blurb: subtitle,
  );
}

/// The single source of truth for the app's navigation. Every route referenced
/// here must exist in `app_router.dart`.
///
/// **Navigation is grouped by business domain; code is grouped by engine.** A
/// sales invoice routes under `/transactions/*` and is built by the item-qty
/// voucher engine, but it *navigates* from Sales. The `EntityManifest` /
/// `VoucherBlueprint` indirection is what lets those two groupings differ —
/// don't "fix" the mismatch by moving feature folders.
///
/// **Binder vs hub:** only hubs appear in the binder. Masters and voucher types
/// are hub tiles; each still gets a shell route and a palette entry.
abstract final class AppMenu {
  static const MenuItemModel desk = MenuItemModel(
    label: 'Desk',
    icon: Icons.home_work_outlined,
    selectedIcon: Icons.home_work,
    route: '/dashboard',
    blurb: "Today's work",
  );

  static const MenuItemModel reports = MenuItemModel(
    label: 'Reports',
    icon: Icons.bar_chart_outlined,
    selectedIcon: Icons.bar_chart,
    route: '/reports',
    blurb: 'Registers, stock, VAT, and books',
  );

  static const MenuItemModel settings = MenuItemModel(
    label: 'Settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    route: '/settings',
    blurb: 'Preferences and developer tools',
  );

  /// Routed, but not in the binder and not owned by a hub. Reachable from
  /// Settings → Developer and from the command palette.
  static const List<MenuItemModel> utilityItems = [
    MenuItemModel(
      label: 'Theme preview',
      icon: Icons.palette_outlined,
      selectedIcon: Icons.palette,
      route: '/theme-preview',
      blurb: 'Ledger & Linen tokens and type scale',
    ),
    MenuItemModel(
      label: 'Widget gallery',
      icon: Icons.widgets_outlined,
      selectedIcon: Icons.widgets,
      route: '/widget-gallery',
      blurb: 'Core widget catalogue',
    ),
  ];

  // ---------------------------------------------------------------------------
  // Business hubs. Keyed by hub route; order here is binder order.
  // ---------------------------------------------------------------------------

  static const Map<String, ModuleHub> hubs = {
    '/sales': _sales,
    '/purchase': _purchase,
    '/inventory': _inventory,
    '/accounts': _finance,
    '/employee': _people,
    '/organization': _organization,
    '/transactions': _allDocuments,
  };

  static const ModuleHub _sales = ModuleHub(
    route: '/sales',
    label: 'Sales',
    icon: Icons.storefront_outlined,
    selectedIcon: Icons.storefront,
    eyebrow: 'Business',
    subtitle: 'Quote to cash — customer documents and sales setup',
    footerHint: 'Open a document type to list, create, or review records.',
    groups: [
      MenuGroup(title: 'Documents', items: _salesDocs),
      MenuGroup(
        title: 'Setup',
        items: [
          MenuItemModel(
            label: 'Price list',
            icon: Icons.price_change_outlined,
            selectedIcon: Icons.price_change,
            route: '/inventory/pricelist',
            requiredModule: 'Inventory',
            blurb: 'Price lists and rates',
          ),
          MenuItemModel(
            label: 'Route',
            icon: Icons.alt_route_outlined,
            selectedIcon: Icons.alt_route,
            route: '/inventory/route',
            requiredModule: 'Inventory',
            blurb: 'Delivery routes',
          ),
        ],
      ),
    ],
    crossLinks: [
      MenuItemModel(
        label: 'Receipt',
        icon: Icons.account_balance_wallet_outlined,
        selectedIcon: Icons.account_balance_wallet,
        route: '/transactions/receipts',
        requiredModule: 'ReceiptVoucher',
        blurb: 'Incoming receipts',
      ),
      MenuItemModel(
        label: 'Contact',
        icon: Icons.contacts_outlined,
        selectedIcon: Icons.contacts,
        route: '/organization/contacts',
        requiredModule: 'AddressBook',
        blurb: 'Address book contacts',
      ),
    ],
  );

  static const ModuleHub _purchase = ModuleHub(
    route: '/purchase',
    label: 'Purchase',
    icon: Icons.shopping_basket_outlined,
    selectedIcon: Icons.shopping_basket,
    eyebrow: 'Business',
    subtitle: 'Procure to pay — supplier documents',
    footerHint: 'Open a document type to list, create, or review records.',
    groups: [MenuGroup(title: 'Documents', items: _purchaseDocs)],
    crossLinks: [
      MenuItemModel(
        label: 'Payment',
        icon: Icons.payments_outlined,
        selectedIcon: Icons.payments,
        route: '/transactions/payments',
        requiredModule: 'PaymentVoucher',
        blurb: 'Outgoing payments',
      ),
      MenuItemModel(
        label: 'Contact',
        icon: Icons.contacts_outlined,
        selectedIcon: Icons.contacts,
        route: '/organization/contacts',
        requiredModule: 'AddressBook',
        blurb: 'Address book contacts',
      ),
    ],
  );

  static const ModuleHub _inventory = ModuleHub(
    route: '/inventory',
    label: 'Inventory',
    icon: Icons.inventory_2_outlined,
    selectedIcon: Icons.inventory_2,
    eyebrow: 'Business',
    subtitle: 'Catalogue, warehouses, and stock movement',
    groups: [
      MenuGroup(
        title: 'Catalogue',
        items: [
          MenuItemModel(
            label: 'Item',
            icon: Icons.inventory_outlined,
            selectedIcon: Icons.inventory,
            route: '/inventory/item',
            requiredModule: 'Inventory',
            blurb: 'Sellable and stocked items',
          ),
          MenuItemModel(
            label: 'Item group',
            icon: Icons.account_tree_outlined,
            selectedIcon: Icons.account_tree,
            route: '/inventory/group',
            requiredModule: 'Inventory',
            blurb: 'Item classification tree',
          ),
          MenuItemModel(
            label: 'SKU',
            icon: Icons.qr_code_2_outlined,
            selectedIcon: Icons.qr_code_2,
            route: '/inventory/sku',
            requiredModule: 'Inventory',
            blurb: 'SKU variants linked to items',
          ),
          MenuItemModel(
            label: 'Batch',
            icon: Icons.layers_outlined,
            selectedIcon: Icons.layers,
            route: '/inventory/batch',
            requiredModule: 'Inventory',
            blurb: 'Batch / lot tracking',
          ),
          MenuItemModel(
            label: 'Brand',
            icon: Icons.sell_outlined,
            selectedIcon: Icons.sell,
            route: '/inventory/brand',
            requiredModule: 'Inventory',
            blurb: 'Product brands',
          ),
          MenuItemModel(
            label: 'Category',
            icon: Icons.category_outlined,
            selectedIcon: Icons.category,
            route: '/inventory/category',
            requiredModule: 'Inventory',
            blurb: 'Sales and stock categories',
          ),
          MenuItemModel(
            label: 'UOM',
            icon: Icons.straighten_outlined,
            selectedIcon: Icons.straighten,
            route: '/inventory/uom',
            requiredModule: 'Inventory',
            blurb: 'Units of measure',
          ),
          MenuItemModel(
            label: 'UOM conversion',
            icon: Icons.swap_horiz_outlined,
            selectedIcon: Icons.swap_horiz,
            route: '/inventory/conversion',
            requiredModule: 'Inventory',
            blurb: 'UOM conversion factors',
          ),
          MenuItemModel(
            label: 'Godown',
            icon: Icons.warehouse_outlined,
            selectedIcon: Icons.warehouse,
            route: '/inventory/godown',
            requiredModule: 'Inventory',
            blurb: 'Warehouses and stock locations',
          ),
          MenuItemModel(
            label: 'Product attribute',
            icon: Icons.style_outlined,
            selectedIcon: Icons.style,
            route: '/inventory/attribute',
            requiredModule: 'Inventory',
            blurb: 'Product attributes, options & groups',
          ),
          MenuItemModel(
            label: 'Item property',
            icon: Icons.tune_outlined,
            selectedIcon: Icons.tune,
            route: '/inventory/property',
            requiredModule: 'Inventory',
            blurb: 'Item property definitions',
          ),
        ],
      ),
      MenuGroup(title: 'Stock movements', items: _stockDocs),
    ],
  );

  static const ModuleHub _finance = ModuleHub(
    route: '/accounts',
    label: 'Finance',
    icon: Icons.account_balance_outlined,
    selectedIcon: Icons.account_balance,
    eyebrow: 'Back office',
    subtitle: 'Books, money movement, and fiscal setup',
    groups: [
      MenuGroup(
        title: 'Books',
        items: [
          MenuItemModel(
            label: 'Ledger',
            icon: Icons.menu_book_outlined,
            selectedIcon: Icons.menu_book,
            route: '/accounts/ledgers',
            requiredModule: 'Accounts',
            blurb: 'Customers, suppliers, cash, bank, and GL',
          ),
          MenuItemModel(
            label: 'Account group',
            icon: Icons.account_tree_outlined,
            selectedIcon: Icons.account_tree,
            route: '/accounts/groups',
            requiredModule: 'Accounts',
            blurb: 'Account hierarchy and parent groups',
          ),
          ..._bookDocs,
        ],
      ),
      MenuGroup(title: 'Money', items: _moneyDocs),
      MenuGroup(
        title: 'Fiscal setup',
        items: [
          MenuItemModel(
            label: 'Tax category',
            icon: Icons.percent_outlined,
            selectedIcon: Icons.percent,
            route: '/inventory/tax-category',
            requiredModule: 'Inventory',
            blurb: 'Tax rates and categories',
          ),
          MenuItemModel(
            label: 'Currency',
            icon: Icons.currency_exchange_outlined,
            selectedIcon: Icons.currency_exchange,
            route: '/organization/currencies',
            requiredModule: 'Currency',
            blurb: 'ISO currencies and base currency',
          ),
          MenuItemModel(
            label: 'Currency rate',
            icon: Icons.show_chart_outlined,
            selectedIcon: Icons.show_chart,
            route: '/organization/rates/history',
            requiredModule: 'CurrencyRate',
            blurb: 'Daily buy / sell FX rates',
          ),
          MenuItemModel(
            label: 'Financial year',
            icon: Icons.event_note_outlined,
            selectedIcon: Icons.event_note,
            route: '/organization/fy',
            requiredModule: 'FinancialYear',
            blurb: 'Open, close, and default financial years',
          ),
          MenuItemModel(
            label: 'Voucher series',
            icon: Icons.pin_outlined,
            selectedIcon: Icons.pin,
            route: '/organization/voucher-series',
            requiredModule: 'VoucherSeries',
            blurb: 'Prefixes, numbering, approvals',
          ),
        ],
      ),
    ],
  );

  static const ModuleHub _people = ModuleHub(
    route: '/employee',
    label: 'People',
    icon: Icons.badge_outlined,
    selectedIcon: Icons.badge,
    eyebrow: 'Back office',
    subtitle: 'Employees, structure, leave, and shifts',
    groups: [
      MenuGroup(
        title: 'Records',
        items: [
          MenuItemModel(
            label: 'Employees',
            icon: Icons.badge_outlined,
            selectedIcon: Icons.badge,
            route: '/employee/employees',
            requiredModule: 'Employee',
            blurb: 'Employee profiles, bank, and salary',
          ),
          MenuItemModel(
            label: 'Department',
            icon: Icons.apartment_outlined,
            selectedIcon: Icons.apartment,
            route: '/employee/department',
            requiredModule: 'Employee',
            blurb: 'Departments',
          ),
          MenuItemModel(
            label: 'Designation',
            icon: Icons.work_outline,
            selectedIcon: Icons.work,
            route: '/employee/designation',
            requiredModule: 'Employee',
            blurb: 'Job titles and designations',
          ),
          MenuItemModel(
            label: 'Shift',
            icon: Icons.schedule_outlined,
            selectedIcon: Icons.schedule,
            route: '/employee/shifts',
            requiredModule: 'Employee',
            blurb: 'Shift schedules',
          ),
        ],
      ),
      MenuGroup(
        title: 'Leave',
        items: [
          MenuItemModel(
            label: 'Leave policy',
            icon: Icons.event_available_outlined,
            selectedIcon: Icons.event_available,
            route: '/employee/leave/policies',
            requiredModule: 'Employee',
            blurb: 'Leave policy definitions',
          ),
          MenuItemModel(
            label: 'Leave allocation',
            icon: Icons.pie_chart_outline,
            selectedIcon: Icons.pie_chart,
            route: '/employee/leave/allocations',
            requiredModule: 'Employee',
            blurb: 'Yearly leave balances',
          ),
          MenuItemModel(
            label: 'Leave request',
            icon: Icons.beach_access_outlined,
            selectedIcon: Icons.beach_access,
            route: '/employee/leave-requests',
            requiredModule: 'Employee',
            blurb: 'Apply, approve, and cancel leave',
          ),
        ],
      ),
    ],
  );

  /// Company structure and admin. Not a binder entry — opened from Settings.
  static const ModuleHub _organization = ModuleHub(
    route: '/organization',
    label: 'Organization',
    icon: Icons.corporate_fare_outlined,
    selectedIcon: Icons.corporate_fare,
    eyebrow: 'Settings',
    subtitle: 'Company structure, access, and system administration',
    inBinder: false,
    groups: [
      MenuGroup(
        title: 'Structure',
        items: [
          MenuItemModel(
            label: 'Company',
            icon: Icons.business_outlined,
            selectedIcon: Icons.business,
            route: '/organization/companies',
            requiredModule: 'CompanyProfile',
            blurb: 'Legal profile, TRN, and address',
          ),
          MenuItemModel(
            label: 'Branch',
            icon: Icons.store_outlined,
            selectedIcon: Icons.store,
            route: '/organization/branches',
            requiredModule: 'Branch',
            blurb: 'Branches and locations',
          ),
          MenuItemModel(
            label: 'Project',
            icon: Icons.account_tree_outlined,
            selectedIcon: Icons.account_tree,
            route: '/organization/projects',
            requiredModule: 'ProjectMaster',
            blurb: 'Project hierarchy for vouchers',
          ),
          MenuItemModel(
            label: 'Contact',
            icon: Icons.contacts_outlined,
            selectedIcon: Icons.contacts,
            route: '/organization/contacts',
            requiredModule: 'AddressBook',
            blurb: 'Address book contacts',
          ),
        ],
      ),
      MenuGroup(
        title: 'Access',
        items: [
          MenuItemModel(
            label: 'User',
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            route: '/organization/users',
            requiredModule: 'UserCredentials',
            blurb: 'Logins, roles, and branches',
          ),
          MenuItemModel(
            label: 'User role',
            icon: Icons.admin_panel_settings_outlined,
            selectedIcon: Icons.admin_panel_settings,
            route: '/organization/roles',
            requiredModule: 'UserRole',
            blurb: 'Roles and permission matrix',
          ),
        ],
      ),
      MenuGroup(
        title: 'System',
        items: [
          MenuItemModel(
            label: 'Config',
            icon: Icons.tune_outlined,
            selectedIcon: Icons.tune,
            route: '/organization/config',
            requiredModule: 'ConfigSetting',
            blurb: 'Key system settings',
          ),
          MenuItemModel(
            label: 'Audit log',
            icon: Icons.history_outlined,
            selectedIcon: Icons.history,
            route: '/organization/audit-logs',
            requiredModule: 'AuditLog',
            blurb: 'Read-only activity trail',
          ),
          MenuItemModel(
            label: 'Error report',
            icon: Icons.bug_report_outlined,
            selectedIcon: Icons.bug_report,
            route: '/organization/error-reports',
            requiredModule: 'ErrorReporting',
            blurb: 'Captured client and server errors',
          ),
        ],
      ),
    ],
    crossLinks: [
      MenuItemModel(
        label: 'Voucher series',
        icon: Icons.pin_outlined,
        selectedIcon: Icons.pin,
        route: '/organization/voucher-series',
        requiredModule: 'VoucherSeries',
        blurb: 'Prefixes, numbering, approvals',
      ),
    ],
  );

  /// Every voucher type in one grid. Not in the binder — each voucher's home is
  /// a business hub — but routed and searchable as a cross-domain index.
  static const ModuleHub _allDocuments = ModuleHub(
    route: '/transactions',
    label: 'All documents',
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long,
    eyebrow: 'Documents',
    subtitle: 'Every voucher type, across sales, purchase, finance, and stock',
    footerHint: 'Each document type also lives on its business hub.',
    inBinder: false,
    groups: [
      MenuGroup(title: 'Sales', items: _salesDocs),
      MenuGroup(title: 'Purchase', items: _purchaseDocs),
      MenuGroup(title: 'Finance', items: _financeDocs),
      MenuGroup(title: 'Stock', items: _stockDocs),
    ],
  );

  // ---------------------------------------------------------------------------
  // Voucher tiles. Defined once, shared by the business hub that owns them and
  // by the All-documents index. `allHubTiles` dedupes by route, so a tile on two
  // hubs still registers exactly one route.
  // ---------------------------------------------------------------------------

  static const List<MenuItemModel> _salesDocs = [
    MenuItemModel(
      label: 'Quotation',
      icon: Icons.request_quote_outlined,
      selectedIcon: Icons.request_quote,
      route: '/transactions/quotations',
      requiredModule: 'Quotation',
      blurb: 'Sales quotations',
    ),
    MenuItemModel(
      label: 'Sales order',
      icon: Icons.shopping_cart_outlined,
      selectedIcon: Icons.shopping_cart,
      route: '/transactions/sales-orders',
      requiredModule: 'SalesOrder',
      blurb: 'Confirmed sales orders',
    ),
    MenuItemModel(
      label: 'Delivery note',
      icon: Icons.local_shipping_outlined,
      selectedIcon: Icons.local_shipping,
      route: '/transactions/delivery-notes',
      requiredModule: 'DeliveryNote',
      blurb: 'Stock out / delivery',
    ),
    MenuItemModel(
      label: 'Sales invoice',
      icon: Icons.point_of_sale_outlined,
      selectedIcon: Icons.point_of_sale,
      route: '/transactions/sales-invoices',
      requiredModule: 'SalesInvoice',
      blurb: 'Customer invoices — gold template',
    ),
    MenuItemModel(
      label: 'Credit note',
      icon: Icons.note_alt_outlined,
      selectedIcon: Icons.note_alt,
      route: '/transactions/credit-notes',
      requiredModule: 'CreditNote',
      blurb: 'Customer credit notes',
    ),
  ];

  static const List<MenuItemModel> _purchaseDocs = [
    MenuItemModel(
      label: 'Purchase order',
      icon: Icons.shopping_bag_outlined,
      selectedIcon: Icons.shopping_bag,
      route: '/transactions/purchase-orders',
      requiredModule: 'PurchaseOrder',
      blurb: 'Purchase orders',
    ),
    MenuItemModel(
      label: 'Receipt note',
      icon: Icons.move_to_inbox_outlined,
      selectedIcon: Icons.move_to_inbox,
      route: '/transactions/receipt-notes',
      requiredModule: 'ReceiptNote',
      blurb: 'Goods receipt / stock in',
    ),
    MenuItemModel(
      label: 'Purchase invoice',
      icon: Icons.receipt_outlined,
      selectedIcon: Icons.receipt,
      route: '/transactions/purchase-invoices',
      requiredModule: 'PurchaseInvoice',
      blurb: 'Supplier invoices',
    ),
    MenuItemModel(
      label: 'Debit note',
      icon: Icons.sticky_note_2_outlined,
      selectedIcon: Icons.sticky_note_2,
      route: '/transactions/debit-notes',
      requiredModule: 'DebitNote',
      blurb: 'Supplier debit notes',
    ),
  ];

  static const List<MenuItemModel> _bookDocs = [
    MenuItemModel(
      label: 'Journal',
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book,
      route: '/transactions/journals',
      requiredModule: 'JournalVoucher',
      blurb: 'General journal entries',
    ),
    MenuItemModel(
      label: 'Contra',
      icon: Icons.swap_horiz_outlined,
      selectedIcon: Icons.swap_horiz,
      route: '/transactions/contra',
      requiredModule: 'ContraVoucher',
      blurb: 'Cash and bank contra',
    ),
  ];

  static const List<MenuItemModel> _moneyDocs = [
    MenuItemModel(
      label: 'Payment',
      icon: Icons.payments_outlined,
      selectedIcon: Icons.payments,
      route: '/transactions/payments',
      requiredModule: 'PaymentVoucher',
      blurb: 'Outgoing payments',
    ),
    MenuItemModel(
      label: 'Receipt',
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet,
      route: '/transactions/receipts',
      requiredModule: 'ReceiptVoucher',
      blurb: 'Incoming receipts',
    ),
  ];

  static const List<MenuItemModel> _financeDocs = [..._bookDocs, ..._moneyDocs];

  static const List<MenuItemModel> _stockDocs = [
    MenuItemModel(
      label: 'Godown transfer',
      icon: Icons.warehouse_outlined,
      selectedIcon: Icons.warehouse,
      route: '/transactions/godown-transfers',
      requiredModule: 'GodownTransfer',
      blurb: 'Warehouse-to-warehouse transfer',
    ),
    MenuItemModel(
      label: 'Material in',
      icon: Icons.input_outlined,
      selectedIcon: Icons.input,
      route: '/transactions/material-in',
      requiredModule: 'MaterialIn',
      blurb: 'Material in adjustments',
    ),
    MenuItemModel(
      label: 'Requirement',
      icon: Icons.playlist_add_check_outlined,
      selectedIcon: Icons.playlist_add_check,
      route: '/transactions/requirements',
      requiredModule: 'Requirement',
      blurb: 'Material requirements',
    ),
    MenuItemModel(
      label: 'Stock request',
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
      route: '/transactions/stock-requests',
      requiredModule: 'StockRequest',
      blurb: 'Stock requests',
    ),
  ];

  // ---------------------------------------------------------------------------
  // Derived views.
  // ---------------------------------------------------------------------------

  static List<ModuleHub> get binderHubs => [
    for (final hub in hubs.values)
      if (hub.inBinder) hub,
  ];

  /// Binder structure. Section titles group hubs for the extended rail.
  static List<MenuSectionModel> get sections => [
    const MenuSectionModel(items: [desk]),
    MenuSectionModel(
      title: 'Operations',
      items: [
        for (final hub in binderHubs)
          if (hub.eyebrow == 'Business') hub.menuItem,
      ],
    ),
    MenuSectionModel(
      title: 'Back office',
      items: [
        for (final hub in binderHubs)
          if (hub.eyebrow == 'Back office') hub.menuItem,
      ],
    ),
    const MenuSectionModel(items: [reports, settings]),
  ];

  static List<MenuItemModel> get allItems =>
      sections.expand((s) => s.items).toList(growable: false);

  /// Every hub tile, deduped by route. Cross-links are excluded by
  /// [ModuleHub.tiles], and the All-documents hub reuses existing tiles, so a
  /// voucher shared by two hubs still yields exactly one route.
  static List<MenuItemModel> get allHubTiles =>
      _dedupe([for (final hub in hubs.values) ...hub.tiles]);

  /// Every route the shell must register: binder entries, non-binder hubs,
  /// utility pages, and all hub tiles.
  static List<MenuItemModel> get allShellListItems => _dedupe([
    ...allItems,
    for (final hub in hubs.values) hub.menuItem,
    ...utilityItems,
    ...allHubTiles,
  ]);

  /// The hub that owns [route], or null. Prefers an exact tile match, then the
  /// longest matching tile prefix — a voucher's *route* prefix (`/transactions`)
  /// is not its owner, so the All-documents hub is never considered.
  static ModuleHub? owningHub(String route) {
    ModuleHub? best;
    var bestLength = -1;

    for (final hub in hubs.values) {
      // Index hub only — never claims ownership over domain tiles.
      if (hub.route == '/transactions') continue;
      for (final tile in hub.tiles) {
        if (route == tile.route) return hub;
        if (route.startsWith('${tile.route}/') &&
            tile.route.length > bestLength) {
          best = hub;
          bestLength = tile.route.length;
        }
      }
    }
    if (best != null) return best;

    for (final hub in hubs.values) {
      if (hub.route == '/transactions') continue;
      if (route == hub.route || route.startsWith('${hub.route}/')) {
        if (hub.route.length > bestLength) {
          best = hub;
          bestLength = hub.route.length;
        }
      }
    }
    return best;
  }

  /// The binder route that should highlight for [location].
  static String? selectedBinderRoute(String location) {
    for (final item in [desk, reports, settings]) {
      if (location == item.route || location.startsWith('${item.route}/')) {
        return item.route;
      }
    }
    final hub = owningHub(location);
    if (hub == null) return null;
    // Organization (and any other non-binder hub) lives under Settings.
    if (!hub.inBinder) return settings.route;
    return hub.route;
  }

  /// [sections] with everything the user may not read removed. A hub survives
  /// iff at least one of its own tiles is readable; empty sections are dropped.
  ///
  /// This is what makes binder RBAC real — `requiredModule` used to be dead
  /// metadata in the sidebar.
  static List<MenuSectionModel> visibleSections(PermissionService permissions) {
    bool canRead(MenuItemModel item) =>
        item.requiredModule == null ||
        permissions.can(item.requiredModule!, PermissionAction.read);

    bool visible(MenuItemModel item) {
      final hub = hubs[item.route];
      if (hub != null) return hub.tiles.any(canRead);
      return canRead(item);
    }

    final out = <MenuSectionModel>[];
    for (final section in sections) {
      final items = section.items.where(visible).toList();
      if (items.isNotEmpty) {
        out.add(MenuSectionModel(title: section.title, items: items));
      }
    }
    return out;
  }

  static List<MenuItemModel> _dedupe(List<MenuItemModel> items) {
    final seen = <String>{};
    return [
      for (final item in items)
        if (seen.add(item.route)) item,
    ];
  }
}
