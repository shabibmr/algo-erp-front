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
        // Organization gates per entity rather than behind one module string,
        // so each item names its own backend module (organization.routes.ts).
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
          label: 'User role',
          icon: Icons.admin_panel_settings_outlined,
          selectedIcon: Icons.admin_panel_settings,
          route: '/organization/roles',
          requiredModule: 'UserRole',
        ),
        MenuItemModel(
          label: 'Contact',
          icon: Icons.contacts_outlined,
          selectedIcon: Icons.contacts,
          route: '/organization/contacts',
          requiredModule: 'AddressBook',
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
      ],
    ),
    MenuSectionModel(
      title: 'Employee',
      items: [
        MenuItemModel(
          label: 'Employee',
          icon: Icons.badge_outlined,
          selectedIcon: Icons.badge,
          route: '/employee',
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
}
